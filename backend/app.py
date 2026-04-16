from flask import Flask, request, jsonify, send_file, render_template
from flask_cors import CORS
from werkzeug.utils import secure_filename
import os
import cv2
import numpy as np
from io import BytesIO
import base64
from datetime import datetime
import logging
from image_processor_ai import ImageEnhancer  # Using AI-powered processor

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = Flask(__name__)
CORS(app)

# Configuration
app.config['MAX_CONTENT_LENGTH'] = 16 * 1024 * 1024  # 16MB max file size
app.config['UPLOAD_FOLDER'] = 'uploads'
app.config['ENHANCED_FOLDER'] = 'enhanced'
ALLOWED_EXTENSIONS = {'png', 'jpg', 'jpeg', 'bmp', 'tiff'}

# Create necessary directories
os.makedirs(app.config['UPLOAD_FOLDER'], exist_ok=True)
os.makedirs(app.config['ENHANCED_FOLDER'], exist_ok=True)

# Initialize image enhancer
enhancer = ImageEnhancer()


def allowed_file(filename):
    """Check if file extension is allowed"""
    return '.' in filename and filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS


def decode_base64_image(base64_string):
    """Decode base64 image to numpy array"""
    try:
        # Remove header if present
        if ',' in base64_string:
            base64_string = base64_string.split(',')[1]
        
        img_data = base64.b64decode(base64_string)
        nparr = np.frombuffer(img_data, np.uint8)
        img = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
        return img
    except Exception as e:
        logger.error(f"Error decoding base64 image: {str(e)}")
        return None


def encode_image_to_base64(img):
    """Encode numpy array image to base64 (without data URL prefix)"""
    try:
        _, buffer = cv2.imencode('.jpg', img, [cv2.IMWRITE_JPEG_QUALITY, 95])
        img_base64 = base64.b64encode(buffer).decode('utf-8')
        return img_base64
    except Exception as e:
        logger.error(f"Error encoding image to base64: {str(e)}")
        return None


@app.route('/')
def index():
    """Serve the web interface"""
    return render_template('index.html')


@app.route('/api/status')
def api_status():
    """API health check endpoint"""
    return jsonify({
        'status': 'online',
        'service': 'Image Enhancement API',
        'version': '1.0.0',
        'timestamp': datetime.now().isoformat()
    })


@app.route('/enhance_image', methods=['POST'])
def enhance_image():
    """
    Main endpoint for image enhancement
    Accepts: multipart/form-data with 'image' file OR JSON with base64 image
    Returns: Enhanced image as base64
    """
    try:
        img = None
        original_filename = None
        
        # Check if image is sent as file
        if 'image' in request.files:
            file = request.files['image']
            
            if file.filename == '':
                return jsonify({'error': 'No file selected'}), 400
            
            if not allowed_file(file.filename):
                return jsonify({'error': 'Invalid file type. Allowed: png, jpg, jpeg, bmp, tiff'}), 400
            
            original_filename = secure_filename(file.filename)
            
            # Read image
            file_bytes = np.frombuffer(file.read(), np.uint8)
            img = cv2.imdecode(file_bytes, cv2.IMREAD_COLOR)
            
        # Check if image is sent as base64 in JSON
        elif request.is_json:
            data = request.get_json()
            
            if 'image' not in data:
                return jsonify({'error': 'No image data provided'}), 400
            
            img = decode_base64_image(data['image'])
            original_filename = data.get('filename', 'uploaded_image.jpg')
        
        else:
            return jsonify({'error': 'Invalid request format. Send image as file or base64 JSON'}), 400
        
        if img is None:
            return jsonify({'error': 'Failed to decode image'}), 400
        
        # Get enhancement method from request
        method = request.form.get('method', 'auto') if 'image' in request.files else \
                 request.get_json().get('method', 'auto')
        
        logger.info(f"Processing image: {original_filename}, Method: {method}")
        
        # Enhance the image
        enhanced_img, metrics = enhancer.enhance(img, method=method)
        
        if enhanced_img is None:
            logger.error("Enhancement returned None")
            return jsonify({'error': 'Image enhancement failed', 'details': 'Enhancement returned None'}), 500
        
        logger.info(f"Enhanced image shape: {enhanced_img.shape}, dtype: {enhanced_img.dtype}")
        
        # Save enhanced image (optional)
        timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
        enhanced_filename = f"enhanced_{timestamp}_{original_filename}"
        enhanced_path = os.path.join(app.config['ENHANCED_FOLDER'], enhanced_filename)
        cv2.imwrite(enhanced_path, enhanced_img)
        
        # Convert enhanced image to base64
        enhanced_base64 = encode_image_to_base64(enhanced_img)
        
        if enhanced_base64 is None:
            logger.error("Failed to encode enhanced image")
            return jsonify({'error': 'Failed to encode enhanced image'}), 500
        
        logger.info(f"Base64 encoded length: {len(enhanced_base64)}")
        
        # Prepare response
        response = {
            'success': True,
            'enhanced_image': enhanced_base64,
            'original_filename': original_filename,
            'enhanced_filename': enhanced_filename,
            'method': method,
            'metrics': metrics,
            'timestamp': datetime.now().isoformat()
        }
        
        logger.info(f"Successfully enhanced image: {original_filename}")
        return jsonify(response), 200
        
    except Exception as e:
        logger.error(f"Error in enhance_image: {str(e)}")
        return jsonify({'error': f'Server error: {str(e)}'}), 500


@app.route('/health', methods=['GET'])
def health():
    """Detailed health check"""
    return jsonify({
        'status': 'healthy',
        'upload_folder': os.path.exists(app.config['UPLOAD_FOLDER']),
        'enhanced_folder': os.path.exists(app.config['ENHANCED_FOLDER']),
        'model_loaded': enhancer is not None,
        'timestamp': datetime.now().isoformat()
    })


@app.route('/methods', methods=['GET'])
def get_methods():
    """Get available enhancement methods"""
    return jsonify({
        'methods': [
            {'id': 'auto', 'name': 'Auto Enhancement', 'description': 'Advanced multi-stage automatic enhancement with guided filtering and tone mapping'},
            {'id': 'deblur', 'name': 'Deblur (Richardson-Lucy)', 'description': 'Superior deblurring using Richardson-Lucy deconvolution'},
            {'id': 'sharpen', 'name': 'Multi-Scale Sharpen', 'description': 'Advanced sharpening with edge protection and frequency separation'},
            {'id': 'denoise', 'name': 'Advanced Denoise', 'description': 'Multi-stage noise reduction with edge preservation'},
            {'id': 'enhance', 'name': 'Contrast Enhancement', 'description': 'Advanced brightness, contrast and tone mapping'},
            {'id': 'super_resolution', 'name': 'Super Resolution', 'description': 'Upscale image 2x with detail enhancement'},
            {'id': 'hdr', 'name': 'HDR Tone Mapping', 'description': 'HDR-like tone mapping for better dynamic range'},
            {'id': 'detail_enhance', 'name': 'Detail Enhancement', 'description': 'Frequency separation for enhanced details'}
        ]
    })


if __name__ == '__main__':
    print("=" * 60)
    print("Image Enhancement API Server")
    print("=" * 60)
    print("Server running on: http://127.0.0.1:8000")
    print("Endpoints:")
    print("  - GET  /           : Health check")
    print("  - POST /enhance_image : Enhance image")
    print("  - GET  /health     : Detailed health status")
    print("  - GET  /methods    : Available enhancement methods")
    print("=" * 60)
    
    # Use port 8000 (5000 is often used by AirPlay Receiver on macOS)
    port = int(os.environ.get('PORT', 8000))
    app.run(host='0.0.0.0', port=port, debug=True)
