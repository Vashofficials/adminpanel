import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class KeywordAnalyticsScreen extends StatelessWidget {
  const KeywordAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Main Background Color
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA), 
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Keyword Search Analytics",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1D1F),
              ),
            ),
            const SizedBox(height: 24),
            
            // Top Section: Chart + Overview Cards
            const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left Side: Trending Keywords Chart
                Expanded(
                  flex: 5,
                  child: TrendingKeywordsChartCard(),
                ),
                SizedBox(width: 24),
                // Right Side: Overview Stats
                Expanded(
                  flex: 6,
                  child: OverviewCardsSection(),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Bottom Section: Data Table
            const SearchTableSection(),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// SECTION 1: TRENDING KEYWORDS CHART (DONUT)
// -----------------------------------------------------------------------------

class TrendingKeywordsChartCard extends StatelessWidget {
  const TrendingKeywordsChartCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 400,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Trending Keywords",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    Text("Last 7 Days", style: TextStyle(fontSize: 12, color: Colors.grey[700])),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_drop_down, size: 16, color: Colors.grey),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Stack(
              children: [
                PieChart(
                  PieChartData(
                    sectionsSpace: 0,
                    centerSpaceRadius: 90,
                    sections: [
                      PieChartSectionData(color: const Color(0xFFFF7020), value: 35, title: '', radius: 25), // Saloon
                      PieChartSectionData(color: const Color(0xFFFFA055), value: 25, title: '', radius: 25), // Spa
                      PieChartSectionData(color: const Color(0xFFFFCC90), value: 20, title: '', radius: 25), // Cleaning
                      PieChartSectionData(color: const Color(0xFFFFE0B5), value: 12, title: '', radius: 25), // Hair
                      PieChartSectionData(color: const Color(0xFFFFF0DC), value: 8, title: '', radius: 25),  // Skin
                    ],
                  ),
                ),
                const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text("Total", style: TextStyle(color: Colors.grey, fontSize: 14)),
                      SizedBox(height: 4),
                      Text("2,450", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black)),
                    ],
                  ),
                )
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Legend
          const Wrap(
            spacing: 16,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              _LegendItem(color: Color(0xFFFF7020), label: "Saloon: 850"),
              _LegendItem(color: Color(0xFFFFA055), label: "Spa: 620"),
              _LegendItem(color: Color(0xFFFFCC90), label: "Cleaning: 480"),
              _LegendItem(color: Color(0xFFFFE0B5), label: "Hair: 310"),
              _LegendItem(color: Color(0xFFFFF0DC), label: "Skin: 190"),
            ],
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(radius: 4, backgroundColor: color),
        const SizedBox(width: 8),
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// SECTION 2: OVERVIEW CARDS
// -----------------------------------------------------------------------------

class OverviewCardsSection extends StatelessWidget {
  const OverviewCardsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 400,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Overview: Lucknow Services",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Expanded(child: _buildInfoCard(Icons.trending_up, "Top Trend", "Saloon Services")),
                      const SizedBox(height: 16),
                      Expanded(child: _buildInfoCard(Icons.location_city, "Location", "Lucknow Only")),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    children: [
                      Expanded(child: _buildInfoCard(Icons.search, "Total Searches", "Last 30 Days")),
                      const SizedBox(height: 16),
                      Expanded(child: _buildInfoCard(Icons.category, "5 Categories", "Active Services")),
                    ],
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildInfoCard(IconData icon, String title, String subtitle) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFFFF5EB), // Light orange bg
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: const Color(0xFFFF7020), size: 28),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 4),
          Text(subtitle, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// SECTION 3: DATA TABLE
// -----------------------------------------------------------------------------

class SearchTableSection extends StatelessWidget {
  const SearchTableSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          // Table Header Actions
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: "Search by Keyword",
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6B00), // Orange button
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  elevation: 0,
                ),
                child: const Text("Search"),
              )
            ],
          ),
          const SizedBox(height: 24),
          
          // The Table
          SizedBox(
            width: double.infinity,
            child: DataTable(
              headingRowColor: MaterialStateProperty.all(Colors.transparent),
              horizontalMargin: 0,
              columnSpacing: 20,
              dividerThickness: 0.5,
              columns: [
                DataColumn(label: Text("SL", style: _headerStyle)),
                DataColumn(label: Text("KEYWORD", style: _headerStyle)),
                DataColumn(label: Text("SEARCH VOLUME", style: _headerStyle)),
                DataColumn(label: Text("RELATED SERVICES", style: _headerStyle)),
              ],
              rows: _tableData.map((data) {
                return DataRow(
                  cells: [
                    DataCell(Text(data['sl']!, style: const TextStyle(color: Colors.grey))),
                    DataCell(Text(data['keyword']!, style: const TextStyle(fontWeight: FontWeight.w500))),
                    DataCell(Text(data['volume']!, style: TextStyle(color: Colors.grey[700]))),
                    DataCell(_buildServiceChip(data['service']!)),
                  ],
                );
              }).toList(),
            ),
          ),
          
          const SizedBox(height: 16),
          // Pagination Footer
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Showing 1 to 8 of 56 results", style: TextStyle(color: Colors.grey[600], fontSize: 13)),
              Row(
                children: [
                  _paginationButton("Previous"),
                  const SizedBox(width: 8),
                  _paginationButton("Next"),
                ],
              )
            ],
          )
        ],
      ),
    );
  }

  TextStyle get _headerStyle => TextStyle(
    fontSize: 11, 
    fontWeight: FontWeight.bold, 
    color: Colors.grey[500],
    letterSpacing: 0.5
  );

  Widget _paginationButton(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(text, style: TextStyle(color: Colors.grey[700], fontSize: 12)),
    );
  }

  Widget _buildServiceChip(String label) {
    Color bg;
    Color text;

    // Simple logic to match the image colors loosely
    if (label == 'Saloon') {
      bg = const Color(0xFFFFEBD9); // light orange
      text = const Color(0xFFA64D00);
    } else if (label == 'Cleaning') {
      bg = const Color(0xFFFFEDD5);
      text = const Color(0xFF9A5B13);
    } else if (label == 'Hair') {
      bg = const Color(0xFFFFF4E3);
      text = const Color(0xFF946200);
    } else if (label == 'Spa') {
      bg = const Color(0xFFFFE4D6);
      text = const Color(0xFF8C3E1F);
    } else {
      bg = const Color(0xFFFFECE0);
      text = const Color(0xFF8C3E1F);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(color: text, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }
}

// Dummy Data
final List<Map<String, String>> _tableData = [
  {'sl': '01', 'keyword': 'Bridal Makeup Lucknow', 'volume': '1,204', 'service': 'Saloon'},
  {'sl': '02', 'keyword': 'Home Cleaning Services', 'volume': '985', 'service': 'Cleaning'},
  {'sl': '03', 'keyword': 'Hair Spa near me', 'volume': '850', 'service': 'Hair'},
  {'sl': '04', 'keyword': 'Full Body Massage', 'volume': '720', 'service': 'Spa'},
  {'sl': '05', 'keyword': 'Facial Treatment Lucknow', 'volume': '654', 'service': 'Skin'},
  {'sl': '06', 'keyword': 'Deep Cleaning Sofa', 'volume': '430', 'service': 'Cleaning'},
  {'sl': '07', 'keyword': 'Hair Cut Men', 'volume': '390', 'service': 'Saloon'},
  {'sl': '08', 'keyword': 'Anti-Aging Treatment', 'volume': '210', 'service': 'Skin'},
];