"""
Evaluation module with comprehensive metrics and visualizations.
Includes Grad-CAM heatmap visualization for Vision Transformer models.
"""
import torch
import numpy as np
import matplotlib.pyplot as plt
from sklearn.metrics import (accuracy_score, precision_score, recall_score,
                             f1_score, roc_auc_score, confusion_matrix,
                             roc_curve, classification_report)
from tqdm import tqdm
import cv2
from PIL import Image


# ============ Evaluation Metrics Functions ============

def evaluate_model(model, dataloader, device, dataset_name="Test"):
    """Evaluate model and return comprehensive metrics."""
    model.eval()
    all_preds = []
    all_labels = []
    all_probs = []

    with torch.no_grad():
        for inputs, labels in tqdm(dataloader, desc=f"Evaluating on {dataset_name}"):
            inputs = inputs.to(device)
            outputs = model(inputs)
            probs = torch.softmax(outputs, dim=1)
            _, preds = torch.max(outputs, 1)

            all_preds.extend(preds.cpu().numpy())
            all_labels.extend(labels.numpy())
            all_probs.extend(probs.cpu().numpy()[:, 1])

    accuracy = accuracy_score(all_labels, all_preds)
    precision = precision_score(all_labels, all_preds)
    recall = recall_score(all_labels, all_preds)
    f1 = f1_score(all_labels, all_preds)
    auc = roc_auc_score(all_labels, all_probs)
    cm = confusion_matrix(all_labels, all_preds)

    metrics = {
        'accuracy': accuracy,
        'precision': precision,
        'recall': recall,
        'f1_score': f1,
        'auc': auc,
        'confusion_matrix': cm.tolist(),
        'predictions': all_preds,
        'labels': all_labels,
        'probabilities': all_probs
    }

    return metrics


def plot_confusion_matrix(cm, class_names, save_path):
    """Plot and save confusion matrix."""
    fig, ax = plt.subplots(figsize=(8, 6))
    im = ax.imshow(cm, interpolation='nearest', cmap=plt.cm.Blues)
    ax.figure.colorbar(im, ax=ax)
    ax.set(xticks=np.arange(cm.shape[1]), yticks=np.arange(cm.shape[0]),
           xticklabels=class_names, yticklabels=class_names,
           xlabel='Predicted Label', ylabel='True Label')

    thresh = cm.max() / 2
    for i in range(cm.shape[0]):
        for j in range(cm.shape[1]):
            ax.text(j, i, format(cm[i, j], 'd'),
                    ha="center", va="center",
                    color="white" if cm[i, j] > thresh else "black")

    ax.set_title('Confusion Matrix', fontsize=14, fontweight='bold')
    fig.tight_layout()
    plt.savefig(save_path, dpi=300, bbox_inches='tight')
    plt.show()
    print(f"✓ Confusion matrix saved to {save_path}")


def plot_roc_curve(y_true, y_probs, save_path):
    """Plot and save ROC curve."""
    fpr, tpr, _ = roc_curve(y_true, y_probs)
    auc = roc_auc_score(y_true, y_probs)

    plt.figure(figsize=(8, 6))
    plt.plot(fpr, tpr, 'b-', linewidth=2, label=f'Model (AUC = {auc:.3f})')
    plt.plot([0, 1], [0, 1], 'r--', linewidth=1, label='Random Classifier (AUC = 0.5)')
    plt.xlabel('False Positive Rate (FPR)', fontsize=12)
    plt.ylabel('True Positive Rate (TPR)', fontsize=12)
    plt.title('ROC Curve', fontsize=14, fontweight='bold')
    plt.legend(loc='lower right', fontsize=11)
    plt.grid(alpha=0.3)
    plt.savefig(save_path, dpi=300, bbox_inches='tight')
    plt.show()
    print(f"✓ ROC curve saved to {save_path}")


def plot_training_history(history, save_path):
    """Plot training and validation curves."""
    fig, axes = plt.subplots(1, 2, figsize=(14, 5))

    epochs = history['epochs']

    axes[0].plot(epochs, history['val_loss'], 'b-', label='Validation Loss', linewidth=2, marker='o')
    axes[0].plot(epochs, history['train_loss'], 'r--', label='Training Loss', linewidth=2, marker='s', alpha=0.7)
    axes[0].set_xlabel('Epoch', fontsize=12, fontweight='bold')
    axes[0].set_ylabel('Loss', fontsize=12, fontweight='bold')
    axes[0].set_title('Training & Validation Loss', fontsize=14, fontweight='bold')
    axes[0].legend(fontsize=11)
    axes[0].grid(True, alpha=0.3)

    axes[1].plot(epochs, history['val_acc'], 'b-', label='Validation Accuracy', linewidth=2, marker='o')
    axes[1].plot(epochs, history['train_acc'], 'r--', label='Training Accuracy', linewidth=2, marker='s', alpha=0.7)
    axes[1].set_xlabel('Epoch', fontsize=12, fontweight='bold')
    axes[1].set_ylabel('Accuracy', fontsize=12, fontweight='bold')
    axes[1].set_title('Training & Validation Accuracy', fontsize=14, fontweight='bold')
    axes[1].legend(fontsize=11)
    axes[1].grid(True, alpha=0.3)
    axes[1].yaxis.set_major_formatter(plt.FuncFormatter(lambda y, _: f'{y*100:.1f}%'))

    plt.tight_layout()
    plt.savefig(save_path, dpi=300, bbox_inches='tight')
    print(f"✓ Training curves saved to {save_path}")
    plt.show()


def plot_sample_predictions(model, dataloader, device, class_names, num_samples=8, save_path=None):
    """Plot sample predictions with true/predicted labels."""
    model.eval()

    all_inputs, all_labels, all_preds, all_probs = [], [], [], []

    with torch.no_grad():
        for inputs, labels in dataloader:
            inputs = inputs.to(device)
            outputs = model(inputs)
            probs = torch.softmax(outputs, dim=1)
            _, preds = torch.max(outputs, 1)

            all_inputs.extend(inputs.cpu())
            all_labels.extend(labels.numpy())
            all_preds.extend(preds.cpu().numpy())
            all_probs.extend(probs.cpu().numpy()[:, 1])

            if len(all_inputs) >= num_samples:
                break

    indices = np.random.choice(len(all_inputs), min(num_samples, len(all_inputs)), replace=False)

    rows = (num_samples + 3) // 4
    cols = min(4, num_samples)
    fig, axes = plt.subplots(rows, cols, figsize=(cols * 4, rows * 4))
    axes = axes.flatten()

    for idx, ax in enumerate(axes):
        if idx >= len(indices):
            ax.axis('off')
            continue

        i = indices[idx]
        img = all_inputs[i].numpy().transpose((1, 2, 0))
        mean = np.array([0.485, 0.456, 0.406])
        std = np.array([0.229, 0.224, 0.225])
        img = std * img + mean
        img = np.clip(img, 0, 1)

        true_label = class_names[all_labels[i]]
        pred_label = class_names[all_preds[i]]
        prob = all_probs[i]

        is_correct = (all_labels[i] == all_preds[i])
        color = 'green' if is_correct else 'red'

        ax.imshow(img)
        ax.set_title(f"True: {true_label}\nPred: {pred_label} ({prob*100:.1f}%)", color=color, fontsize=10)
        ax.axis('off')

    plt.tight_layout()
    if save_path:
        plt.savefig(save_path, dpi=300, bbox_inches='tight')
        print(f"✓ Sample predictions saved to {save_path}")
    plt.show()


# ============ Grad-CAM Heatmap for Vision Transformer ============

class ViTGradCAM:
    """
    Grad-CAM implementation for Vision Transformer (ViT)
    Adapted for torchvision's vit_b_16 model
    """
    def __init__(self, model, target_layer=None):
        self.model = model
        self.model.eval()
        self.gradients = None
        self.activations = None
        
        # Register hooks - auto-detect if target_layer not provided
        if target_layer is None:
            target_layer = self._find_target_layer()
        
        self.target_layer = target_layer
        self._register_hooks()
        print(f"✓ ViTGradCAM initialized with target layer: {target_layer.__class__.__name__}")
    
    def _find_target_layer(self):
        """Automatically find the appropriate target layer for torchvision ViT"""
        # For torchvision's vit_b_16
        if hasattr(self.model, 'encoder') and hasattr(self.model.encoder, 'layers'):
            last_layer = self.model.encoder.layers[-1]
            if hasattr(last_layer, 'ln_1'):  # torchvision uses ln_1
                print("✓ Auto-detected target layer: encoder.layers[-1].ln_1")
                return last_layer.ln_1
        # Fallback: try to find any norm layer
        for name, module in self.model.named_modules():
            if 'ln_1' in name or 'norm' in name:
                print(f"✓ Auto-detected target layer: {name}")
                return module
        raise AttributeError("Could not find target layer. Please provide target_layer manually.")
    
    def _register_hooks(self):
        """Register forward and backward hooks on target layer."""
        def forward_hook(module, input, output):
            self.activations = output
            
        def backward_hook(module, grad_input, grad_output):
            self.gradients = grad_output[0]
        
        self.target_layer.register_forward_hook(forward_hook)
        self.target_layer.register_backward_hook(backward_hook)
    
    def _reshape_to_2d(self, tensor):
        """
        Reshape ViT features from sequence format to 2D spatial format.
        """
        # Remove CLS token (first token)
        if tensor.shape[1] > 1:
            patch_tokens = tensor[:, 1:, :]
        else:
            patch_tokens = tensor
        
        # Calculate grid size (assuming square grid)
        num_patches = patch_tokens.shape[1]
        grid_size = int(np.sqrt(num_patches))
        hidden_dim = patch_tokens.shape[-1]
        
        # Reshape to spatial grid
        patch_tokens_2d = patch_tokens.reshape(-1, grid_size, grid_size, hidden_dim)
        return patch_tokens_2d
    
    def generate_cam(self, input_tensor, target_class=None):
        """
        Generate Grad-CAM heatmap for the input image.
        """
        input_tensor = input_tensor.clone().detach().requires_grad_(True)
        
        # Forward pass
        output = self.model(input_tensor)
        
        if target_class is None:
            target_class = output.argmax(dim=1).item()
        
        # Zero gradients
        self.model.zero_grad()
        
        # Backward pass for target class
        output[0, target_class].backward()
        
        # Get gradients and activations
        gradients = self.gradients
        activations = self.activations
        
        if gradients is None or activations is None:
            raise ValueError("Failed to capture gradients or activations. Check hook registration.")
        
        # Reshape to spatial format
        act_2d = self._reshape_to_2d(activations)
        grad_2d = self._reshape_to_2d(gradients)
        
        # Global average pooling of gradients
        weights = grad_2d.mean(dim=(1, 2), keepdim=True)
        
        # Weighted combination of activation maps
        cam = (weights * act_2d).sum(dim=-1)
        
        # Apply ReLU
        cam = torch.relu(cam)
        cam = cam.squeeze().cpu().detach().numpy()
        
        # Normalize to [0, 1]
        if cam.max() > cam.min():
            cam = (cam - cam.min()) / (cam.max() - cam.min())
        
        return cam
    
    def overlay_heatmap(self, heatmap, image, alpha=0.5, colormap=cv2.COLORMAP_JET):
        """Overlay heatmap on original image."""
        if isinstance(image, Image.Image):
            image = np.array(image)
        
        if image.dtype != np.uint8:
            if image.max() <= 1.0:
                image = (image * 255).astype(np.uint8)
            else:
                image = image.astype(np.uint8)
        
        heatmap_resized = cv2.resize(heatmap, (image.shape[1], image.shape[0]))
        heatmap_colored = cv2.applyColorMap(np.uint8(255 * heatmap_resized), colormap)
        heatmap_colored = cv2.cvtColor(heatmap_colored, cv2.COLOR_BGR2RGB)
        overlay = cv2.addWeighted(image, 1 - alpha, heatmap_colored, alpha, 0)
        
        return overlay


def visualize_heatmaps(model, dataloader, device, class_names, num_samples=8, save_path=None, target_layer=None):
    """
    Generate and display Grad-CAM heatmaps for multiple test samples.
    """
    model.eval()
    
    # Initialize Grad-CAM for ViT with optional target_layer
    grad_cam = ViTGradCAM(model, target_layer=target_layer)
    
    # Collect samples
    all_inputs = []
    all_labels = []
    all_preds = []
    all_probs = []
    all_original_images = []
    
    with torch.no_grad():
        for inputs, labels in dataloader:
            inputs = inputs.to(device)
            outputs = model(inputs)
            probs = torch.softmax(outputs, dim=1)
            _, preds = torch.max(outputs, 1)
            
            all_inputs.extend(inputs.cpu())
            all_labels.extend(labels.numpy())
            all_preds.extend(preds.cpu().numpy())
            all_probs.extend(probs.cpu().numpy()[:, 1])
            
            # Denormalize images
            for i in range(inputs.size(0)):
                img = inputs[i].cpu().numpy().transpose((1, 2, 0))
                mean = np.array([0.485, 0.456, 0.406])
                std = np.array([0.229, 0.224, 0.225])
                img = std * img + mean
                img = np.clip(img, 0, 1)
                all_original_images.append(img)
            
            if len(all_inputs) >= num_samples:
                break
    
    num_samples = min(num_samples, len(all_inputs))
    indices = np.random.choice(len(all_inputs), num_samples, replace=False)
    
    rows = num_samples
    cols = 3
    fig, axes = plt.subplots(rows, cols, figsize=(cols * 4, rows * 4))
    
    if rows == 1:
        axes = axes.reshape(1, -1)
    
    for idx in range(num_samples):
        sample_idx = indices[idx]
        
        original_img = all_original_images[sample_idx]
        input_tensor = all_inputs[sample_idx].unsqueeze(0).to(device)
        true_label = class_names[all_labels[sample_idx]]
        pred_label = class_names[all_preds[sample_idx]]
        prob = all_probs[sample_idx]
        is_correct = (all_labels[sample_idx] == all_preds[sample_idx])
        
        with torch.enable_grad():
            heatmap = grad_cam.generate_cam(input_tensor, target_class=all_preds[sample_idx])
        
        overlay = grad_cam.overlay_heatmap(heatmap, (original_img * 255).astype(np.uint8), alpha=0.5)
        
        axes[idx, 0].imshow(original_img)
        axes[idx, 0].set_title(f"Original\nTrue: {true_label}", fontsize=10)
        axes[idx, 0].axis('off')
        
        im = axes[idx, 1].imshow(heatmap, cmap='jet', alpha=0.8)
        axes[idx, 1].set_title(f"Heatmap\nPred: {pred_label} ({prob*100:.1f}%)", 
                               color='green' if is_correct else 'red', fontsize=10)
        axes[idx, 1].axis('off')
        plt.colorbar(im, ax=axes[idx, 1], fraction=0.046, pad=0.04)
        
        axes[idx, 2].imshow(overlay)
        axes[idx, 2].set_title("Overlay", fontsize=10)
        axes[idx, 2].axis('off')
    
    plt.suptitle("Grad-CAM Visualizations for ViT-based AI Image Detection", 
                 fontsize=16, fontweight='bold', y=1.02)
    plt.tight_layout()
    
    if save_path:
        plt.savefig(save_path, dpi=300, bbox_inches='tight')
        print(f"✓ Heatmap visualizations saved to {save_path}")
    
    plt.show()
    
    return grad_cam
