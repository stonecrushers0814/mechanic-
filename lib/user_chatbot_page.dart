import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'services/mumbai_emergency_data.dart';

class UserChatbotPage extends StatefulWidget {
  const UserChatbotPage({super.key});

  @override
  State<UserChatbotPage> createState() => _UserChatbotPageState();
}

class _UserChatbotPageState extends State<UserChatbotPage> {
  final List<_ChatMessage> _messages = <_ChatMessage>[];
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _addBotIntro();
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _addBotIntro() {
    _messages.add(
      _ChatMessage(
        text:
            'Hi! I\'m your assistant. Tell me the issue (e.g."battery dead", "overheating", "flat tire","oil leak","brake squeal","smell/smoke","check engine","ac not cooling","lights not working","steering pull/vibration","clicking, no start (starter)","fuel/engine performance","radiator coolant leak","clutch slipping (manual)","wiper/washer issues", "headlight/tail light/indicator/blinker"). I\'ll suggest quick checks you can try before requesting a mechanic.',
        isUser: false,
      ),
    );
  }

  Future<void> _handleSend() async {
    final String query = _textController.text.trim();
    if (query.isEmpty || _isSending) return;
    setState(() {
      _isSending = true;
      _messages.add(_ChatMessage(text: query, isUser: true));
      _textController.clear();
    });

    // Local simple responses and emergency detection
    final String reply = _generateLocalAdvice(query);
    setState(() {
      _messages.add(_ChatMessage(text: reply, isUser: false));
      _isSending = false;
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 80,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _askEmergencyNumbers() async {
    final String? locality = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        final TextEditingController controller = TextEditingController();
        return AlertDialog(
          title: const Text('Emergency numbers (Mumbai)'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Enter Mumbai locality (e.g., Andheri West)',
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              child: const Text('Get'),
            ),
          ],
        );
      },
    );

    if (locality == null || locality.isEmpty) return;

    setState(() {
      _messages.add(_ChatMessage(
        text: 'Emergency numbers for: $locality',
        isUser: true,
      ));
      _isSending = true;
    });

    final String? local = MumbaiEmergencyDirectory.findNumbersForLocality(locality);
    final String reply = local ?? MumbaiEmergencyDirectory.localityToNumbers['mumbai']!.join('\n');
    setState(() {
      _messages.add(_ChatMessage(text: reply, isUser: false));
      _isSending = false;
    });
    _scrollToBottom();
  }

  String _generateLocalAdvice(String input) {
    final String text = input.toLowerCase();

    // If user asks for emergency numbers inline
    if (text.contains('emergency') && text.contains('mumbai')) {
      final String? local = MumbaiEmergencyDirectory.findNumbersForLocality(text);
      if (local != null) return local;
      return MumbaiEmergencyDirectory.localityToNumbers['mumbai']!.join('\n');
    }

    if (text.contains('flat') || text.contains('puncture') || text.contains('tire')) {
      return 'Flat tire quick checks:\n• Pull over safely and turn on hazards.\n• Inspect tire for objects.\n• If you have a spare, use the jack on reinforced points.\n• Tighten lug nuts in a star pattern.\n• If no spare, avoid driving on the rim; request help.';
    }

    if (text.contains('battery') || text.contains("won't start") || text.contains('no crank') || text.contains('jump')) {
      return 'Won\'t start / battery tips:\n• Check interior lights: dim lights suggest weak battery.\n• Ensure gear in P/N, brake pressed.\n• Jump-start with correct polarity (+ to +, - to chassis).\n• Let it idle 15–20 min after start.\n• If repeated failure, battery/alternator needs service.';
    }

    if (text.contains('overheat') || text.contains('temperature') || text.contains('coolant')) {
      return 'Overheating steps:\n• Turn heater to max to draw heat.\n• Pull over safely and shut engine.\n• Wait until cool before opening coolant cap.\n• Top up with 50/50 mix if available.\n• If leaking or recurs, seek service.';
    }

    if (text.contains('oil') || text.contains('leak')) {
      return 'Oil leak / low oil:\n• Do not drive if oil light is on.\n• Check dipstick and add correct grade if low.\n• Look under car for fresh spots.\n• Persistent leak needs inspection.';
    }

    if (text.contains('brake') || text.contains('squeal') || text.contains('soft pedal')) {
      return 'Brake concerns:\n• If pedal is soft, do not drive.\n• Check for fluid around wheels/master cylinder.\n• Squeal: worn pads; grinding: metal-on-metal.\n• Seek immediate service.';
    }

    if (text.contains('smell') || text.contains('smoke')) {
      return 'Unusual smell/smoke:\n• Burning smell: stop and inspect.\n• Electrical smell: turn off accessories.\n• White smoke: coolant; blue: oil; black: rich fuel.\n• Avoid driving until assessed.';
    }

    // Additional remedial modules
    if (text.contains('check engine') || text.contains('cel') || text.contains('engine light')) {
      return 'Check Engine Light:\n• Ensure fuel cap is tight; drive a short distance to see if it clears.\n• Note any new noises/smells/performance loss.\n• Avoid hard driving; schedule a scan (OBD-II).\n• If flashing light or rough running, stop and seek service.';
    }

    if (text.contains('ac') || text.contains('a/c') || text.contains('air conditioning') || text.contains('not cooling')) {
      return 'AC not cooling:\n• Set to recirculate and lowest temp; check fan speeds.\n• Inspect cabin filter; replace if clogged.\n• Look for icing or weak airflow indicating low refrigerant.\n• Avoid DIY refrigerant top-up; leaks need professional service.';
    }

    if (text.contains('headlight') || text.contains('tail light') || text.contains('indicator') || text.contains('blinker')) {
      return 'Lights not working:\n• Check bulb and fuse for the affected circuit.\n• Inspect for moisture inside lens and loose connectors.\n• Try swapping left/right bulbs to confirm fault.\n• Replace faulty bulb/fuse; persistent issue may be a relay/wiring fault.';
    }

    if (text.contains('alignment') || text.contains('pulling') || text.contains('steering') || text.contains('vibration')) {
      return 'Steering pull/vibration:\n• Verify tire pressures match door sticker.\n• Inspect tires for uneven wear or bulges.\n• Vibration at speed: consider wheel balancing.\n• Persistent pull: alignment/suspension check required.';
    }

    if (text.contains('starter') || text.contains('clicking') || text.contains('solenoid')) {
      return 'Clicking, no start (starter):\n• Battery must be healthy; try jump-start first.\n• Check battery terminals for corrosion/tightness.\n• Single click often starter/solenoid; repeated clicks often weak battery.\n• If jump works repeatedly, test battery/alternator; else inspect starter.';
    }

    if (text.contains('fuel') || text.contains('misfire') || text.contains('rough idle')) {
      return 'Fuel/engine performance:\n• Use known good fuel; avoid running tank very low.\n• Rough idle: check for vacuum leaks and old spark plugs.\n• Intermittent misfire: coil/plug/injector; scan codes to isolate.\n• Severe misfire: avoid driving to prevent catalytic damage.';
    }

    if (text.contains('radiator') || text.contains('coolant leak') || text.contains('hose')) {
      return 'Coolant leak suspected:\n• Look for green/orange/pink residue near radiator/hoses/pump.\n• Do not open cap when hot.\n• Top up only when cool; monitor level.\n• Leaks need pressure test and hose/clamp/radiator repair.';
    }

    if (text.contains('clutch') || text.contains('slip') || text.contains('manual')) {
      return 'Clutch slipping (manual):\n• Test in higher gear at low speed: if revs rise without speed, clutch slipping.\n• Avoid hard acceleration to reduce wear.\n• Check for hydraulic fluid loss (clutch master/slave).\n• Likely needs inspection/replacement soon.';
    }

    if (text.contains('wiper') || text.contains('washer') || text.contains('windshield')) {
      return 'Wipers/washer issues:\n• Refill washer fluid and clear blocked nozzles.\n• Replace worn blades if streaking/chatter.\n• No movement: check fuse/motor linkage.\n• Poor visibility is unsafe—fix before driving in rain.';
    }

    return 'Tell me the issue (e.g., "battery dead", "overheating", "flat tire","oil leak","brake squeal","smell/smoke","check engine","ac not cooling","lights not working","steering pull/vibration","clicking, no start (starter)","fuel/engine performance","radiator coolant leak","clutch slipping (manual)","wiper/washer issues", "headlight/tail light/indicator/blinker").\nTap the emergency icon for Mumbai emergency numbers.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quick Help Assistant'),
        actions: [
          IconButton(
            tooltip: 'Emergency numbers (Mumbai)',
            onPressed: _isSending ? null : _askEmergencyNumbers,
            icon: const Icon(Icons.emergency_share_outlined),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.backgroundGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: _messages.length,
                  itemBuilder: (BuildContext context, int index) {
                    final _ChatMessage message = _messages[index];
                    return _ChatBubble(message: message);
                  },
                ),
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _textController,
                        minLines: 1,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          hintText: 'Describe the issue... (e.g., battery dead) ',
                        ),
                        onSubmitted: (_) => _handleSend(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      height: 48,
                      width: 48,
                      child: ElevatedButton(
                        onPressed: _isSending ? null : _handleSend,
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isSending
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Icon(Icons.send, size: 18),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChatMessage {
  final String text;
  final bool isUser;

  _ChatMessage({required this.text, required this.isUser});
}

class _ChatBubble extends StatelessWidget {
  final _ChatMessage message;

  const _ChatBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final bool isUser = message.isUser;
    final Alignment alignment = isUser ? Alignment.centerRight : Alignment.centerLeft;
    final Color bgColor = isUser
        ? AppTheme.primaryColor
        : Colors.white;
    final Color textColor = isUser ? Colors.white : AppTheme.textPrimary;
    final BorderRadius borderRadius = BorderRadius.only(
      topLeft: const Radius.circular(16),
      topRight: const Radius.circular(16),
      bottomLeft: Radius.circular(isUser ? 16 : 4),
      bottomRight: Radius.circular(isUser ? 4 : 16),
    );

    return Align(
      alignment: alignment,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: borderRadius,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Text(
          message.text,
          style: TextStyle(
            color: textColor,
            fontSize: 14,
            height: 1.4,
          ),
        ),
      ),
    );
  }
}


