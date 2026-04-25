"""
Training module with optimizer, scheduler, and mixed precision support.
"""
import torch
import torch.nn as nn
import torch.optim as optim
from torch.amp import autocast, GradScaler
from tqdm import tqdm
import json
import os

def get_optimizer(model, config):
    """
    Creates optimizer with differential learning rates.

    Differential learning rates allow:
    - Higher learning rate for newly initialized classification head
    - Lower learning rate for pretrained backbone layers

    Args:
        model: PyTorch model
        config: Configuration dictionary

    Returns:
        optimizer: PyTorch optimizer
    """
    opt_cfg = config['optimizer']
    model_cfg = config['model']

    param_groups = []

    # Build parameter groups with different learning rates
    if model_cfg['name'] == 'vit_b_16' and model_cfg['freeze_backbone'] and model_cfg['unfreeze_last_n_blocks'] > 0:
        # ViT with unfrozen last N blocks
        param_groups.append({
            'params': model.encoder.layers[-model_cfg['unfreeze_last_n_blocks']:].parameters(),
            'lr': opt_cfg['lr_unfrozen']
        })
        param_groups.append({
            'params': model.heads.parameters(),
            'lr': opt_cfg['lr_head']
        })
    elif model_cfg['freeze_backbone']:
        # Only classification head is trainable
        if model_cfg['name'] == 'vit_b_16':
            param_groups = [{'params': model.heads.parameters(), 'lr': opt_cfg['lr_head']}]
        elif model_cfg['name'] == 'resnet50':
            param_groups = [{'params': model.fc.parameters(), 'lr': opt_cfg['lr_head']}]
        else:
            param_groups = [{'params': model.classifier.parameters(), 'lr': opt_cfg['lr_head']}]
    else:
        # Full fine-tuning (all layers trainable)
        param_groups = [{'params': model.parameters(), 'lr': opt_cfg['lr_head']}]

    # Create optimizer based on configuration
    opt_name = opt_cfg['name'].lower()
    if opt_name == 'adamw':
        return optim.AdamW(param_groups, weight_decay=opt_cfg['weight_decay'])
    elif opt_name == 'adam':
        return optim.Adam(param_groups, weight_decay=opt_cfg['weight_decay'])
    elif opt_name == 'sgd':
        return optim.SGD(param_groups, momentum=opt_cfg['momentum'], weight_decay=opt_cfg['weight_decay'])
    else:
        raise ValueError(f"Unsupported optimizer: {opt_cfg['name']}")

def get_scheduler(optimizer, config, epochs):
    """
    Creates learning rate scheduler.

    Supported schedulers:
    - CosineAnnealingLR: Smooth decay to 0
    - StepLR: Step-wise decay
    - ReduceLROnPlateau: Reduce when validation loss plateaus

    Args:
        optimizer: PyTorch optimizer
        config: Configuration dictionary
        epochs: Total number of training epochs

    Returns:
        scheduler: PyTorch learning rate scheduler
    """
    sched_cfg = config['scheduler']
    sched_name = sched_cfg['name'].lower()

    if sched_name == 'cosineannealinglr':
        return optim.lr_scheduler.CosineAnnealingLR(optimizer, T_max=epochs)
    elif sched_name == 'steplr':
        return optim.lr_scheduler.StepLR(optimizer, step_size=sched_cfg['step_size'], gamma=sched_cfg['gamma'])
    elif sched_name == 'reducelronplateau':
        return optim.lr_scheduler.ReduceLROnPlateau(optimizer, mode='min', patience=sched_cfg['patience'], factor=0.5)
    else:
        return None

def train_model(model, dataloaders, dataset_sizes, device, config, checkpoint_path, best_model_path, history_path):
    """
    Main training loop with checkpointing and history tracking.

    Features:
    - Mixed precision training (AMP) for faster training
    - Automatic checkpoint resuming
    - Best model saving based on validation accuracy
    - Training history logging

    Args:
        model: PyTorch model
        dataloaders: Dict with 'train' and 'val' loaders
        dataset_sizes: Dict with sizes of each split
        device: PyTorch device
        config: Configuration dictionary
        checkpoint_path: Path to save checkpoints
        best_model_path: Path to save best model
        history_path: Path to save training history

    Returns:
        history: Dictionary with training metrics
        best_val_acc: Best validation accuracy achieved
    """
    criterion = nn.CrossEntropyLoss()
    optimizer = get_optimizer(model, config)
    scheduler = get_scheduler(optimizer, config, config['training']['epochs'])

    use_amp = config['training']['use_mixed_precision']
    scaler = GradScaler('cuda') if use_amp else None

    start_epoch = 0
    best_val_acc = 0.0

    # Initialize history tracking
    history = {
        'train_loss': [],
        'train_acc': [],
        'val_loss': [],
        'val_acc': [],
        'epochs': []
    }

    # Resume from checkpoint if enabled
    if config['training']['resume_from_checkpoint'] and os.path.exists(checkpoint_path):
        print(f"\nRestoring from checkpoint: {checkpoint_path}")
        checkpoint = torch.load(checkpoint_path)
        model.load_state_dict(checkpoint['model_state_dict'])
        optimizer.load_state_dict(checkpoint['optimizer_state_dict'])
        start_epoch = checkpoint['epoch'] + 1
        best_val_acc = checkpoint['best_val_acc']
        if 'history' in checkpoint:
            history = checkpoint['history']
        print(f"Resumed from epoch {start_epoch}")

    # Training loop
    for epoch in range(start_epoch, config['training']['epochs']):
        print(f"\nEpoch {epoch+1}/{config['training']['epochs']}")
        print(f"Learning Rate: {optimizer.param_groups[0]['lr']:.2e}")

        for phase in ['train', 'val']:
            # Set model mode
            model.train() if phase == 'train' else model.eval()

            running_loss = 0.0
            running_corrects = 0
            samples_in_current_epoch_phase = 0 # Accumulates actual samples processed in the current phase (train/val)

            # Progress bar
            progress_bar = tqdm(dataloaders[phase], desc=f"{phase.upper():5s}", unit="batch", leave=True)

            for batch_idx, (inputs, labels) in enumerate(progress_bar):
                current_batch_size = inputs.size(0)
                samples_in_current_epoch_phase += current_batch_size

                inputs, labels = inputs.to(device), labels.to(device)
                optimizer.zero_grad()

                with torch.set_grad_enabled(phase == 'train'):
                    # Mixed precision forward pass
                    if use_amp and phase == 'train':
                        with autocast('cuda'):
                            outputs = model(inputs)
                            _, preds = torch.max(outputs, 1)
                            loss = criterion(outputs, labels)
                    else:
                        outputs = model(inputs)
                        _, preds = torch.max(outputs, 1)
                        loss = criterion(outputs, labels)

                    # Backward pass (training only)
                    if phase == 'train':
                        if use_amp:
                            scaler.scale(loss).backward()
                            scaler.step(optimizer)
                            scaler.update()
                        else:
                            loss.backward()
                            optimizer.step()

                # Update statistics
                running_loss += loss.item() * current_batch_size
                running_corrects += torch.sum(preds == labels.data)

                # Update progress bar
                current_loss = running_loss / samples_in_current_epoch_phase
                current_acc = running_corrects.double() / samples_in_current_epoch_phase
                progress_bar.set_postfix({'loss': f'{current_loss:.4f}', 'acc': f'{current_acc*100:.2f}%'})

            # Epoch statistics
            epoch_loss = running_loss / dataset_sizes[phase]
            epoch_acc = running_corrects.double() / dataset_sizes[phase]

            print(f"{phase.upper():5s} - Loss: {epoch_loss:.4f} | Accuracy: {epoch_acc*100:.2f}%")

            # Save history
            if phase == 'train':
                history['train_loss'].append(epoch_loss)
                history['train_acc'].append(epoch_acc.item())
            else:
                history['val_loss'].append(epoch_loss)
                history['val_acc'].append(epoch_acc.item())
                history['epochs'].append(epoch + 1)

                # Save checkpoint
                torch.save({
                    'epoch': epoch,
                    'model_state_dict': model.state_dict(),
                    'optimizer_state_dict': optimizer.state_dict(),
                    'best_val_acc': best_val_acc,
                    'history': history
                }, checkpoint_path)

                # Save best model
                if epoch_acc > best_val_acc:
                    best_val_acc = epoch_acc
                    torch.save(model.state_dict(), best_model_path)
                    print(f"NEW BEST MODEL SAVED. Val Acc: {best_val_acc*100:.2f}%")

                # Step scheduler
                if scheduler is not None:
                    if config['scheduler']['name'].lower() == 'reducelronplateau':
                        scheduler.step(epoch_loss)
                    else:
                        scheduler.step()

    # Training complete
    print(f"\nTraining Complete!")
    print(f"Best Validation Accuracy: {best_val_acc*100:.2f}%\n")

    # Save training history
    with open(history_path, 'w') as f:
        json.dump(history, f, indent=4)

    return history, best_val_acc
