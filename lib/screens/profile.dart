import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:food_recipes_app/helper/theme_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      backgroundColor: themeProvider.isDark ? Colors.black : Colors.white,
      appBar: AppBar(
        backgroundColor: themeProvider.isDark ? Colors.grey[900] : Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            Image.asset(
              'assets/images/cook-book.png',
              height: 30,
            ),
            const SizedBox(width: 8),
            Text(
              "FLAVOR FIESTA",
              style: TextStyle(
                color: themeProvider.isDark ? Colors.white : Colors.black87,
                fontWeight: FontWeight.bold,
                fontSize: 20,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),

            // Profile Picture Section
            Center(
              child: SizedBox(
                width: 120,
                height: 120,
                child: Stack(
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.grey[200],
                        image: const DecorationImage(
                          image: AssetImage('assets/images/dr.youssry.png'),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.grey[800],
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          size: 18,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Name
            Text(
              'Yousry Abdul Azeem',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: themeProvider.isDark ? Colors.white : Colors.black87,
              ),
            ),

            const SizedBox(height: 8),

            // Email
            Text(
              'dr.yousry@email.com',
              style: TextStyle(
                fontSize: 16,
                color: themeProvider.isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),

            const SizedBox(height: 32),

            // Stats Cards
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildStatCard('24', 'Recipes', themeProvider),
                  _buildStatCard('12', 'Favorites', themeProvider),
                  _buildStatCard('8', 'Created', themeProvider),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // Preferences Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Preferences',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: themeProvider.isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),

                  _buildPreferenceRow(
                    icon: Icons.favorite_outline,
                    title: 'Dietary Restrictions',
                    onTap: () {},
                    themeProvider: themeProvider,
                  ),
                  const SizedBox(height: 12),

                  _buildPreferenceRow(
                    icon: Icons.notifications_outlined,
                    title: 'Notifications',
                    onTap: () {},
                    themeProvider: themeProvider,
                  ),
                  const SizedBox(height: 12),

                  // 🌙 Dark Mode Toggle
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                    decoration: BoxDecoration(
                      color: themeProvider.isDark ? Colors.grey[850] : Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.dark_mode, color: themeProvider.isDark ? Colors.white : Colors.black87),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            "Dark Mode",
                            style: TextStyle(
                              fontSize: 16,
                              color: themeProvider.isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                        ),
                        Switch(
                          value: themeProvider.isDark,
                          onChanged: (value) {
                            themeProvider.toggleTheme(value);
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Settings Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Settings',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: themeProvider.isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildPreferenceRow(
                    icon: Icons.settings_outlined,
                    title: 'Account Settings',
                    onTap: () {},
                    themeProvider: themeProvider,
                  ),
                  const SizedBox(height: 12),
                  _buildPreferenceRow(
                    icon: Icons.lock_outline,
                    title: 'Privacy & Security',
                    onTap: () {},
                    themeProvider: themeProvider,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String number, String label, ThemeProvider themeProvider) {
    return Container(
      width: 100,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: themeProvider.isDark ? Colors.grey[900] : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            number,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: themeProvider.isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: themeProvider.isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreferenceRow({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    required ThemeProvider themeProvider,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        decoration: BoxDecoration(
          color: themeProvider.isDark ? Colors.grey[850] : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 24,
              color: themeProvider.isDark ? Colors.white : Colors.black87,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  color: themeProvider.isDark ? Colors.white : Colors.black87,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: themeProvider.isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ],
        ),
      ),
    );
  }
}
