// ─────────────────────────────────────────────────────────────────────────────
// COLOR PALETTE (from lib/theme.dart)
// ─────────────────────────────────────────────────────────────────────────────

export const AppColors = {
  // Dark mode colours
  appBgDark: '#0B1426',
  appCardDark: '#152238',
  appBorderDark: '#1E3354',

  // Light mode colours
  appBgLight: '#EFF2F7',
  appCardLight: '#FFFFFF',
  appBorderLight: '#CCD3DE',

  // Shared accent colours
  appAccent: '#00C9A7',
  appAccent2: '#4DD0E1',

  // Admin theme
  adminBg: '#0F0C29',
  adminCard: '#1A1638',
  adminBorder: '#2D2442',
  adminBgLight: '#F8FAFC',
  adminCardLight: '#FFFFFF',
  adminBorderLight: '#E2E8F0',
  adminAccent: '#8B5CF6',
  adminAccent2: '#6366F1',

  // Shared
  white: '#FFFFFF',
  grey400: '#9CA3AF',
  grey500: '#6B7280',
  red400: '#F87171',
  orange400: '#FB923C',
  orange500: '#F97316',

  // Light mode text colours
  lightTextPrimary: '#0F172A',
  lightTextSecondary: '#475569',
  lightTextMuted: '#64748B',
} as const;

// ─────────────────────────────────────────────────────────────────────────────
// THEME HELPER FUNCTIONS
// ─────────────────────────────────────────────────────────────────────────────

export const getThemeColors = (isDarkMode: boolean) => ({
  bg: isDarkMode ? AppColors.appBgDark : AppColors.appBgLight,
  cardBg: isDarkMode ? AppColors.appCardDark : AppColors.appCardLight,
  borderColor: isDarkMode ? AppColors.appBorderDark : AppColors.appBorderLight,
  textPrimary: isDarkMode ? AppColors.white : AppColors.lightTextPrimary,
  textSecondary: isDarkMode ? AppColors.grey400 : AppColors.lightTextSecondary,
  textMuted: isDarkMode ? AppColors.grey500 : AppColors.lightTextMuted,
  surfaceVariant: isDarkMode
    ? 'rgba(255, 255, 255, 0.05)'
    : 'rgba(0, 0, 0, 0.06)',
  dividerColor: isDarkMode
    ? 'rgba(255, 255, 255, 0.10)'
    : 'rgba(0, 0, 0, 0.12)',
});

export const getAdminThemeColors = (isDarkMode: boolean) => ({
  bg: isDarkMode ? AppColors.adminBg : AppColors.adminBgLight,
  card: isDarkMode ? AppColors.adminCard : AppColors.adminCardLight,
  border: isDarkMode ? AppColors.adminBorder : AppColors.adminBorderLight,
  accent: isDarkMode ? AppColors.adminAccent : '#7C3AED',
  accent2: isDarkMode ? AppColors.adminAccent2 : AppColors.adminAccent2,
  textPrimary: isDarkMode ? AppColors.white : '#1E293B',
  textSecondary: isDarkMode ? AppColors.grey400 : '#475569',
  textMuted: isDarkMode ? AppColors.grey500 : '#64748B',
});
