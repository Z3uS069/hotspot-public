import React, { useState } from 'react';
import { useDarkMode } from '@/hooks';
import { useAppStore } from '@/store';
import { getAdminThemeColors } from '@/utils/theme';
import { AppScreen } from '@/types/app';
import AdminDashboardPage from './AdminDashboardPage';
import SpaceSetupPage from './SpaceSetupPage';
import MyQRCodePage from './MyQRCodePage';
import './AdminAppShell.css';

// ─────────────────────────────────────────────────────────────────────────────
// ADMIN APP SHELL
// (Equivalent to UserAppShell but for admin role)
//
// Shows:
// - Admin navigation menu
// - Tab-based page routing (Dashboard/Setup/QR Codes)
// - Admin profile and settings
// ─────────────────────────────────────────────────────────────────────────────

type AdminTab = 'dashboard' | 'setup' | 'qrcodes';

const AdminAppShell: React.FC = () => {
  const { isDarkMode } = useDarkMode();
  const colors = getAdminThemeColors(isDarkMode);
  const { toggleTheme } = useDarkMode();
  const setScreen = useAppStore((state) => state.setScreen);

  const [activeTab, setActiveTab] = useState<AdminTab>('dashboard');

  const renderContent = () => {
    switch (activeTab) {
      case 'dashboard':
        return <AdminDashboardPage />;
      case 'setup':
        return <SpaceSetupPage />;
      case 'qrcodes':
        return <MyQRCodePage />;
      default:
        return <AdminDashboardPage />;
    }
  };

  return (
    <div className="admin-app-shell" style={{ backgroundColor: colors.bg, color: colors.textPrimary }}>
      {/* Header */}
      <header
        className="admin-app-shell__header"
        style={{
          backgroundColor: colors.cardBg,
          borderColor: colors.borderColor,
        }}
      >
        <div className="admin-app-shell__header-left">
          <h1 style={{ margin: 0, fontSize: '1.5rem', fontWeight: 800 }}>
            Hotspot Admin
          </h1>
        </div>
        <div className="admin-app-shell__header-right">
          <button
            className="admin-app-shell__btn-theme"
            onClick={toggleTheme}
            style={{
              backgroundColor: colors.surfaceVariant,
              color: colors.textPrimary,
            }}
          >
            {isDarkMode ? '☀️' : '🌙'}
          </button>
          <button
            className="admin-app-shell__btn-logout"
            onClick={() => setScreen(AppScreen.RoleSelect)}
            style={{
              backgroundColor: '#ff4757',
              color: '#fff',
            }}
          >
            Logout
          </button>
        </div>
      </header>

      {/* Navigation Tabs */}
      <nav
        className="admin-app-shell__nav"
        style={{
          backgroundColor: colors.cardBg,
          borderColor: colors.borderColor,
        }}
      >
        {(['dashboard', 'setup', 'qrcodes'] as const).map((tab) => (
          <button
            key={tab}
            className={`admin-app-shell__nav-tab ${activeTab === tab ? 'active' : ''}`}
            onClick={() => setActiveTab(tab)}
            style={{
              color: activeTab === tab ? colors.adminAccent : colors.textSecondary,
              borderBottomColor: activeTab === tab ? colors.adminAccent : 'transparent',
            }}
          >
            {tab === 'dashboard' && '📊 Dashboard'}
            {tab === 'setup' && '🏗️ Setup Space'}
            {tab === 'qrcodes' && '📱 QR Codes'}
          </button>
        ))}
      </nav>

      {/* Main Content */}
      <main className="admin-app-shell__content">
        {renderContent()}
      </main>
    </div>
  );
};

export default AdminAppShell;
