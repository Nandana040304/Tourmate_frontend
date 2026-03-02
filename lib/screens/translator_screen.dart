import 'package:flutter/material.dart';

import 'package:image_picker/image_picker.dart';

import '../services/api_service.dart';



class TranslatorScreen extends StatefulWidget {

  const TranslatorScreen({super.key});



  @override

  State<TranslatorScreen> createState() => _TranslatorScreenState();

}



class _TranslatorScreenState extends State<TranslatorScreen> {

  final TextEditingController _manualTextController = TextEditingController();

  String _selectedSourceLanguage = 'Malayalam';

  String _selectedTargetLanguage = 'English';

  String _extractedText = '';

  String _translatedText = '';

  String? _imagePath;

  bool _isTranslating = false;

  bool _hasError = false;

  String _errorMessage = '';



  final ImagePicker _imagePicker = ImagePicker();



  @override

  void dispose() {

    _manualTextController.dispose();

    super.dispose();

  }



  // Show image source selection dialog

  Future<void> _showImageSourceDialog() {

    return showDialog(

      context: context,

      builder: (context) => AlertDialog(

        title: const Text('Select Image Source'),

        content: Column(

          mainAxisSize: MainAxisSize.min,

          children: [

            ListTile(

              leading: const Icon(Icons.camera_alt),

              title: const Text('Camera'),

              onTap: () {

                Navigator.pop(context);

                _pickImage(ImageSource.camera);

              },

            ),

            ListTile(

              leading: const Icon(Icons.photo_library),

              title: const Text('Gallery'),

              onTap: () {

                Navigator.pop(context);

                _pickImage(ImageSource.gallery);

              },

            ),

          ],

        ),

      ),

    );

  }



  // Pick image from camera or gallery

  Future<void> _pickImage(ImageSource source) async {

    try {

      final XFile? pickedFile = await _imagePicker.pickImage(

        source: source,

        maxWidth: 800,

        maxHeight: 600,

        imageQuality: 80,

      );



      if (pickedFile != null) {

        setState(() {

          _imagePath = pickedFile.path;

          _extractedText = '';

          _translatedText = '';

          _hasError = false;

          _errorMessage = '';

        });

        

        // Simulate OCR processing (in real app, this would call OCR API)

        _simulateOCR();

      }

    } catch (e) {

      _showError('Failed to pick image: $e');

    }

  }



  // Simulate OCR text extraction (mock implementation)

  // after picking the image...

  Future<void> _simulateOCR() async {

    setState(() {

      _isTranslating = true;

      _hasError = false;

      _translatedText = '';

      _extractedText = '';

    });



    try {

      // call backend OCR+translate endpoint

      final result = await ApiService.ocrAndTranslate(

        _imagePath!,

        sourceLanguage:

        _selectedSourceLanguage == 'Malayalam' ? 'ml' : 'en',

        targetLanguage:

        _selectedTargetLanguage == 'English' ? 'en' : 'ml',

      );



      if (result['success'] == 'true') {

        setState(() {

          _extractedText = result['extracted_text'] ?? '';

          _translatedText = result['translated_text'] ?? '';

        });

      } else {

        _showError(result['error'] ?? 'OCR/translation failed');

      }

    } catch (e) {

      _showError('Error: $e');

    } finally {

      setState(() {

        _isTranslating = false;

      });

    }

  }



  // Translate text (mock implementation)

  Future<void> _translateText() async {

    String sourceText = _manualTextController.text.isNotEmpty

        ? _manualTextController.text

        : _extractedText;



    if (sourceText.isEmpty && _imagePath == null) {

      _showError('Please enter text or upload an image');

      return;

    }



    setState(() {

      _isTranslating = true;

      _hasError = false;

    });



    String sourceCode = _selectedSourceLanguage == 'Malayalam' ? 'ml' : 'en';

    String targetCode = _selectedTargetLanguage == 'English' ? 'en' : 'ml';



    // If image is uploaded, use OCR+Translate endpoint

    if (_imagePath != null && sourceText.isEmpty) {

      final result = await ApiService.ocrAndTranslate(

        _imagePath!,

        sourceLanguage: sourceCode,

        targetLanguage: targetCode,

      );



      setState(() {

        if (result['success'] == 'false') {

          _showError(result['error'] ?? 'OCR translation failed');

        } else {

          _extractedText = result['extracted_text'] ?? '';

          _translatedText = result['translated_text'] ?? '';

        }

        _isTranslating = false;

      });

    } else {

      // Standard text translation

      final translatedText = await ApiService.translateText(

        sourceText,

        sourceLanguage: sourceCode,

        targetLanguage: targetCode,

      );



      setState(() {

        if (translatedText.startsWith('Error') || translatedText.startsWith('Network')) {

          _showError(translatedText);

        } else {

          _translatedText = translatedText;

        }

        _isTranslating = false;

      });

    }

  }



  // Show error message

  void _showError(String message) {

    setState(() {

      _hasError = true;

      _errorMessage = message;

      _isTranslating = false;

    });

  }



  @override

  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(

        title: Row(

          children: [

            const Icon(Icons.translate, color: Colors.white, size: 24),

            const SizedBox(width: 8),

            const Text(

              'Translator',

              style: TextStyle(

                color: Colors.white,

                fontWeight: FontWeight.w600,

              ),

            ),

          ],

        ),

        centerTitle: true,

        flexibleSpace: Container(

          decoration: const BoxDecoration(

            gradient: LinearGradient(

              colors: [Color(0xFF2196F3), Color(0xFF1976D2)],

              begin: Alignment.topLeft,

              end: Alignment.bottomRight,

            ),

          ),

        ),

      ),

      body: Column(

        children: [

          _buildLanguageSelector(),

          Expanded(

            child: SingleChildScrollView(

              padding: const EdgeInsets.all(16),

              child: Column(

                children: [

                  _buildImageSection(),

                  const SizedBox(height: 20),

                  _buildExtractedTextSection(),

                  const SizedBox(height: 16),

                  _buildTranslatedTextSection(),

                  const SizedBox(height: 16),

                  _buildManualTextInputSection(),

                  const SizedBox(height: 20),

                  _buildTranslateButton(),

                  if (_hasError) ...[

                    const SizedBox(height: 16),

                    _buildErrorMessage(),

                  ],

                  const SizedBox(height: 80), // Bottom navigation padding

                ],

              ),

            ),

          ),

        ],

      ),

      bottomNavigationBar: _buildBottomNavigationBar(),

    );

  }



  // Language selector with pill-shaped buttons

  Widget _buildLanguageSelector() {

    return Container(

      padding: const EdgeInsets.all(16),

      color: Colors.grey[50],

      child: Row(

        children: [

          Expanded(

            child: GestureDetector(

              onTap: () {

                setState(() {

                  _selectedSourceLanguage = 'Malayalam';

                  _selectedTargetLanguage = 'English';

                });

              },

              child: Container(

                padding: const EdgeInsets.symmetric(vertical: 12),

                decoration: BoxDecoration(

                  color: _selectedSourceLanguage == 'Malayalam' 

                      ? const Color(0xFF2196F3) 

                      : Colors.white,

                  borderRadius: BorderRadius.circular(25),

                  border: Border.all(

                    color: const Color(0xFF2196F3),

                    width: 1,

                  ),

                  boxShadow: [

                    BoxShadow(

                      color: Colors.black.withValues(alpha: 0.1),

                      blurRadius: 4,

                      offset: const Offset(0, 2),

                    ),

                  ],

                ),

                child: Row(

                  mainAxisAlignment: MainAxisAlignment.center,

                  children: [

                    Container(

                      width: 24,

                      height: 24,

                      decoration: BoxDecoration(

                        color: Colors.orange,

                        borderRadius: BorderRadius.circular(12),

                      ),

                      child: const Center(

                        child: Text(

                          '🇮🇳',

                          style: TextStyle(fontSize: 14),

                        ),

                      ),

                    ),

                    const SizedBox(width: 8),

                    Text(

                      'Malayalam',

                      style: TextStyle(

                        color: _selectedSourceLanguage == 'Malayalam' 

                            ? Colors.white 

                            : Colors.black87,

                        fontWeight: FontWeight.w600,

                      ),

                    ),

                  ],

                ),

              ),

            ),

          ),

          const SizedBox(width: 12),

          const Icon(Icons.arrow_forward, color: Colors.grey),

          const SizedBox(width: 12),

          Expanded(

            child: GestureDetector(

              onTap: () {

                setState(() {

                  _selectedSourceLanguage = 'English';

                  _selectedTargetLanguage = 'Malayalam';

                });

              },

              child: Container(

                padding: const EdgeInsets.symmetric(vertical: 12),

                decoration: BoxDecoration(

                  color: _selectedTargetLanguage == 'English' 

                      ? const Color(0xFF2196F3) 

                      : Colors.white,

                  borderRadius: BorderRadius.circular(25),

                  border: Border.all(

                    color: const Color(0xFF2196F3),

                    width: 1,

                  ),

                  boxShadow: [

                    BoxShadow(

                      color: Colors.black.withValues(alpha: 0.1),

                      blurRadius: 4,

                      offset: const Offset(0, 2),

                    ),

                  ],

                ),

                child: Row(

                  mainAxisAlignment: MainAxisAlignment.center,

                  children: [

                    Container(

                      width: 24,

                      height: 24,

                      decoration: BoxDecoration(

                        color: Colors.blue,

                        borderRadius: BorderRadius.circular(12),

                      ),

                      child: const Center(

                        child: Text(

                          '🇺🇸',

                          style: TextStyle(fontSize: 14),

                        ),

                      ),

                    ),

                    const SizedBox(width: 8),

                    Text(

                      'English',

                      style: TextStyle(

                        color: _selectedTargetLanguage == 'English' 

                            ? Colors.white 

                            : Colors.black87,

                        fontWeight: FontWeight.w600,

                      ),

                    ),

                  ],

                ),

              ),

            ),

          ),

        ],

      ),

    );

  }



  // Image upload/preview section

  Widget _buildImageSection() {

    return Container(

      height: 200,

      decoration: BoxDecoration(

        color: Colors.white,

        borderRadius: BorderRadius.circular(16),

        border: Border.all(color: Colors.grey[300]!),

        boxShadow: [

          BoxShadow(

            color: Colors.black.withValues(alpha: 0.08),

            blurRadius: 8,

            offset: const Offset(0, 4),

          ),

        ],

      ),

      child: _imagePath != null

          ? ClipRRect(

              borderRadius: BorderRadius.circular(16),

              child: Stack(

                fit: StackFit.expand,

                children: [

                  Image.asset(

                    _imagePath!,

                    fit: BoxFit.cover,

                    errorBuilder: (context, error, stackTrace) {

                      return Container(

                        color: Colors.grey[100],

                        child: const Center(

                          child: Icon(Icons.image, size: 48, color: Colors.grey),

                        ),

                      );

                    },

                  ),

                  Positioned(

                    top: 8,

                    right: 8,

                    child: GestureDetector(

                      onTap: () {

                        setState(() {

                          _imagePath = null;

                          _extractedText = '';

                          _translatedText = '';

                        });

                      },

                      child: Container(

                        padding: const EdgeInsets.all(4),

                        decoration: BoxDecoration(

                          color: Colors.black.withValues(alpha: 0.5),

                          borderRadius: BorderRadius.circular(12),

                        ),

                        child: const Icon(

                          Icons.close,

                          color: Colors.white,

                          size: 20,

                        ),

                      ),

                    ),

                  ),

                ],

              ),

            )

          : GestureDetector(

              onTap: _showImageSourceDialog,

              child: Column(

                mainAxisAlignment: MainAxisAlignment.center,

                children: [

                  Icon(

                    Icons.cloud_upload,

                    size: 48,

                    color: Colors.grey[400],

                  ),

                  const SizedBox(height: 12),

                  Text(

                    'Tap to upload image',

                    style: TextStyle(

                      color: Colors.grey[600],

                      fontSize: 16,

                      fontWeight: FontWeight.w500,

                    ),

                  ),

                ],

              ),

            ),

    );

  }



  Widget _buildExtractedTextSection() {

    if (_extractedText.isEmpty && !_isTranslating) return const SizedBox.shrink();

    

    return Container(

      width: double.infinity,

      padding: const EdgeInsets.all(16),

      decoration: BoxDecoration(

        color: Colors.white,

        borderRadius: BorderRadius.circular(12),

        border: Border.all(color: Colors.grey[200]!),

        boxShadow: [

          BoxShadow(

            color: Colors.black.withValues(alpha: 0.05),

            blurRadius: 4,

            offset: const Offset(0, 2),

          ),

        ],

      ),

      child: Column(

        crossAxisAlignment: CrossAxisAlignment.start,

        children: [

          Text(

            'Extracted Text ($_selectedSourceLanguage)',

            style: const TextStyle(

              fontSize: 14,

              fontWeight: FontWeight.bold,

              color: Colors.blue,

            ),

          ),

          const SizedBox(height: 8),

          _isTranslating && _extractedText.isEmpty

              ? const LinearProgressIndicator()

              : Text(

                  _extractedText,

                  style: const TextStyle(fontSize: 16),

                ),

        ],

      ),

    );

  }



  Widget _buildTranslatedTextSection() {

    if (_translatedText.isEmpty && !_isTranslating) return const SizedBox.shrink();

    

    return Container(

      width: double.infinity,

      padding: const EdgeInsets.all(16),

      decoration: BoxDecoration(

        color: Colors.blue[50],

        borderRadius: BorderRadius.circular(12),

        border: Border.all(color: Colors.blue[100]!),

        boxShadow: [

          BoxShadow(

            color: Colors.black.withValues(alpha: 0.05),

            blurRadius: 4,

            offset: const Offset(0, 2),

          ),

        ],

      ),

      child: Column(

        crossAxisAlignment: CrossAxisAlignment.start,

        children: [

          Text(

            'Translated Text ($_selectedTargetLanguage)',

            style: const TextStyle(

              fontSize: 14,

              fontWeight: FontWeight.bold,

              color: Colors.blue,

            ),

          ),

          const SizedBox(height: 8),

          _isTranslating && _translatedText.isEmpty

              ? const LinearProgressIndicator()

              : Text(

                  _translatedText,

                  style: const TextStyle(

                    fontSize: 18,

                    fontWeight: FontWeight.w500,

                    color: Colors.black87,

                  ),

                ),

        ],

      ),

    );

  }



  Widget _buildManualTextInputSection() {

    return Container(

      padding: const EdgeInsets.all(16),

      decoration: BoxDecoration(

        color: Colors.white,

        borderRadius: BorderRadius.circular(12),

        border: Border.all(color: Colors.grey[200]!),

        boxShadow: [

          BoxShadow(

            color: Colors.black.withValues(alpha: 0.05),

            blurRadius: 4,

            offset: const Offset(0, 2),

          ),

        ],

      ),

      child: TextField(

        controller: _manualTextController,

        maxLines: 3,

        decoration: const InputDecoration(

          hintText: 'Or enter text manually to translate...',

          border: InputBorder.none,

        ),

      ),

    );

  }



  Widget _buildTranslateButton() {

    return SizedBox(

      width: double.infinity,

      height: 50,

      child: ElevatedButton(

        onPressed: _isTranslating ? null : _translateText,

        style: ElevatedButton.styleFrom(

          backgroundColor: const Color(0xFF2196F3),

          foregroundColor: Colors.white,

          shape: RoundedRectangleBorder(

            borderRadius: BorderRadius.circular(25),

          ),

          elevation: 4,

          shadowColor: Colors.green.withValues(alpha: 0.3),

        ),

        child: _isTranslating

            ? const SizedBox(

                height: 20,

                width: 20,

                child: CircularProgressIndicator(

                  color: Colors.white,

                  strokeWidth: 2,

                ),

              )

            : const Row(

                mainAxisAlignment: MainAxisAlignment.center,

                children: [

                  Icon(Icons.translate),

                  SizedBox(width: 8),

                  Text(

                    'Translate Now',

                    style: TextStyle(

                      fontSize: 16,

                      fontWeight: FontWeight.bold,

                    ),

                  ),

                ],

              ),

      ),

    );

  }



  Widget _buildErrorMessage() {

    return Container(

      padding: const EdgeInsets.all(12),

      decoration: BoxDecoration(

        color: Colors.red[50],

        borderRadius: BorderRadius.circular(8),

        border: Border.all(color: Colors.red[100]!),

        boxShadow: [

          BoxShadow(

            color: Colors.black.withValues(alpha: 0.1),

            blurRadius: 4,

            offset: const Offset(0, 2),

          ),

        ],

      ),

      child: Row(

        children: [

          Icon(Icons.error_outline, color: Colors.red[700]),

          const SizedBox(width: 12),

          Expanded(

            child: Text(

              _errorMessage,

              style: TextStyle(color: Colors.red[700]),

            ),

          ),

          IconButton(

            icon: const Icon(Icons.close, size: 18),

            onPressed: () => setState(() => _hasError = false),

          ),

        ],

      ),

    );

  }



  Widget _buildBottomNavigationBar() {

    return Container(

      decoration: BoxDecoration(

        color: Colors.white,

        boxShadow: [

          BoxShadow(

            color: Colors.black.withValues(alpha: 0.1),

            blurRadius: 10,

            offset: const Offset(0, -2),

          ),

        ],

      ),

      child: BottomNavigationBar(

        currentIndex: 1, // Translator tab

        selectedItemColor: const Color(0xFF2196F3),

        unselectedItemColor: Colors.grey,

        type: BottomNavigationBarType.fixed,

        items: const [

          BottomNavigationBarItem(

            icon: Icon(Icons.dashboard_outlined),

            activeIcon: Icon(Icons.dashboard),

            label: 'Dashboard',

          ),

          BottomNavigationBarItem(

            icon: Icon(Icons.translate),

            label: 'Translator',

          ),

          BottomNavigationBarItem(

            icon: Icon(Icons.map_outlined),

            activeIcon: Icon(Icons.map),

            label: 'Places',

          ),

          BottomNavigationBarItem(

            icon: Icon(Icons.more_horiz),

            label: 'More',

          ),

        ],

        onTap: (index) {

          if (index == 0) Navigator.pop(context);

          if (index == 2) {

             Navigator.pushReplacementNamed(context, '/popular_places');

          }

          if (index == 3) {

             Navigator.pushReplacementNamed(context, '/more_options');

          }

        },

      ),

    );

  }

}