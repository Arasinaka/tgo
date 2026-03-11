import 'package:flutter/material.dart';
import 'package:tgo_widget/tgo_widget.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize TGO Widget
  // Replace 'your-api-key' with your actual platform API key
  await TgoWidget.init(
    apiKey: 'ak_live_oVeNfkwvBVwafV2XdRLcQTjGwU8UBrTo',
    apiBase: 'http://localhost/api',
    config: const TgoWidgetConfig(
      title: 'Customer Service',
      themeColor: Color(0xFF2F80ED),
      position: WidgetPosition.bottomRight,
      welcomeMessage: 'Hello! How can I help you today?',
    ),
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TGO Widget Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2F80ED)),
        useMaterial3: true,
      ),
      darkTheme: ThemeData.dark(useMaterial3: true).copyWith(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2F80ED),
          brightness: Brightness.dark,
        ),
      ),
      themeMode: ThemeMode.system,
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    // Listen to unread count
    TgoWidget.unreadCountStream.listen((count) {
      if (mounted) {
        setState(() => _unreadCount = count);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TGO Widget Example'),
        actions: [
          // Unread badge in app bar
          if (_unreadCount > 0)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$_unreadCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Stack(
        children: [
          // Main content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.chat_bubble_outline,
                  size: 64,
                  color: Colors.grey,
                ),
                const SizedBox(height: 16),
                const Text(
                  'TGO Widget Demo',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tap the floating button to open chat',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 32),

                // Button to open chat directly
                ElevatedButton.icon(
                  onPressed: () => TgoWidget.show(context),
                  icon: const Icon(Icons.chat),
                  label: const Text('Open Chat (Bottom Sheet)'),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => TgoWidget.showFullScreen(context),
                  icon: const Icon(Icons.fullscreen),
                  label: const Text('Open Chat (Full Screen)'),
                ),
                const SizedBox(height: 32),

                // Visitor Management Example
                const Divider(height: 40),
                const Text(
                  'Visitor Management',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        TgoWidget.setVisitor(const VisitorInfo(
                          platformOpenId: 'user_123456',
                          name: 'Demo User',
                          avatarUrl: 'https://i.pravatar.cc/150?u=user_123456',
                        ));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Visitor set to: Demo User (user_123456)')),
                        );
                      },
                      child: const Text('Login: User A'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        TgoWidget.setVisitor(const VisitorInfo(
                          platformOpenId: 'user_789012',
                          name: 'Another User',
                          avatarUrl: 'https://i.pravatar.cc/150?u=user_789012',
                        ));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Visitor set to: Another User (user_789012)')),
                        );
                      },
                      child: const Text('Login: User B'),
                    ),
                    OutlinedButton(
                      onPressed: () {
                        TgoWidget.clearVisitor();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Visitor cleared (Anonymous mode)')),
                        );
                      },
                      child: const Text('Logout (Clear)'),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Connection status
                StreamBuilder<ConnectionStatus>(
                  stream: TgoWidget.connectionStatusStream,
                  initialData: TgoWidget.connectionStatus,
                  builder: (context, snapshot) {
                    final status = snapshot.data ?? ConnectionStatus.disconnected;
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _statusColor(status),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _statusText(status),
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),

          // Floating launcher button
          const TgoWidgetLauncher(),
        ],
      ),
    );
  }

  Color _statusColor(ConnectionStatus status) {
    switch (status) {
      case ConnectionStatus.connected:
        return Colors.green;
      case ConnectionStatus.connecting:
        return Colors.orange;
      case ConnectionStatus.error:
        return Colors.red;
      case ConnectionStatus.disconnected:
        return Colors.grey;
    }
  }

  String _statusText(ConnectionStatus status) {
    switch (status) {
      case ConnectionStatus.connected:
        return 'Connected';
      case ConnectionStatus.connecting:
        return 'Connecting...';
      case ConnectionStatus.error:
        return 'Connection Error';
      case ConnectionStatus.disconnected:
        return 'Disconnected';
    }
  }
}

