from io import BytesIO
import unittest
import json
import os
import base64
import cv2
import numpy as np
from app import app
from image_processor import ImageEnhancer


class TestImageEnhancementAPI(unittest.TestCase):
    """
    Unit tests for the Image Enhancement API
    """
    
    @classmethod
    def setUpClass(cls):
        """Set up test fixtures"""
        cls.app = app
        cls.client = cls.app.test_client()
        cls.app.config['TESTING'] = True
        
        # Create test image
        cls.test_image = np.random.randint(0, 255, (100, 100, 3), dtype=np.uint8)
        _, buffer = cv2.imencode('.jpg', cls.test_image)
        cls.test_image_bytes = buffer.tobytes()
        cls.test_image_base64 = base64.b64encode(cls.test_image_bytes).decode('utf-8')
    
    def test_index_endpoint(self):
        """Test the index endpoint"""
        response = self.client.get('/')
        self.assertEqual(response.status_code, 200)
        
        data = json.loads(response.data)
        self.assertEqual(data['status'], 'online')
        self.assertIn('service', data)
    
    def test_health_endpoint(self):
        """Test the health check endpoint"""
        response = self.client.get('/health')
        self.assertEqual(response.status_code, 200)
        
        data = json.loads(response.data)
        self.assertEqual(data['status'], 'healthy')
        self.assertTrue(data['model_loaded'])
    
    def test_methods_endpoint(self):
        """Test the methods listing endpoint"""
        response = self.client.get('/methods')
        self.assertEqual(response.status_code, 200)
        
        data = json.loads(response.data)
        self.assertIn('methods', data)
        self.assertGreater(len(data['methods']), 0)
    
    def test_enhance_image_with_file(self):
        """Test image enhancement with file upload"""
        data = {
            'image': (BytesIO(self.test_image_bytes), 'test.jpg'),
            'method': 'auto'
        }
        
        response = self.client.post('/enhance_image', 
                                   data=data,
                                   content_type='multipart/form-data')
        
        self.assertEqual(response.status_code, 200)
        
        result = json.loads(response.data)
        self.assertTrue(result['success'])
        self.assertIn('enhanced_image', result)
        self.assertIn('metrics', result)
    
    def test_enhance_image_with_base64(self):
        """Test image enhancement with base64 JSON"""
        data = {
            'image': f'data:image/jpeg;base64,{self.test_image_base64}',
            'method': 'sharpen',
            'filename': 'test.jpg'
        }
        
        response = self.client.post('/enhance_image',
                                   data=json.dumps(data),
                                   content_type='application/json')
        
        self.assertEqual(response.status_code, 200)
        
        result = json.loads(response.data)
        self.assertTrue(result['success'])
        self.assertIn('enhanced_image', result)
    
    def test_enhance_image_invalid_method(self):
        """Test with invalid file type"""
        data = {
            'image': (BytesIO(b'fake data'), 'test.txt'),
        }
        
        response = self.client.post('/enhance_image',
                                   data=data,
                                   content_type='multipart/form-data')
        
        self.assertEqual(response.status_code, 400)
    
    def test_enhance_image_no_file(self):
        """Test with no file provided"""
        response = self.client.post('/enhance_image',
                                   data={},
                                   content_type='multipart/form-data')
        
        self.assertEqual(response.status_code, 400)


class TestImageEnhancer(unittest.TestCase):
    """
    Unit tests for the ImageEnhancer class
    """
    
    @classmethod
    def setUpClass(cls):
        """Set up test fixtures"""
        cls.enhancer = ImageEnhancer()
        cls.test_image = np.random.randint(0, 255, (100, 100, 3), dtype=np.uint8)
    
    def test_auto_enhance(self):
        """Test auto enhancement method"""
        enhanced, metrics = self.enhancer.enhance(self.test_image, method='auto')
        
        self.assertIsNotNone(enhanced)
        self.assertEqual(enhanced.shape, self.test_image.shape)
        self.assertIsInstance(metrics, dict)
    
    def test_sharpen(self):
        """Test sharpening method"""
        enhanced, metrics = self.enhancer.enhance(self.test_image, method='sharpen')
        
        self.assertIsNotNone(enhanced)
        self.assertEqual(enhanced.shape, self.test_image.shape)
    
    def test_denoise(self):
        """Test denoising method"""
        enhanced, metrics = self.enhancer.enhance(self.test_image, method='denoise')
        
        self.assertIsNotNone(enhanced)
        self.assertEqual(enhanced.shape, self.test_image.shape)
    
    def test_enhance_brightness_contrast(self):
        """Test brightness/contrast enhancement"""
        enhanced, metrics = self.enhancer.enhance(self.test_image, method='enhance')
        
        self.assertIsNotNone(enhanced)
        self.assertEqual(enhanced.shape, self.test_image.shape)
    
    def test_deblur(self):
        """Test deblurring method"""
        enhanced, metrics = self.enhancer.enhance(self.test_image, method='deblur')
        
        self.assertIsNotNone(enhanced)
        self.assertEqual(enhanced.shape, self.test_image.shape)
    
    def test_metrics_calculation(self):
        """Test metrics calculation"""
        enhanced, metrics = self.enhancer.enhance(self.test_image, method='auto')
        
        self.assertIn('psnr', metrics)
        self.assertIn('ssim', metrics)
        self.assertIn('original_sharpness', metrics)
        self.assertIn('enhanced_sharpness', metrics)


if __name__ == '__main__':
    unittest.main()
