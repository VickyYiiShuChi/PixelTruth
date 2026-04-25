"""
Model building module supporting ViT, ResNet50, and ConvNeXt.
"""
import torch
import torch.nn as nn
from torchvision import models

def build_model(config, device):
    model_cfg = config['model']
    model_name = model_cfg['name']

    print(f"Loading {model_name} Architecture...")

    if model_name == 'vit_b_16':
        weights = getattr(models.ViT_B_16_Weights, model_cfg['pretrained_weights'])
        model = models.vit_b_16(weights=weights)

        if model_cfg['freeze_backbone']:
            for param in model.encoder.parameters():
                param.requires_grad = False

            unfreeze_n = model_cfg['unfreeze_last_n_blocks']
            if unfreeze_n > 0:
                for param in model.encoder.layers[-unfreeze_n:].parameters():
                    param.requires_grad = True
                print(f"✓ Backbone frozen | Last {unfreeze_n} blocks unfrozen")
            else:
                print("✓ Backbone fully frozen")

        n_inputs = model.heads.head.in_features
        model.heads.head = nn.Sequential(
            nn.Dropout(p=model_cfg['dropout_rate']),
            nn.Linear(n_inputs, model_cfg['num_classes'])
        )

    elif model_name == 'resnet50':
        weights = getattr(models.ResNet50_Weights, model_cfg['pretrained_weights'])
        model = models.resnet50(weights=weights)

        if model_cfg['freeze_backbone']:
            for param in model.parameters():
                param.requires_grad = False
            print("✓ Backbone frozen")

        n_inputs = model.fc.in_features
        model.fc = nn.Sequential(
            nn.Dropout(p=model_cfg['dropout_rate']),
            nn.Linear(n_inputs, model_cfg['num_classes'])
        )

    elif model_name == 'convnext_tiny':
        weights = getattr(models.ConvNeXt_Tiny_Weights, model_cfg['pretrained_weights'])
        model = models.convnext_tiny(weights=weights)

        if model_cfg['freeze_backbone']:
            for param in model.parameters():
                param.requires_grad = False
            print("✓ Backbone frozen")

        n_inputs = model.classifier[2].in_features
        model.classifier = nn.Sequential(
            nn.LayerNorm(n_inputs),
            nn.Linear(n_inputs, model_cfg['num_classes'])
        )

    else:
        raise ValueError(f"Unsupported model: {model_name}")

    if model_name == 'vit_b_16':
        for param in model.heads.parameters():
            param.requires_grad = True
    elif model_name == 'resnet50':
        for param in model.fc.parameters():
            param.requires_grad = True
    else:
        for param in model.classifier.parameters():
            param.requires_grad = True

    total_params = sum(p.numel() for p in model.parameters())
    trainable_params = sum(p.numel() for p in model.parameters() if p.requires_grad)
    print(f"Total parameters: {total_params:,}")
    print(f"Trainable parameters: {trainable_params:,} ({trainable_params/total_params*100:.1f}%)")

    return model.to(device)
