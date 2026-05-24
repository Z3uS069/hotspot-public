import React, { useState } from 'react';
import { useDarkMode, useNavigation } from '@/hooks';
import { AppTab } from '@/types/app';
import { getThemeColors } from '@/utils/theme';
import HomePage from './HomePage';
import SpacesPage from './SpacesPage';
import ActivityPage from './ActivityPage';
import SavedPage from './SavedPage';
import ProfilePage from './ProfilePage';
import './UserAppShell.css';

// ─────────────────────────────────────────────────────────────────────────────
// USER APP SHELL
// (Replaces lib/pages/user_app_shell.dart)
// Handles navigation between different tabs: Map, Spaces, Activity, Saved
// ─────────────────────────────────────────────────────────────────────────────

const UserAppShell: React.FC = () => {
  const { isDarkMode, toggleTheme } = useDarkMode();
  const colors = getThemeColors(isDarkMode);
  const { activeTab, setActiveTab } = useNavigation();
  const [isProfileOpen, setIsProfileOpen] = useState(false);

  const renderContent = () => {
    if (isProfileOpen) {
      return <ProfilePage />;
    }

    switch (activeTab) {
      case AppTab.Map:
        return <HomePage />;
      case AppTab.Space:
        return <SpacesPage />;
      case AppTab.Activity:
        return <ActivityPage />;
      case AppTab.Saved:
        return <SavedPage />;
      default:
        return null;
    }
  };

  const tabs = [
    { label: 'Map', value: AppTab.Map, icon: '🗺️' },
    { label: 'Spaces', value: AppTab.Space, icon: '🏢' },
    { label: 'Activity', value: AppTab.Activity, icon: '📋' },
    { label: 'Saved', value: AppTab.Saved, icon: '❤️' },
  ];

  return (
    <div className="user-app-shell">
      {/* Header */}
      <header
        className="user-app-shell__header"
        style={{
          backgroundColor: colors.cardBg,
          borderBottomColor: colors.borderColor,
        }}
      >
        {isProfileOpen && (
          <button
            className="user-app-shell__back-btn"
            onClick={() => setIsProfileOpen(false)}
            style={{
              background: 'transparent',
              border: 'none',
              color: colors.textPrimary,
              cursor: 'pointer',
              fontSize: '1.5rem',
              padding: 0,
            }}
            title="Back"
          >
            ←
          </button>
        )}
        <h1 style={{ color: colors.textPrimary, flex: 1 }}>
          {isProfileOpen ? 'Profile' : 'Hotspot'}
        </h1>
        <div className="user-app-shell__header-actions">
          {!isProfileOpen && (
            <button
              className="user-app-shell__profile-btn"
              onClick={() => setIsProfileOpen(true)}
              style={{
                background: 'transparent',
                border: `1px solid ${colors.borderColor}`,
                borderRadius: '0.5rem',
                color: colors.textPrimary,
                cursor: 'pointer',
                padding: '0.5rem 1rem',
                fontWeight: 600,
                transition: 'all 0.3s ease',
              }}
              onMouseEnter={(e) => {
                e.currentTarget.style.backgroundColor = colors.borderColor;
              }}
              onMouseLeave={(e) => {
                e.currentTarget.style.backgroundColor = 'transparent';
              }}
              title="Profile"
            >
              👤
            </button>
          )}
          <button
            className="user-app-shell__theme-btn"
            onClick={toggleTheme}
            style={{
              padding: '0.5rem 1rem',
              borderRadius: '0.5rem',
              border: `1px solid ${colors.borderColor}`,
              backgroundColor: colors.bg,
              color: colors.textPrimary,
              cursor: 'pointer',
              fontWeight: 600,
              transition: 'all 0.3s ease',
            }}
            onMouseEnter={(e) => {
              e.currentTarget.style.backgroundColor = colors.borderColor;
            }}
            onMouseLeave={(e) => {
              e.currentTarget.style.backgroundColor = colors.bg;
            }}
          >
            {isDarkMode ? '☀️' : '🌙'}
          </button>
        </div>
      </header>

      {/* Main Content */}
      <main className="user-app-shell__content">{renderContent()}</main>

      {/* Bottom Navigation */}
      {!isProfileOpen && (
        <nav
          className="user-app-shell__nav"
          style={{
            backgroundColor: colors.cardBg,
            borderTopColor: colors.borderColor,
          }}
        >
          {tabs.map((tab) => (
            <button
              key={tab.value}
              className={`user-app-shell__nav-item ${activeTab === tab.value ? 'active' : ''}`}
              onClick={() => setActiveTab(tab.value)}
              style={{
                color: activeTab === tab.value ? '#00C9A7' : colors.textSecondary,
                borderBottomColor: activeTab === tab.value ? '#00C9A7' : 'transparent',
              }}
              title={tab.label}
            >
              <div className="user-app-shell__nav-icon">{tab.icon}</div>
              <div className="user-app-shell__nav-label">{tab.label}</div>
            </button>
          ))}
        </nav>
      )}
    </div>
  );
};

export default UserAppShell;
