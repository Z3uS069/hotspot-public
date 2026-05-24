import React from 'react';
import { useNavigation } from '@/hooks';
import { AppScreen, AppRole } from '@/types/app';
import { useAppStore } from '@/store';
import { getThemeColors } from '@/utils/theme';
import { useDarkMode } from '@/hooks';
import './RoleSelectionPage.css';

// ─────────────────────────────────────────────────────────────────────────────
// ROLE SELECTION PAGE
// (Replaces lib/pages/role_selection_page.dart)
// ─────────────────────────────────────────────────────────────────────────────

const RoleSelectionPage: React.FC = () => {
  const { isDarkMode } = useDarkMode();
  const colors = getThemeColors(isDarkMode);
  const { setScreen, setRole } = useNavigation();

  const handleSelectRole = (role: AppRole) => {
    setRole(role);
    if (role === AppRole.User) {
      // Skip to user app directly (in real app, would go through signup/login)
      setScreen(AppScreen.UserApp);
    } else {
      // Admin goes to space setup
      setScreen(AppScreen.SpaceSetup);
    }
  };

  return (
    <div
      className="role-selection-page"
      style={{ backgroundColor: colors.bg, color: colors.textPrimary }}
    >
      <div className="role-selection-page__container">
        <div className="role-selection-page__content">
          <h1 className="role-selection-page__title">Welcome to Hotspot</h1>
          <p className="role-selection-page__subtitle" style={{ color: colors.textSecondary }}>
            Choose your role to get started
          </p>

          <div className="role-selection-page__cards">
            {/* User Role Card */}
            <button
              onClick={() => handleSelectRole(AppRole.User)}
              className="role-selection-page__card role-selection-page__card--user"
              style={{
                borderColor: colors.borderColor,
                backgroundColor: colors.cardBg,
              }}
              onMouseEnter={(e) => {
                e.currentTarget.style.borderColor = '#00C9A7';
                e.currentTarget.style.transform = 'translateY(-8px)';
              }}
              onMouseLeave={(e) => {
                e.currentTarget.style.borderColor = colors.borderColor;
                e.currentTarget.style.transform = 'translateY(0)';
              }}
            >
              <div className="role-selection-page__icon">👤</div>
              <h2 style={{ color: colors.textPrimary }}>I'm a User</h2>
              <p style={{ color: colors.textSecondary }}>
                Book spaces and collaborate with others
              </p>
            </button>

            {/* Admin Role Card */}
            <button
              onClick={() => handleSelectRole(AppRole.Admin)}
              className="role-selection-page__card role-selection-page__card--admin"
              style={{
                borderColor: colors.borderColor,
                backgroundColor: colors.cardBg,
              }}
              onMouseEnter={(e) => {
                e.currentTarget.style.borderColor = '#8B5CF6';
                e.currentTarget.style.transform = 'translateY(-8px)';
              }}
              onMouseLeave={(e) => {
                e.currentTarget.style.borderColor = colors.borderColor;
                e.currentTarget.style.transform = 'translateY(0)';
              }}
            >
              <div className="role-selection-page__icon">🏢</div>
              <h2 style={{ color: colors.textPrimary }}>I'm an Admin</h2>
              <p style={{ color: colors.textSecondary }}>
                Manage spaces and bookings
              </p>
            </button>
          </div>
        </div>
      </div>
    </div>
  );
};

export default RoleSelectionPage;
