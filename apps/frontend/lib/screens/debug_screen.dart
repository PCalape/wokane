import 'package:flutter/material.dart';
import '../services/api_service.dart';

class DebugScreen extends StatefulWidget {
  const DebugScreen({Key? key}) : super(key: key);

  @override
  _DebugScreenState createState() => _DebugScreenState();
}

class _DebugScreenState extends State<DebugScreen> {
  Map<String, dynamic> _envConfig = {};
  Map<String, dynamic> _connectionTest = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkEnvConfig();
  }

  Future<void> _checkEnvConfig() async {
    setState(() {
      _envConfig = ApiService.debugEnvConfig();
    });
  }

  Future<void> _testConnection() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final result = await ApiService.testConnection();
      setState(() {
        _connectionTest = result;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _connectionTest = {'error': e.toString()};
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug Info'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Environment Configuration',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildEnvInfo(),
            const Divider(height: 32),
            const Text(
              'API Connection Test',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _isLoading ? null : _testConnection,
              child: _isLoading
                  ? const CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    )
                  : const Text('Test API Connection'),
            ),
            const SizedBox(height: 12),
            _buildConnectionInfo(),
          ],
        ),
      ),
    );
  }

  Widget _buildEnvInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('dotenv loaded', '${_envConfig['dotenvLoaded']}'),
            _buildInfoRow('Variables count', '${_envConfig['envVarCount']}'),
            _buildInfoRow('Keys', '${_envConfig['envVarKeys']}'),
            _buildInfoRow('BACKEND_URL', '${_envConfig['backendUrl']}'),
            _buildInfoRow('Resolved URL', '${_envConfig['resolvedBaseUrl']}'),
            _buildInfoRow('Platform', '${_envConfig['platform']}'),
            _buildInfoRow('Running on web', '${_envConfig['runningOnWeb']}'),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectionInfo() {
    if (_connectionTest.isEmpty) {
      return const Text('Not tested yet');
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('Connection URL', '${_connectionTest['baseUrl']}'),
            _buildInfoRow('Connected', '${_connectionTest['isConnected']}'),
            _buildInfoRow('Status code', '${_connectionTest['statusCode']}'),
            if (_connectionTest.containsKey('response'))
              _buildInfoRow('Response', '${_connectionTest['response']}'),
            if (_connectionTest.containsKey('error'))
              _buildInfoRow('Error', '${_connectionTest['error']}'),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}
