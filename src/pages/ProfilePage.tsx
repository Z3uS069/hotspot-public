import React, { useState } from 'react';
import { useDarkMode } from '@/hooks';
import { getThemeColors } from '@/utils/theme';
import './ProfilePage.css';

// ─────────────────────────────────────────────────────────────────────────────
// PROFILE PAGE
// (Replaces lib/pages/profile_page.dart)
//
// Shows:
// - User profile information (avatar, name, email)
// - Settings and preferences
// - Notifications settings
// - Privacy settings
// - Account actions (logout, delete account)
// ─────────────────────────────────────────────────────────────────────────────

interface UserProfile {
  id: string;
  name: string;
  email: string;
  phone: string;
  avatar: string;
  memberSince: string;
}

const ProfilePage: React.FC = () => {
  const { isDarkMode, toggleTheme, setDarkMode } = useDarkMode();
  const colors = getThemeColors(isDarkMode);

  const [isEditing, setIsEditing] = useState(false);
  const [profile, setProfile] = useState<UserProfile>({
    id: 'user_001',
    name: 'John Doe',
    email: 'john.doe@example.com',
    phone: '+91 98765 43210',
    avatar: 'https://api.dicebear.com/7.x/avataaars/svg?seed=John',
    memberSince: 'January 2024',
  });

  const [settings, setSettings] = useState({
    notifications: true,
    emailUpdates: true,
    promotions: false,
    privateProfile: false,
  });

  const [editForm, setEditForm] = useState(profile);

  const handleSaveProfile = () => {
    setProfile(editForm);
    setIsEditing(false);
  };

  const handleSettingChange = (key: string, value: boolean) => {
    setSettings((prev) => ({ ...prev, [key]: value }));
  };

  return (
    <div className="profile-page" style={{ backgroundColor: colors.bg, color: colors.textPrimary }}>
      {/* Header */}
      <div
        className="profile-page__header"
        style={{
          backgroundColor: colors.cardBg,
          borderColor: colors.borderColor,
        }}
      >
        <h1>Profile</h1>
      </div>

      {/* Content */}
      <div className="profile-page__content">
        {/* Profile Card */}
        <section
          className="profile-page__section"
          style={{
            backgroundColor: colors.cardBg,
            borderColor: colors.borderColor,
          }}
        >
          <div className="profile-page__profile-header">
            <img
              src={profile.avatar}
              alt={profile.name}
              className="profile-page__avatar"
            />
            <div className="profile-page__profile-info">
              <h2 style={{ color: colors.textPrimary }}>{profile.name}</h2>
              <p style={{ color: colors.textSecondary }}>{profile.email}</p>
              <p
                className="profile-page__member-since"
                style={{ color: colors.textMuted }}
              >
                Member since {profile.memberSince}
              </p>
            </div>
            <button
              className="profile-page__btn-edit"
              onClick={() => {
                if (isEditing) {
                  handleSaveProfile();
                } else {
                  setIsEditing(true);
                  setEditForm(profile);
                }
              }}
              style={{
                backgroundColor: '#00C9A7',
                color: '#0B1426',
              }}
            >
              {isEditing ? 'Save' : 'Edit Profile'}
            </button>
          </div>

          {/* Edit Form */}
          {isEditing && (
            <div
              className="profile-page__edit-form"
              style={{
                borderTopColor: colors.borderColor,
              }}
            >
              <div className="profile-page__form-group">
                <label style={{ color: colors.textPrimary }}>Full Name</label>
                <input
                  type="text"
                  value={editForm.name}
                  onChange={(e) =>
                    setEditForm({ ...editForm, name: e.target.value })
                  }
                  style={{
                    backgroundColor: colors.bg,
                    color: colors.textPrimary,
                    borderColor: colors.borderColor,
                  }}
                />
              </div>

              <div className="profile-page__form-group">
                <label style={{ color: colors.textPrimary }}>Email</label>
                <input
                  type="email"
                  value={editForm.email}
                  onChange={(e) =>
                    setEditForm({ ...editForm, email: e.target.value })
                  }
                  style={{
                    backgroundColor: colors.bg,
                    color: colors.textPrimary,
                    borderColor: colors.borderColor,
                  }}
                />
              </div>

              <div className="profile-page__form-group">
                <label style={{ color: colors.textPrimary }}>Phone</label>
                <input
                  type="tel"
                  value={editForm.phone}
                  onChange={(e) =>
                    setEditForm({ ...editForm, phone: e.target.value })
                  }
                  style={{
                    backgroundColor: colors.bg,
                    color: colors.textPrimary,
                    borderColor: colors.borderColor,
                  }}
                />
              </div>

              <button
                className="profile-page__btn-cancel"
                onClick={() => setIsEditing(false)}
                style={{
                  color: colors.textSecondary,
                  borderColor: colors.borderColor,
                }}
              >
                Cancel
              </button>
            </div>
          )}

          {/* Profile Stats */}
          {!isEditing && (
            <div className="profile-page__stats">
              <div className="profile-page__stat">
                <div
                  className="profile-page__stat-value"
                  style={{ color: '#00C9A7' }}
                >
                  12
                </div>
                <div className="profile-page__stat-label" style={{ color: colors.textSecondary }}>
                  Bookings
                </div>
              </div>
              <div className="profile-page__stat">
                <div
                  className="profile-page__stat-value"
                  style={{ color: '#4DD0E1' }}
                >
                  8
                </div>
                <div className="profile-page__stat-label" style={{ color: colors.textSecondary }}>
                  Reviews
                </div>
              </div>
              <div className="profile-page__stat">
                <div className="profile-page__stat-value" style={{ color: '#00C9A7' }}>
                  4.8
                </div>
                <div className="profile-page__stat-label" style={{ color: colors.textSecondary }}>
                  Rating
                </div>
              </div>
            </div>
          )}
        </section>

        {/* Settings Section */}
        <section
          className="profile-page__section"
          style={{
            backgroundColor: colors.cardBg,
            borderColor: colors.borderColor,
          }}
        >
          <h3 style={{ color: colors.textPrimary, marginTop: 0 }}>
            Preferences
          </h3>

          <div className="profile-page__setting">
            <div>
              <div className="profile-page__setting-title" style={{ color: colors.textPrimary }}>
                Dark Mode
              </div>
              <div className="profile-page__setting-desc" style={{ color: colors.textSecondary }}>
                {isDarkMode ? 'Currently enabled' : 'Currently disabled'}
              </div>
            </div>
            <button
              className="profile-page__toggle"
              onClick={toggleTheme}
              style={{
                backgroundColor: isDarkMode ? '#00C9A7' : colors.surfaceVariant,
              }}
            >
              <div className="profile-page__toggle-ball" style={{ transform: isDarkMode ? 'translateX(24px)' : 'translateX(0)' }} />
            </button>
          </div>
        </section>

        {/* Notifications Section */}
        <section
          className="profile-page__section"
          style={{
            backgroundColor: colors.cardBg,
            borderColor: colors.borderColor,
          }}
        >
          <h3 style={{ color: colors.textPrimary, marginTop: 0 }}>
            Notifications
          </h3>

          <div className="profile-page__setting">
            <div>
              <div className="profile-page__setting-title" style={{ color: colors.textPrimary }}>
                Push Notifications
              </div>
              <div className="profile-page__setting-desc" style={{ color: colors.textSecondary }}>
                Receive booking updates and reminders
              </div>
            </div>
            <button
              className="profile-page__toggle"
              onClick={() =>
                handleSettingChange('notifications', !settings.notifications)
              }
              style={{
                backgroundColor: settings.notifications ? '#00C9A7' : colors.surfaceVariant,
              }}
            >
              <div className="profile-page__toggle-ball" style={{ transform: settings.notifications ? 'translateX(24px)' : 'translateX(0)' }} />
            </button>
          </div>

          <div className="profile-page__setting">
            <div>
              <div className="profile-page__setting-title" style={{ color: colors.textPrimary }}>
                Email Updates
              </div>
              <div className="profile-page__setting-desc" style={{ color: colors.textSecondary }}>
                Get email notifications about your activity
              </div>
            </div>
            <button
              className="profile-page__toggle"
              onClick={() =>
                handleSettingChange('emailUpdates', !settings.emailUpdates)
              }
              style={{
                backgroundColor: settings.emailUpdates ? '#00C9A7' : colors.surfaceVariant,
              }}
            >
              <div className="profile-page__toggle-ball" style={{ transform: settings.emailUpdates ? 'translateX(24px)' : 'translateX(0)' }} />
            </button>
          </div>

          <div className="profile-page__setting">
            <div>
              <div className="profile-page__setting-title" style={{ color: colors.textPrimary }}>
                Promotions
              </div>
              <div className="profile-page__setting-desc" style={{ color: colors.textSecondary }}>
                Receive special offers and promotions
              </div>
            </div>
            <button
              className="profile-page__toggle"
              onClick={() =>
                handleSettingChange('promotions', !settings.promotions)
              }
              style={{
                backgroundColor: settings.promotions ? '#00C9A7' : colors.surfaceVariant,
              }}
            >
              <div className="profile-page__toggle-ball" style={{ transform: settings.promotions ? 'translateX(24px)' : 'translateX(0)' }} />
            </button>
          </div>
        </section>

        {/* Privacy Section */}
        <section
          className="profile-page__section"
          style={{
            backgroundColor: colors.cardBg,
            borderColor: colors.borderColor,
          }}
        >
          <h3 style={{ color: colors.textPrimary, marginTop: 0 }}>Privacy</h3>

          <div className="profile-page__setting">
            <div>
              <div className="profile-page__setting-title" style={{ color: colors.textPrimary }}>
                Private Profile
              </div>
              <div className="profile-page__setting-desc" style={{ color: colors.textSecondary }}>
                Hide your profile from other users
              </div>
            </div>
            <button
              className="profile-page__toggle"
              onClick={() =>
                handleSettingChange('privateProfile', !settings.privateProfile)
              }
              style={{
                backgroundColor: settings.privateProfile ? '#00C9A7' : colors.surfaceVariant,
              }}
            >
              <div className="profile-page__toggle-ball" style={{ transform: settings.privateProfile ? 'translateX(24px)' : 'translateX(0)' }} />
            </button>
          </div>
        </section>

        {/* Account Actions */}
        <section
          className="profile-page__section profile-page__section--danger"
          style={{
            backgroundColor: colors.cardBg,
            borderColor: colors.borderColor,
          }}
        >
          <h3 style={{ color: colors.textPrimary, marginTop: 0 }}>
            Account
          </h3>

          <button
            className="profile-page__btn-logout"
            onClick={() => alert('Logging out...')}
            style={{
              borderColor: colors.borderColor,
              color: colors.textPrimary,
            }}
          >
            🚪 Log Out
          </button>

          <button
            className="profile-page__btn-delete"
            onClick={() =>
              alert('Are you sure? This action cannot be undone.')
            }
          >
            🗑️ Delete Account
          </button>
        </section>
      </div>
    </div>
  );
};

export default ProfilePage;
