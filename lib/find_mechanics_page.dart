import 'package:flutter/material.dart';
import 'package:pro_v1/models/mechanic_list_item.dart';
import 'package:pro_v1/request_form_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FindMechanicsPage extends StatefulWidget {
  const FindMechanicsPage({super.key});

  @override
  _FindMechanicsPageState createState() => _FindMechanicsPageState();
}

class _FindMechanicsPageState extends State<FindMechanicsPage> {
  final List<MechanicListItem> _mechanics = [];
  final List<MechanicListItem> _selectedMechanics = [];
  bool _selectionMode = false;
  bool _isLoading = true;
  String? _errorMessage;
  String _searchQuery = '';
  String _selectedSpecialization = 'All';
  bool _showAvailableOnly = true;

  final List<String> _specializations = [
    'All',
    'General Mechanic',
    'Engine Specialist',
    'Brake Specialist',
    'Transmission Specialist',
    'Electrical Systems',
    'AC Repair',
    'Tire Specialist',
    'Diagnostics',
  ];

  @override
  void initState() {
    super.initState();
    _loadMechanics();
  }

  Future<void> _loadMechanics() async {
    try {
      print('Loading mechanics from database...');
      
      final mechanicsData = await Supabase.instance.client
          .from('mechanic_profiles')
          .select('*')
          .order('name');

      print('Raw data from database: $mechanicsData');
      
      setState(() {
        _mechanics.clear();
        if (mechanicsData != null && mechanicsData.isNotEmpty) {
          print('Found ${mechanicsData.length} mechanics in database');
          for (var mechanicMap in mechanicsData) {
            print('Processing mechanic: $mechanicMap');
            try {
              final mechanic = MechanicListItem.fromMap(mechanicMap);
              _mechanics.add(mechanic);
              print('Added mechanic: ${mechanic.name}');
            } catch (e) {
              print('Error creating mechanic from map: $e');
              print('Problematic map: $mechanicMap');
            }
          }
        } else {
          print('No mechanics found in database or mechanicsData is null/empty');
        }
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading mechanics: $e');
      setState(() {
        _errorMessage = 'Failed to load mechanics: $e';
        _isLoading = false;
      });
    }
  }

  List<MechanicListItem> get _filteredMechanics {
    return _mechanics.where((mechanic) {
      // Filter by search query
      final matchesSearch = _searchQuery.isEmpty ||
          mechanic.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          mechanic.specialization.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          mechanic.location.toLowerCase().contains(_searchQuery.toLowerCase());

      // Filter by specialization
      final matchesSpecialization = _selectedSpecialization == 'All' ||
          mechanic.specialization == _selectedSpecialization;

      // Filter by availability
      final matchesAvailability = !_showAvailableOnly || mechanic.isAvailable;

      return matchesSearch && matchesSpecialization && matchesAvailability;
    }).toList();
  }

  void _toggleMechanicSelection(MechanicListItem mechanic) {
    setState(() {
      if (_selectedMechanics.contains(mechanic)) {
        _selectedMechanics.remove(mechanic);
      } else {
        _selectedMechanics.add(mechanic);
      }
      
      // Exit selection mode if no mechanics selected
      if (_selectedMechanics.isEmpty) {
        _selectionMode = false;
      }
    });
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.person, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'No Mechanics Available',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Check back later or try a different search',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _loadMechanics,
            child: const Text('Refresh'),
          ),
        ],
      ),
    );
  }

  void _showMechanicDetails(MechanicListItem mechanic) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _buildMechanicDetails(mechanic),
    );
  }

  Widget _buildMechanicDetails(MechanicListItem mechanic) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: CircleAvatar(
              radius: 40,
              backgroundColor: Colors.blue,
              child: Text(
                mechanic.name[0].toUpperCase(),
                style: const TextStyle(fontSize: 32, color: Colors.white),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              mechanic.name,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              mechanic.specialization,
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ),
          const SizedBox(height: 20),
          _buildDetailRow(Icons.location_on, mechanic.location),
          _buildDetailRow(Icons.phone, mechanic.phoneNumber),
          _buildDetailRow(Icons.email, mechanic.email),
          _buildDetailRow(Icons.star, 'Rating: ${mechanic.rating} (${mechanic.totalReviews} reviews)'),
          _buildDetailRow(Icons.work, 'Experience: ${mechanic.yearsOfExperience} years'),
          _buildDetailRow(
            Icons.circle,
            mechanic.isAvailable ? 'Available' : 'Not Available',
            color: mechanic.isAvailable ? Colors.green : Colors.red,
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _contactMechanic(mechanic),
                  icon: const Icon(Icons.phone),
                  label: const Text('Call'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _messageMechanic(mechanic),
                  icon: const Icon(Icons.message),
                  label: const Text('Message'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String text, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: color ?? Colors.blue, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 16, color: color ?? Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  void _contactMechanic(MechanicListItem mechanic) {
    // Implement phone call functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Calling ${mechanic.name} at ${mechanic.phoneNumber}')),
    );
    Navigator.pop(context);
  }

  void _messageMechanic(MechanicListItem mechanic) {
    // Implement messaging functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Messaging ${mechanic.name}')),
    );
    Navigator.pop(context);
  }

  Widget _buildMechanicCard(MechanicListItem mechanic) {
    final isSelected = _selectedMechanics.contains(mechanic);
    
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
      color: isSelected ? Colors.blue[50] : null,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isSelected ? Colors.blue : Colors.blue,
          child: Text(
            mechanic.name[0].toUpperCase(),
            style: const TextStyle(color: Colors.white),
          ),
        ),
        title: Text(
          mechanic.name,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.blue : Colors.black,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(mechanic.specialization),
            Text(mechanic.location),
            Row(
              children: [
                Icon(Icons.star, color: Colors.amber, size: 16),
                Text(' ${mechanic.rating.toStringAsFixed(1)} (${mechanic.totalReviews})'),
                const Spacer(),
                Icon(
                  Icons.circle,
                  color: mechanic.isAvailable ? Colors.green : Colors.red,
                  size: 12,
                ),
                Text(
                  mechanic.isAvailable ? ' Available' : ' Busy',
                  style: TextStyle(
                    color: mechanic.isAvailable ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: _selectionMode
            ? Checkbox(
                value: isSelected,
                onChanged: (value) => _toggleMechanicSelection(mechanic),
              )
            : const Icon(Icons.chevron_right),
        onTap: () {
          if (_selectionMode) {
            _toggleMechanicSelection(mechanic);
          } else {
            _showMechanicDetails(mechanic);
          }
        },
        onLongPress: () {
          setState(() {
            _selectionMode = true;
            _toggleMechanicSelection(mechanic);
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _selectionMode 
            ? Text('Selected: ${_selectedMechanics.length}')
            : const Text('Find Mechanics'),
        actions: [
          if (_selectionMode)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                setState(() {
                  _selectedMechanics.clear();
                  _selectionMode = false;
                });
              },
            ),
        ],
      ),
      floatingActionButton: _selectionMode
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => RequestFormPage(selectedMechanics: _selectedMechanics),
                  ),
                );
              },
              icon: const Icon(Icons.send),
              label: const Text('Send Request'),
            )
          : null,
      body: Column(
        children: [
          // Search and Filter Section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Search mechanics...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedSpecialization,
                        items: _specializations
                            .map((spec) => DropdownMenuItem(
                                  value: spec,
                                  child: Text(spec),
                                ))
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedSpecialization = value!;
                          });
                        },
                        decoration: const InputDecoration(
                          labelText: 'Specialization',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    FilterChip(
                      label: const Text('Available Only'),
                      selected: _showAvailableOnly,
                      onSelected: (selected) {
                        setState(() {
                          _showAvailableOnly = selected;
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Results Section
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? Center(child: Text(_errorMessage!))
                    : _mechanics.isEmpty
                        ? _buildEmptyState()
                        : _filteredMechanics.isEmpty
                            ? _buildEmptyState()
                            : RefreshIndicator(
                                onRefresh: _loadMechanics,
                                child: ListView.builder(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  itemCount: _filteredMechanics.length,
                                  itemBuilder: (context, index) {
                                    return _buildMechanicCard(_filteredMechanics[index]);
                                  },
                                ),
                              ),
          ),
        ],
      ),
    );
  }
}