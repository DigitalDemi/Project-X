import 'package:flutter/material.dart';

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // BODY
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // TOP BAR
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  
               
                ],
              ),
              const SizedBox(height: 24),

              // HORIZONTAL DATE/TIME SCROLLER
              SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _buildDateChip('TIME', isSelected: false),
                    _buildDateChip('Mon16', isSelected: true),
                    _buildDateChip('Mon16', isSelected: false),
                    _buildDateChip('Mon16', isSelected: false),
                    _buildDateChip('Mon16', isSelected: false),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // MEETING CARD
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[850], // Darker card background
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    // Time Column
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text('8:00', style: TextStyle(color: Colors.white70)),
                        SizedBox(height: 8),
                        Text('8:30', style: TextStyle(color: Colors.white70)),
                        SizedBox(height: 8),
                        Text('9:00', style: TextStyle(color: Colors.white70)),
                      ],
                    ),
                    const Spacer(),
                    // Meeting info
                    Text(
                      'YOU HAVE A MEETING',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // GRID OF "CREATING CV" CARDS
              SizedBox(
                height: 180, // Adjust as needed
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _buildInfoCard(title: 'CREATING CV', subtitle: 'HIGH ENERGY'),
                    _buildInfoCard(title: 'CREATING CV', subtitle: 'HIGH ENERGY'),
                    _buildInfoCard(title: 'CREATING CV', subtitle: 'HIGH ENERGY'),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // TASK LIST & NEXT TIME BLOCK
              Row(
                children: [
                  // TASK LIST
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey[850],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'TASK LIST',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 16),
                          Text('TASK 1', style: TextStyle(color: Colors.white70)),
                          Text('TASK 2', style: TextStyle(color: Colors.white70)),
                          Text('TASK 3', style: TextStyle(color: Colors.white70)),
                          Text('TASK 4', style: TextStyle(color: Colors.white70)),
                          Text('TASK 5', style: TextStyle(color: Colors.white70)),
                        ],
                      ),
                    ),
                  ),
                  // NEXT TIME BLOCK
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.only(left: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey[850],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Text(
                          'NEXT TIME BLOCK',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),

      // BOTTOM NAVIGATION
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.black,
        selectedItemColor: Colors.deepPurpleAccent,
        unselectedItemColor: Colors.white70,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.eco),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.brush),
            label: '',
          ),
        ],
      ),
    );
  }

  Widget _buildDateChip(String label, {bool isSelected = false}) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? Colors.deepPurpleAccent : Colors.grey[850],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.white70,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildInfoCard({required String title, required String subtitle}) {
    return Container(
      width: 150,
      margin: const EdgeInsets.only(right: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}