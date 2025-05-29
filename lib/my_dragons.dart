import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MyDragonsPage extends StatelessWidget {
  const MyDragonsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final Color primary = Theme.of(context).colorScheme.primary;
    final Color cardBg = Colors.white;
    final Color cardShadow = Colors.black.withOpacity(0.07);
    final Color lockedBg = const Color(0xFFF4F4F4);
    final double borderRadius = 28.0;
    final double cardPadding = 24.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFB),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.only(top: 8.0, bottom: 18.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'My Dragons',
                        style: GoogleFonts.poppins(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: primary,
                          letterSpacing: 1.2,
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: primary.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: IconButton(
                          icon: Icon(Icons.menu, color: primary, size: 28),
                          onPressed: () {},
                        ),
                      ),
                    ],
                  ),
                ),
                // Dragon Card (Unlocked)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 28),
                  padding: EdgeInsets.all(cardPadding),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(borderRadius),
                    boxShadow: [
                      BoxShadow(
                        color: cardShadow,
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Egg image placeholder with gradient border
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  primary.withOpacity(0.25),
                                  Colors.green.withOpacity(0.18),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: primary.withOpacity(0.3),
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: primary.withOpacity(0.08),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Icon(
                                Icons.egg,
                                size: 48,
                                color: Colors.green[700],
                              ),
                            ),
                          ),
                          const SizedBox(width: 22),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      'Name',
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        color: Colors.black45,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              'Fitzwilliam',
                                              style: GoogleFonts.poppins(
                                                fontSize: 20,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.black87,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          Icon(
                                            Icons.edit,
                                            size: 16,
                                            color: primary,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    Text(
                                      'Species',
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        color: Colors.black45,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Bokaris',
                                        style: GoogleFonts.poppins(
                                          fontSize: 16,
                                          color: Colors.black87,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Divider(color: Colors.grey[200], thickness: 1, height: 1),
                      const SizedBox(height: 18),
                      _DragonInfoRow(label: 'Length', value: '2 feet'),
                      _DragonInfoRow(label: 'Weight', value: '25 pounds'),
                      _DragonInfoRow(
                        label: 'Preferred Environment',
                        value: 'Waterfalls',
                      ),
                      _DragonInfoRow(
                        label: 'Favorite Item',
                        value: 'Ice Cream',
                      ),
                      const SizedBox(height: 22),
                      Center(
                        child: ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primary,
                            foregroundColor: Colors.white,
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 48,
                              vertical: 16,
                            ),
                            textStyle: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          child: const Text('PLAY'),
                        ),
                      ),
                    ],
                  ),
                ),
                // Dragon Card (Locked)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 28),
                  padding: EdgeInsets.all(cardPadding),
                  decoration: BoxDecoration(
                    color: lockedBg,
                    borderRadius: BorderRadius.circular(borderRadius),
                    border: Border.all(color: Colors.grey[300]!, width: 1.2),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Lock image placeholder
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.grey[400]!,
                                width: 2,
                              ),
                            ),
                            child: Center(
                              child: Icon(
                                Icons.lock,
                                size: 48,
                                color: Colors.blueGrey[300],
                              ),
                            ),
                          ),
                          const SizedBox(width: 22),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      'Name',
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        color: Colors.black38,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        '__________________',
                                        style: GoogleFonts.poppins(
                                          fontSize: 16,
                                          color: Colors.black26,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    Text(
                                      'Species',
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        color: Colors.black38,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        '__________________',
                                        style: GoogleFonts.poppins(
                                          fontSize: 16,
                                          color: Colors.black26,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Divider(color: Colors.grey[300], thickness: 1, height: 1),
                      const SizedBox(height: 18),
                      _DragonInfoRow(
                        label: 'Length',
                        value: '______',
                        valueColor: Colors.black26,
                      ),
                      _DragonInfoRow(
                        label: 'Weight',
                        value: '______',
                        valueColor: Colors.black26,
                      ),
                      _DragonInfoRow(
                        label: 'Preferred Environment',
                        value: '______________',
                        valueColor: Colors.black26,
                      ),
                      _DragonInfoRow(
                        label: 'Favorite Item',
                        value: '____________________',
                        valueColor: Colors.black26,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DragonInfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  const _DragonInfoRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible(
            flex: 2,
            child: Text(
              '$label:',
              style: GoogleFonts.poppins(fontSize: 15, color: Colors.black54),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            flex: 3,
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 15,
                color: valueColor ?? Colors.black87,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
