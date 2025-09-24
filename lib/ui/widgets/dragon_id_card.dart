import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:safe_scales/extensions/string_extensions.dart';

import '../../providers/dragon_provider.dart';

class DragonIdCard extends StatefulWidget {
  final String dragonId;
  final Widget dragonImage;
  final String species;
  final String name;
  // final String length; not in use currently
  // final String weight;
  final String favoriteItem;
  final String favoriteEnvironment;

  final bool isPlayUnlocked;

  final VoidCallback? onTapPlayButton;
  final Function(String)? onNameChanged; // Add this callback


  const DragonIdCard({
    super.key,
    required this.dragonId,
    required this.dragonImage,
    required this.species,
    required this.name,
    required this.favoriteItem,
    required this.favoriteEnvironment,
    required this.isPlayUnlocked,
    this.onTapPlayButton,
    this.onNameChanged,
  });

  @override
  State<DragonIdCard> createState() => _DragonIdCardState();

}

class _DragonIdCardState extends State<DragonIdCard> {

  bool _isPlayUnlocked = false;

  @override
  void initState() {
    super.initState();

    _isPlayUnlocked = widget.isPlayUnlocked;
  }


  void _showNameDialog() {

    DragonProvider dragonProvider = Provider.of<DragonProvider>(context, listen: false);

    final TextEditingController nameController = TextEditingController(
      text: dragonProvider.getDragonById(widget.dragonId)?.name ?? '',
    );

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Change Dragon Name'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      // labelText: 'Dragon Name',
                      hintText: 'Enter Your Dragon\'s Name',
                      counterText: '${nameController.text.length}/${dragonProvider.maxNameLength}',
                      errorText:
                      nameController.text.length > dragonProvider.maxNameLength
                          ? 'Name cannot be longer than ${dragonProvider.maxNameLength} characters'
                          : null,
                    ),
                    autofocus: true,
                    maxLength: dragonProvider.maxNameLength,
                    onChanged: (value) {
                      setState(() {}); // Update counter and error text
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed:
                  nameController.text.trim().isEmpty ||
                      nameController.text.length > dragonProvider.maxNameLength
                      ? null // Disable button if name is empty or too long
                      : () async {
                    try {
                      await dragonProvider.updateDragonName(
                        widget.dragonId,
                        nameController.text,
                      );
                      if (mounted) Navigator.pop(context);
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(e.toString())),
                        );
                      }
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void openEditNameDialog() {
    // TODO: Add Backend to saving dragon name

    final TextEditingController controller = TextEditingController(text: widget.name);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Edit Name"),
          content: TextField(
            controller: controller,
            style: Theme.of(context).textTheme.bodyLarge,
            decoration: InputDecoration(
              hintText: 'Enter Dragon\'s name',
              hintStyle: Theme.of(context).textTheme.labelLarge,
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
              },
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                // setState(() {
                //   widget.name = _controller.text;
                // });
                widget.onNameChanged?.call(controller.text);
                Navigator.of(context).pop(); // Close dialog
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {

    ThemeData theme = Theme.of(context);

    return Container(
        margin: EdgeInsets.symmetric(horizontal: 0, vertical: 15),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.surfaceDim.withValues(alpha: 0.9), // Darker royal blue
              theme.colorScheme.surfaceDim, // Royal blue
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.shadow.withValues(alpha: 0.2),
              blurRadius: 15,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              // Header with dragon image and name
              Container(
                padding: EdgeInsets.all(20),
                child: Row(
                  children: [

                    // Dragon image
                    Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                          width: 2,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(13),
                        child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                            child: widget.dragonImage,
                        ),
                      ),
                    ),

                    SizedBox(width: 20),

                    // Name and species
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [

                          Row(
                            children: [
                              Text(
                                'Name'.toTitleCase(),
                                style: theme.textTheme.labelLarge,
                              ),

                              //TODO: Enable when dragon names can be saved
                              IconButton(
                                onPressed: _showNameDialog,
                                icon: Icon(
                                  FontAwesomeIcons.pencil,
                                  size: 15,
                                ),
                              ),
                            ],
                          ),


                          // SizedBox(height: 2),

                          Padding(
                              padding: EdgeInsets.symmetric(horizontal: 12),
                            child: Row(
                              children: [
                                Text(
                                  widget.name,
                                  style: theme.textTheme.headlineSmall?.copyWith(
                                    fontSize: theme.textTheme.bodyMedium?.fontSize,
                                  )
                                ),

                              ],
                            )
                          ),

                          SizedBox(height: 7),

                          Text(
                            'Species'.toTitleCase(),
                            style: theme.textTheme.labelMedium,
                          ),

                          SizedBox(height: 3),

                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              widget.species,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Details section
              Container(
                padding: EdgeInsets.fromLTRB(20, 0, 20, 0),
                child: Column(
                  children: [

                    // Divider
                    Container(
                      height: 1.5,
                      margin: EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            theme.colorScheme.onSurface.withValues(alpha: 0.3),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),

                    // Stats grid

                    //TODO: Maybe delete the weight and length
                    // Row(
                    //   children: [
                    //     Expanded(
                    //       child: _buildStatItem(
                    //         context: context,
                    //         icon: Icons.straighten,
                    //         label: 'Length',
                    //         value: widget.length,
                    //       ),
                    //     ),
                    //     SizedBox(width: 16),
                    //     Expanded(
                    //       child: _buildStatItem(
                    //         context: context,
                    //         icon: Icons.monitor_weight,
                    //         label: 'Weight',
                    //         value: widget.weight,
                    //       ),
                    //     ),
                    //   ],
                    // ),
                    //
                    // SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: _buildStatItem(
                            context: context,
                            icon: Icons.favorite,
                            label: 'Favorite Item',
                            value: widget.favoriteItem,
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: _buildStatItem(
                            context: context,
                            icon: Icons.landscape,
                            label: 'Environment',
                            value: widget.favoriteEnvironment,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),


              // Play Button
              Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                child: ElevatedButton(
                    onPressed: _isPlayUnlocked ? widget.onTapPlayButton : null,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(FontAwesomeIcons.gamepad),

                        SizedBox(width: 20,),

                        Text(
                            'Play with Dragon'.toUpperCase()
                        ),
                      ],
                    )
                ),
              ),
            ],
          ),
        ),
      );
  }

  Widget _buildStatItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String value,
  }) {

    ThemeData theme = Theme.of(context);


    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.1), //Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: theme.colorScheme.primary,
                size: 15,
              ),
              SizedBox(width: 10),
              Text(
                label,
                style: theme.textTheme.labelSmall,
              ),
            ],
          ),
          SizedBox(height: 6),
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}