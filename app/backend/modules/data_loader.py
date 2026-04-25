"""
Data loader module for DeepDetect 2025 dataset.
Splits training data into train/val, uses official test set for final evaluation.
"""
import os
import kagglehub
import torch
from torch.utils.data import DataLoader, random_split
from torchvision import datasets, transforms

def get_data_loaders(config):
    """
    Downloads dataset and creates train/val/test loaders.

    Data Split Strategy:
    - train: 90% of ddata/train (with augmentation)
    - val:   10% of ddata/train (no augmentation, for tuning)
    - test:  ddata/test (official test set, for final evaluation only)
    """
    print("Fetching dataset from Kaggle...")
    dataset_path = kagglehub.dataset_download("ayushmandatta1/deepdetect-2025")

    mean, std = [0.485, 0.456, 0.406], [0.229, 0.224, 0.225]

    train_transforms = transforms.Compose([
        transforms.Resize(256),
        transforms.RandomCrop(224),
        transforms.RandomHorizontalFlip(),
        transforms.ColorJitter(0.2, 0.2),
        transforms.ToTensor(),
        transforms.Normalize(mean, std)
    ])

    val_test_transforms = transforms.Compose([
        transforms.Resize(256),
        transforms.CenterCrop(224),
        transforms.ToTensor(),
        transforms.Normalize(mean, std)
    ])

    full_train_dataset = datasets.ImageFolder(
        os.path.join(dataset_path, "ddata/train"),
        transform=train_transforms
    )

    total_train = len(full_train_dataset)
    train_ratio = config['data_split']['train_ratio']

    train_size = int(train_ratio * total_train)
    val_size = total_train - train_size

    generator = torch.Generator().manual_seed(config['data_split']['seed'])
    train_dataset, val_dataset = random_split(
        full_train_dataset,
        [train_size, val_size],
        generator=generator
    )

    train_dataset.dataset.transform = train_transforms
    val_dataset.dataset.transform = val_test_transforms

    test_dataset = datasets.ImageFolder(
        os.path.join(dataset_path, "ddata/test"),
        transform=val_test_transforms
    )

    # Limit test set to match validation set size if requested
    if config['data_split'].get('limit_test_set', False):
        val_size = len(val_dataset)
        if len(test_dataset) > val_size:
            test_dataset, _ = random_split(
                test_dataset,
                [val_size, len(test_dataset) - val_size],
                generator=generator
            )
            print(f"✓ Test set limited to {val_size} samples (same as validation set)")

    batch_size = config['training']['batch_size']
    num_workers = config['training']['num_workers']

    dataloaders = {
        'train': DataLoader(train_dataset, batch_size=batch_size, shuffle=True, num_workers=num_workers),
        'val': DataLoader(val_dataset, batch_size=batch_size, shuffle=False, num_workers=num_workers),
        'test': DataLoader(test_dataset, batch_size=batch_size, shuffle=False, num_workers=num_workers),
    }

    dataset_sizes = {
        'train': len(train_dataset),
        'val': len(val_dataset),
        'test': len(test_dataset),
    }

    class_names = full_train_dataset.classes

    return dataloaders, dataset_sizes, class_names
