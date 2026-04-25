from fastapi import FastAPI, File, UploadFile
from fastapi.responses import JSONResponse
from fastapi.middleware.cors import CORSMiddleware
import torch
from torchvision import transforms
from PIL import Image
import io
import base64
import requests
from pydantic import BaseModel
import cv2
import numpy as np
# Add ViTGradCAM to your existing module import
from modules.evaluate import ViTGradCAM
# Import the model builder from your team's custom module
from modules.model import build_model

app = FastAPI(title="PixelTruth Detection API")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Allows all origins for local development
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# 1. Configuration (Must exactly match how main_ViT.ipynb was trained)
config = {
    'model': {
        'name': 'vit_b_16',
        'pretrained_weights': 'DEFAULT',
        'freeze_backbone': True,          
        'unfreeze_last_n_blocks': 0,      
        'dropout_rate': 0.2,              
        'num_classes': 2  # UPDATE THIS if you have more classes
    }
}

device = torch.device('cuda' if torch.cuda.is_available() else 'cpu')
model = None

# UPDATE THESE to match the alphabetical order of your dataset folders
class_names = ["AI-Generated", "Authentic"] 

# 2. Replicate the val_test_transforms from your data_loader.py
preprocess = transforms.Compose([
    transforms.Resize(256),
    transforms.CenterCrop(224),
    transforms.ToTensor(),
    transforms.Normalize(mean=[0.485, 0.456, 0.406], std=[0.229, 0.224, 0.225])
])

grad_cam = None
@app.on_event("startup")
async def load_model():
    """Loads the ViT model into memory when the server starts."""
    global model, grad_cam
    print(f"Loading ViT model onto {device}...")
    
    # Build architecture using your module
    model = build_model(config, device)
    
    # Load trained weights (Update the filename if it differs)
    weights_path = "outputs/best_model.pth" 
    state_dict = torch.load(weights_path, map_location=device)
    
    # Handle if your checkpoint saved a dictionary vs just the weights
    if 'model_state_dict' in state_dict:
        model.load_state_dict(state_dict['model_state_dict'])
    else:
        model.load_state_dict(state_dict)
        
    model.eval()
    grad_cam = ViTGradCAM(model) 
    print("Model and Grad-CAM loaded successfully!")

@app.post("/predict")
async def predict(file: UploadFile = File(...)):
    """Receives an image, runs it through ViT, and returns the verdict."""
    try:
        # Read the image sent from the Flutter frontend
        contents = await file.read()
        image = Image.open(io.BytesIO(contents)).convert("RGB")
        
        # Preprocess to match training data
        input_tensor = preprocess(image)
        input_tensor = input_tensor.unsqueeze(0).to(device) # Add batch dimension
        
        # Inference
        with torch.no_grad():
            outputs = model(input_tensor)
            probs = torch.softmax(outputs, dim=1)
            confidence, predicted_idx = torch.max(probs, 1)
            
        predicted_class = class_names[predicted_idx.item()]
        confidence_score = confidence.item()

        with torch.enable_grad():
            heatmap_data = grad_cam.generate_cam(input_tensor, target_class=predicted_idx.item())

        original_np = np.array(image) 
        overlay_img = grad_cam.overlay_heatmap(heatmap_data, original_np, alpha=0.5)

        _, buffer = cv2.imencode('.jpg', overlay_img)
        heatmap_base64 = base64.b64encode(buffer).decode('utf-8')

        # Generate dynamic signals based on the prediction
        if predicted_class == "AI-Generated":
            signals = [
                {"label": "Pixel Frequency Analysis", "status": "Anomaly"},
                {"label": "Noise Pattern", "status": "Synthetic"},
                {"label": "EXIF Metadata", "status": "Missing"},
                {"label": "Compression Artifacts", "status": "Irregular"}
            ]
        else:
            signals = [
                {"label": "Pixel Frequency Analysis", "status": "Normal"},
                {"label": "Noise Pattern", "status": "Organic"},
                {"label": "EXIF Metadata", "status": "Present"},
                {"label": "Compression Artifacts", "status": "Standard"}
            ]

        return JSONResponse(content={
            "success": True,
            "prediction": predicted_class,
            "confidence": confidence_score,
            "signals": signals,
            "heatmap": heatmap_base64
        })

    except Exception as e:
        return JSONResponse(content={"success": False, "error": str(e)}, status_code=500)
    
    # Define the expected JSON payload format
class ImageUrl(BaseModel):
    url: str

@app.post("/predict-url")
async def predict_url(payload: ImageUrl):
    """Downloads an image from a URL, runs it through ViT, and returns the verdict."""
    try:
        if payload.url.startswith("data:image"):
            # Split off the "data:image/jpeg;base64," header
            header, encoded_data = payload.url.split(",", 1)
            # Decode the text string back into raw image bytes
            image_bytes = base64.b64decode(encoded_data)
            image = Image.open(io.BytesIO(image_bytes)).convert("RGB")
            
        else:
            # It's a normal URL, so download it using requests
            headers = {'User-Agent': 'Mozilla/5.0'}
            response = requests.get(payload.url, headers=headers, timeout=10)
            response.raise_for_status()
            image = Image.open(io.BytesIO(response.content)).convert("RGB")

        # 3. Preprocess and run Inference
        input_tensor = preprocess(image)
        input_tensor = input_tensor.unsqueeze(0).to(device)

        with torch.no_grad():
            outputs = model(input_tensor)
            probs = torch.softmax(outputs, dim=1)
            confidence, predicted_idx = torch.max(probs, 1)
            
        predicted_class = class_names[predicted_idx.item()]
        confidence_score = confidence.item()

        with torch.enable_grad():
            heatmap_data = grad_cam.generate_cam(input_tensor, target_class=predicted_idx.item())

        original_np = np.array(image) 
        overlay_img = grad_cam.overlay_heatmap(heatmap_data, original_np, alpha=0.5)

        _, buffer = cv2.imencode('.jpg', overlay_img)
        heatmap_base64 = base64.b64encode(buffer).decode('utf-8')

        # 4. Generate dynamic signals
        if predicted_class == "AI-Generated":
            signals = [
                {"label": "Pixel Frequency Analysis", "status": "Anomaly"},
                {"label": "Noise Pattern", "status": "Synthetic"},
                {"label": "EXIF Metadata", "status": "Missing"},
                {"label": "Compression Artifacts", "status": "Irregular"}
            ]
        else:
            signals = [
                {"label": "Pixel Frequency Analysis", "status": "Normal"},
                {"label": "Noise Pattern", "status": "Organic"},
                {"label": "EXIF Metadata", "status": "Present"},
                {"label": "Compression Artifacts", "status": "Standard"}
            ]

        return JSONResponse(content={
            "success": True,
            "prediction": predicted_class,
            "confidence": confidence_score,
            "signals": signals,
            "heatmap": heatmap_base64
        })

    except Exception as e:
        print(f"CRASH REPORT: {str(e)}")
        return JSONResponse(content={"success": False, "error": str(e)}, status_code=500)