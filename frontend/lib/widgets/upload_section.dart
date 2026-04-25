import 'dart:typed_data';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:ui';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:http_parser/http_parser.dart';
import 'package:flutter/material.dart';
import '../constants/colors.dart';
import 'result_panel.dart';

class UploadSection extends StatefulWidget {
  const UploadSection({super.key});

  @override
  State<UploadSection> createState() => _UploadSectionState();
}

class _UploadSectionState extends State<UploadSection> {
  bool _isDragging = false;
  bool _isAnalyzing = false; // Tracks loading state
  
  String? _verdict;          // Holds the API result
  double? _confidence;       // Holds the API confidence
  List<dynamic> _signals = [];

  // Update this getter to check if we have a result from the backend
  bool get _hasResult => _verdict != null; 

  Uint8List? _imageBytes;       
  String? _imageMimeType;
  String? _uploadedNetworkUrl;  
  final TextEditingController _urlController = TextEditingController();
  String? _errorMessage;
  String? _heatmapBase64;

  StreamSubscription<html.MouseEvent>? _dragOverSub;
  StreamSubscription<html.MouseEvent>? _dropSub;
  StreamSubscription<html.MouseEvent>? _dragLeaveSub;

  static const _allowedMimes = [
    'image/jpeg', 'image/png', 'image/webp', 'image/heic'
  ];
  static const _maxBytes = 20 * 1024 * 1024; // 20MB


  @override
  void initState() {
    super.initState();
    // Bind your custom functions to the browser's native drag events!
    _dragOverSub = html.document.body!.onDragOver.listen(_onDragOver);
    _dropSub = html.document.body!.onDrop.listen(_onDrop);
    _dragLeaveSub = html.document.body!.onDragLeave.listen(_onDragLeave);
  }

  @override
  void dispose() {
    _urlController.dispose();
    // Clean up the listeners to prevent memory leaks
    _dragOverSub?.cancel();
    _dropSub?.cancel();
    _dragLeaveSub?.cancel();
    super.dispose();
  }

  bool get _hasUpload => _imageBytes != null || _uploadedNetworkUrl != null;
  void _setError(String msg) => setState(() => _errorMessage = msg);
  void _clearError() => setState(() => _errorMessage = null);

  void _handleAnalyze() {
    // 1. Check if a file was uploaded via drag-and-drop or browsing
    if (_imageBytes != null) {
      _analyzeImage(); 
    } 
    // 2. Otherwise, check if there is text in the URL box
    else if (_urlController.text.trim().isNotEmpty) {
      _analyzeUrl(); 
      // Note: _analyzeUrl currently just displays the image. 
      // To actually run the API on a URL, your backend needs to download it first.
    } 
    // 3. If both are empty, show an error
    else {
      _setError('Please upload an image or enter a URL.');
    }
  }

  Future<void> _analyzeImage() async {
    if (_imageBytes == null) return;

    setState(() {
      _isAnalyzing = true;
      _clearError();
    });

    try {
      var uri = Uri.parse('http://127.0.0.1:8000/predict');
      var request = http.MultipartRequest('POST', uri);

      request.files.add(http.MultipartFile.fromBytes(
        'file',
        _imageBytes!,
        filename: 'upload.jpg', 
        contentType: MediaType('image', 'jpeg'), 
      ));

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        var jsonResponse = jsonDecode(response.body);
        
        setState(() {
          _verdict = jsonResponse['prediction'];
          _confidence = jsonResponse['confidence'].toDouble();
          _signals = jsonResponse['signals'];
          _heatmapBase64 = jsonResponse['heatmap'];
        });
      } else {
        _setError("Server error: ${response.statusCode}");
      }
    } catch (e) {
      _setError("Network error: Could not reach the server.");
    } finally {
      setState(() {
        _isAnalyzing = false;
      });
    }
  }

  Future<void> _analyzeNetworkUrl() async {
    if (_uploadedNetworkUrl == null) return;

    setState(() {
      _isAnalyzing = true;
      _clearError();
    });

    try {
      var uri = Uri.parse('http://127.0.0.1:8000/predict-url');

      // Send the URL as a JSON body instead of a Multipart File
      var response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'url': _uploadedNetworkUrl}),
      );

      if (response.statusCode == 200) {
        var jsonResponse = jsonDecode(response.body);

        if (jsonResponse['success'] == true) {
          setState(() {
            _verdict = jsonResponse['prediction'];
            _confidence = jsonResponse['confidence'].toDouble();
            _signals = jsonResponse['signals'] ?? [];
            _heatmapBase64 = jsonResponse['heatmap'];
          });
        } else {
           _setError("Analysis failed: ${jsonResponse['error']}");
        }
      } else {
        _setError("Server error: ${response.statusCode}");
      }
    } catch (e) {
      _setError("Network error: Could not reach the server.");
    } finally {
      setState(() {
        _isAnalyzing = false;
      });
    }
  }

  // ── Click to browse (Web) ──────────────────────────────────────────────────

  void _pickFile() {
    final input = html.FileUploadInputElement()
      ..accept = 'image/jpeg,image/png,image/webp,image/heic'
      ..click();

    input.onChange.listen((event) {
      final file = input.files?.first;
      if (file == null) return;

      if (!_allowedMimes.contains(file.type)) {
        _setError('Unsupported file type.');
        return;
      }
      if (file.size > _maxBytes) {
        _setError('File exceeds 20 MB limit.');
        return;
      }

      final reader = html.FileReader();
      reader.readAsArrayBuffer(file);
      reader.onLoad.listen((_) {
        _clearError();
        setState(() {
          _imageBytes = reader.result as Uint8List;
          _imageMimeType = file.type;
          _uploadedNetworkUrl = null;
        });
      });

       _handleAnalyze();
    });
  }

  // ── Drag & drop (Web) ──────────────────────────────────────────────────────

  void _onDragOver(html.MouseEvent event) {
    event.preventDefault();
    setState(() => _isDragging = true);
  }

  void _onDragLeave(html.MouseEvent event) {
    setState(() => _isDragging = false);
  }

  void _onDrop(html.MouseEvent event) {
    event.preventDefault();
    setState(() => _isDragging = false);

    final file = event.dataTransfer?.files?.first;
    if (file == null) return;

    if (!_allowedMimes.contains(file.type)) {
      _setError('Unsupported file type.');
      return;
    }
    if (file.size > _maxBytes) {
      _setError('File exceeds 20 MB limit.');
      return;
    }

    final reader = html.FileReader();
    reader.readAsArrayBuffer(file);
    reader.onLoad.listen((_) {
      _clearError();
      setState(() {
        _imageBytes = reader.result as Uint8List;
        _imageMimeType = file.type;
        _uploadedNetworkUrl = null;
      });

       _handleAnalyze();
    });
  }

  // ── Paste URL ──────────────────────────────────────────────────────────────

  void _analyzeUrl() {
    final url = _urlController.text.trim();
    if (url.isEmpty) { _setError('Please enter an image URL.'); return; }
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme) { _setError('Invalid URL.'); return; }

    _clearError();
    setState(() {
      _uploadedNetworkUrl = url;
      _imageBytes = null;
    });

    _analyzeNetworkUrl();
  }

  // ── Clear ──────────────────────────────────────────────────────────────────
  void _clearUpload() {
    setState(() {
      _imageBytes = null;
      _imageMimeType = null;
      _uploadedNetworkUrl = null;
      _urlController.clear();
      _errorMessage = null;
    });
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 40, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 5,
            child: Container(
              decoration: BoxDecoration(
                color: kSurface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: _isDragging ? kAccent : kBorder,
                    width: _isDragging ? 2 : 1),
              ),
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  _hasUpload ? _buildPreview() : _buildDropZone(),
                  const SizedBox(height: 16),
                  _buildDivider(),
                  const SizedBox(height: 16),
                  _buildUrlRow(),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 10),
                    _buildErrorBanner(),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            flex: 4,
            child: _isAnalyzing 
                ? const _LoadingPanel() // Show this while waiting
                : _hasResult 
                    ? ResultPanel(
                        verdict: _verdict!, 
                        confidence: _confidence!,
                        signals: _signals,
                        heatmapBase64: _heatmapBase64,
                      ) 
                    : const EmptyResultPanel(),
          ),
        ],
      ),
    );
  }

  // ── Drop zone ──────────────────────────────────────────────────────────────

  Widget _buildDropZone() {
    return GestureDetector(
      onTap: _pickFile,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        // We still use MouseRegion to handle hover effects
        onEnter: (_) => setState(() => _isDragging = true),
        onExit: (_) => setState(() => _isDragging = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 220,
          decoration: BoxDecoration(
            color: _isDragging ? kAccent.withOpacity(0.05) : kSurfaceAlt,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: _isDragging ? kAccent : kBorder, width: 1.5),
          ),
          // REMOVED DragTarget! Just put the column directly inside the container.
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                    color: kAccent.withOpacity(0.1),
                    shape: BoxShape.circle),
                child: const Icon(Icons.cloud_upload_outlined,
                    color: kAccent, size: 28),
              ),
              const SizedBox(height: 16),
              const Text('Drop your image here',
                  style: TextStyle(
                      color: kTextPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              const Text('or click to browse files',
                  style: TextStyle(color: kTextSecondary, fontSize: 13)),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                    color: kBorder,
                    borderRadius: BorderRadius.circular(6)),
                child: const Text('JPG, PNG, WEBP, HEIC — Max 20MB',
                    style:
                        TextStyle(color: kTextSecondary, fontSize: 11)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Preview ────────────────────────────────────────────────────────────────

  Widget _buildPreview() {
    return Stack(
      children: [
        // Blurred background fill (looks great for any aspect ratio)
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            height: 420,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Blurred bg layer
                ImageFiltered(
                  imageFilter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: _imageBytes != null
                      ? Image.memory(_imageBytes!,
                          fit: BoxFit.cover,
                          color: Colors.black.withOpacity(0.4),
                          colorBlendMode: BlendMode.darken)
                      : Image.network(_uploadedNetworkUrl!,
                          fit: BoxFit.cover,
                          color: Colors.black.withOpacity(0.4),
                          colorBlendMode: BlendMode.darken),
                ),
                // Sharp image on top, contained
                Center(
                  child: _imageBytes != null
                      ? Image.memory(_imageBytes!,
                          fit: BoxFit.contain,
                          height: 420)
                      : Image.network(_uploadedNetworkUrl!,
                          fit: BoxFit.contain,
                          height: 420,
                          errorBuilder: (_, __, ___) =>
                              _buildNetworkImageError()),
                ),
              ],
            ),
          ),
        ),

        // Top gradient + close button
        Positioned(
          top: 0, left: 0, right: 0,
          child: ClipRRect(
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(12)),
            child: Container(
              height: 60,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.5),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ),

        // Close button
        Positioned(
          top: 10,
          right: 10,
          child: GestureDetector(
            onTap: _clearUpload,
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: Colors.white.withOpacity(0.2), width: 1)),
              child:
                  const Icon(Icons.close, color: Colors.white, size: 15),
            ),
          ),
        ),

        // Bottom badge — "Image ready"
        Positioned(
          bottom: 10,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.55),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: Colors.white.withOpacity(0.15), width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                        color: Color(0xFF00E5A0),
                        shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 6),
                  const Text('Image ready to analyze',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNetworkImageError() {
    return Container(
      color: kSurfaceAlt,
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.broken_image_outlined, color: kTextSecondary, size: 40),
          SizedBox(height: 8),
          Text('Could not load image',
              style: TextStyle(color: kTextSecondary, fontSize: 13)),
        ],
      ),
    );
  }

  // ── Divider ────────────────────────────────────────────────────────────────

  Widget _buildDivider() => Row(
    children: [
      const Expanded(child: Divider(color: kBorder)),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Text('OR',
            style: TextStyle(
                color: kTextSecondary.withOpacity(0.6), fontSize: 12)),
      ),
      const Expanded(child: Divider(color: kBorder)),
    ],
  );

  // ── URL row ────────────────────────────────────────────────────────────────

  Widget _buildUrlRow() => Row(
    children: [
      Expanded(
        child: Container(
          height: 44,
          decoration: BoxDecoration(
              color: kSurfaceAlt,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: kBorder)),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            children: [
              const Icon(Icons.link, color: kTextSecondary, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _urlController,
                  style:
                      const TextStyle(color: kTextPrimary, fontSize: 13),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Paste image URL...',
                    hintStyle: TextStyle(
                        color: kTextSecondary, fontSize: 13),
                    isDense: true,
                  ),
                  onSubmitted: (_) => _handleAnalyze(),
                ),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(width: 10),
      GestureDetector(
        onTap: _isAnalyzing ? null : _handleAnalyze,
        child: Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [kAccentBlue, kAccent]),
              borderRadius: BorderRadius.circular(8)),
          child: const Center(
            child: Text('Analyze',
                style: TextStyle(
                    color: kBg,
                    fontWeight: FontWeight.w700,
                    fontSize: 14)),
          ),
        ),
      ),
    ],
  );

  // ── Error banner ───────────────────────────────────────────────────────────

  Widget _buildErrorBanner() => Container(
    padding:
        const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.withOpacity(0.3))),
    child: Row(
      children: [
        const Icon(Icons.error_outline,
            color: Colors.redAccent, size: 16),
        const SizedBox(width: 8),
        Expanded(
            child: Text(_errorMessage!,
                style: const TextStyle(
                    color: Colors.redAccent, fontSize: 12))),
        GestureDetector(
          onTap: _clearError,
          child: const Icon(Icons.close,
              color: Colors.redAccent, size: 14),
        ),
      ],
    ),
  );
}

class _LoadingPanel extends StatelessWidget {
  const _LoadingPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 620,
      decoration: BoxDecoration(color: kSurface, borderRadius: BorderRadius.circular(16), border: Border.all(color: kBorder)),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              color: kAccentBlue,
              strokeWidth: 3,
            ),
            const SizedBox(height: 24),
            Text('Running neural forensics scan...', 
              style: TextStyle(color: kTextSecondary.withOpacity(0.8), fontSize: 15, fontWeight: FontWeight.w500)
            ),
            const SizedBox(height: 8),
            Text('Analyzing pixel frequency and metadata', 
              style: TextStyle(color: kTextSecondary.withOpacity(0.5), fontSize: 13)
            ),
          ],
        ),
      ),
    );
  }
}