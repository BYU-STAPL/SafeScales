import 'package:flutter/material.dart';
import 'package:safe_scales/config/supabase_config.dart';

class HealthCheck extends StatefulWidget {
  const HealthCheck({super.key});

  @override
  State<HealthCheck> createState() => _HealthCheckState();
}

class _HealthCheckState extends State<HealthCheck> {
  bool _isChecking = true;
  bool _isHealthy = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _checkHealth();
  }

  Future<void> _checkHealth() async {
    setState(() {
      _isChecking = true;
      _isHealthy = false;
      _errorMessage = '';
    });

    try {
      // Try to make a simple query to check Supabase connection
      await SupabaseConfig.client.from('Users').select('count').limit(1);

      setState(() {
        _isChecking = false;
        _isHealthy = true;
      });
    } catch (e) {
      setState(() {
        _isChecking = false;
        _isHealthy = false;
        _errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'System Health Check',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (_isChecking)
              const CircularProgressIndicator()
            else if (_isHealthy)
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 24),
                  SizedBox(width: 8),
                  Text(
                    'Supabase Connection: Healthy',
                    style: TextStyle(color: Colors.green),
                  ),
                ],
              )
            else
              Column(
                children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error, color: Colors.red, size: 24),
                      SizedBox(width: 8),
                      Text(
                        'Supabase Connection: Unhealthy',
                        style: TextStyle(color: Colors.red),
                      ),
                    ],
                  ),
                  if (_errorMessage.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Error: $_errorMessage',
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _checkHealth,
              child: const Text('Check Again'),
            ),
          ],
        ),
      ),
    );
  }
}
