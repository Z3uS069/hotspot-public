import React, { useState } from 'react';
import { useDarkMode } from '@/hooks';
import { getAdminThemeColors } from '@/utils/theme';
import { sampleSpaces } from '@/data/fixtures';
import './AdminDashboardPage.css';

// ─────────────────────────────────────────────────────────────────────────────
// ADMIN DASHBOARD PAGE
// (Replaces lib/pages/admin_dashboard_page.dart)
//
// Shows:
// - Admin statistics (revenue, bookings, spaces, ratings)
// - Space management table
// - Booking management
// - Revenue charts
// - Quick actions
// ─────────────────────────────────────────────────────────────────────────────

interface BookingStats {
  total: number;
  active: number;
  completed: number;
  cancelled: number;
}

interface RevenueData {
  month: string;
  amount: number;
}

const AdminDashboardPage: React.FC = () => {
  const { isDarkMode } = useDarkMode();
  const colors = getAdminThemeColors(isDarkMode);

  const [activeTab, setActiveTab] = useState<'overview' | 'spaces' | 'bookings' | 'revenue'>('overview');
  const [selectedSpace, setSelectedSpace] = useState<string | null>(null);

  // Sample stats
  const stats = {
    totalSpaces: sampleSpaces.length,
    totalRevenue: 145250,
    activeBookings: 12,
    totalBookings: 89,
    averageRating: 4.7,
    monthlyGrowth: 12.5,
  };

  const bookingStats: BookingStats = {
    total: 89,
    active: 12,
    completed: 65,
    cancelled: 12,
  };

  const revenueData: RevenueData[] = [
    { month: 'Jan', amount: 8500 },
    { month: 'Feb', amount: 9200 },
    { month: 'Mar', amount: 11500 },
    { month: 'Apr', amount: 13750 },
    { month: 'May', amount: 15300 },
    { month: 'Jun', amount: 18200 },
  ];

  const topSpaces = sampleSpaces
    .sort((a, b) => b.rating - a.rating)
    .slice(0, 5);

  return (
    <div className="admin-dashboard" style={{ backgroundColor: colors.bg, color: colors.textPrimary }}>
      {/* Header */}
      <div
        className="admin-dashboard__header"
        style={{
          backgroundColor: colors.cardBg,
          borderColor: colors.borderColor,
        }}
      >
        <h1>Admin Dashboard</h1>
        <p style={{ color: colors.textSecondary }}>Manage your spaces and bookings</p>
      </div>

      {/* Stats Grid */}
      <div className="admin-dashboard__stats-grid">
        {/* Total Spaces */}
        <div
          className="admin-dashboard__stat-card"
          style={{
            backgroundColor: colors.cardBg,
            borderColor: colors.adminAccent,
          }}
        >
          <div className="admin-dashboard__stat-icon">🏢</div>
          <div className="admin-dashboard__stat-content">
            <div
              className="admin-dashboard__stat-value"
              style={{ color: colors.adminAccent }}
            >
              {stats.totalSpaces}
            </div>
            <div
              className="admin-dashboard__stat-label"
              style={{ color: colors.textSecondary }}
            >
              Total Spaces
            </div>
          </div>
        </div>

        {/* Total Revenue */}
        <div
          className="admin-dashboard__stat-card"
          style={{
            backgroundColor: colors.cardBg,
            borderColor: colors.adminAccent2,
          }}
        >
          <div className="admin-dashboard__stat-icon">💰</div>
          <div className="admin-dashboard__stat-content">
            <div
              className="admin-dashboard__stat-value"
              style={{ color: colors.adminAccent2 }}
            >
              ₹{stats.totalRevenue.toLocaleString()}
            </div>
            <div
              className="admin-dashboard__stat-label"
              style={{ color: colors.textSecondary }}
            >
              Total Revenue
            </div>
          </div>
        </div>

        {/* Active Bookings */}
        <div
          className="admin-dashboard__stat-card"
          style={{
            backgroundColor: colors.cardBg,
            borderColor: colors.adminAccent,
          }}
        >
          <div className="admin-dashboard__stat-icon">📅</div>
          <div className="admin-dashboard__stat-content">
            <div
              className="admin-dashboard__stat-value"
              style={{ color: colors.adminAccent }}
            >
              {stats.activeBookings}
            </div>
            <div
              className="admin-dashboard__stat-label"
              style={{ color: colors.textSecondary }}
            >
              Active Bookings
            </div>
          </div>
        </div>

        {/* Average Rating */}
        <div
          className="admin-dashboard__stat-card"
          style={{
            backgroundColor: colors.cardBg,
            borderColor: colors.adminAccent2,
          }}
        >
          <div className="admin-dashboard__stat-icon">⭐</div>
          <div className="admin-dashboard__stat-content">
            <div
              className="admin-dashboard__stat-value"
              style={{ color: colors.adminAccent2 }}
            >
              {stats.averageRating}
            </div>
            <div
              className="admin-dashboard__stat-label"
              style={{ color: colors.textSecondary }}
            >
              Avg Rating
            </div>
          </div>
        </div>
      </div>

      {/* Tabs */}
      <div
        className="admin-dashboard__tabs"
        style={{
          backgroundColor: colors.cardBg,
          borderColor: colors.borderColor,
        }}
      >
        {(['overview', 'spaces', 'bookings', 'revenue'] as const).map((tab) => (
          <button
            key={tab}
            className={`admin-dashboard__tab ${activeTab === tab ? 'active' : ''}`}
            onClick={() => setActiveTab(tab)}
            style={{
              color: activeTab === tab ? colors.adminAccent : colors.textSecondary,
              borderBottomColor: activeTab === tab ? colors.adminAccent : 'transparent',
            }}
          >
            {tab.charAt(0).toUpperCase() + tab.slice(1)}
          </button>
        ))}
      </div>

      {/* Content */}
      <div className="admin-dashboard__content">
        {/* Overview Tab */}
        {activeTab === 'overview' && (
          <div className="admin-dashboard__overview">
            {/* Booking Status */}
            <section
              className="admin-dashboard__section"
              style={{
                backgroundColor: colors.cardBg,
                borderColor: colors.borderColor,
              }}
            >
              <h2 style={{ color: colors.textPrimary }}>Booking Status</h2>
              <div className="admin-dashboard__status-grid">
                <div className="admin-dashboard__status-item">
                  <div className="admin-dashboard__status-label">Total Bookings</div>
                  <div
                    className="admin-dashboard__status-value"
                    style={{ color: colors.adminAccent }}
                  >
                    {bookingStats.total}
                  </div>
                </div>
                <div className="admin-dashboard__status-item">
                  <div className="admin-dashboard__status-label">Active</div>
                  <div
                    className="admin-dashboard__status-value"
                    style={{ color: '#00C9A7' }}
                  >
                    {bookingStats.active}
                  </div>
                </div>
                <div className="admin-dashboard__status-item">
                  <div className="admin-dashboard__status-label">Completed</div>
                  <div
                    className="admin-dashboard__status-value"
                    style={{ color: colors.adminAccent2 }}
                  >
                    {bookingStats.completed}
                  </div>
                </div>
                <div className="admin-dashboard__status-item">
                  <div className="admin-dashboard__status-label">Cancelled</div>
                  <div
                    className="admin-dashboard__status-value"
                    style={{ color: '#ff4757' }}
                  >
                    {bookingStats.cancelled}
                  </div>
                </div>
              </div>
            </section>

            {/* Top Spaces */}
            <section
              className="admin-dashboard__section"
              style={{
                backgroundColor: colors.cardBg,
                borderColor: colors.borderColor,
              }}
            >
              <h2 style={{ color: colors.textPrimary }}>Top Performing Spaces</h2>
              <div className="admin-dashboard__spaces-list">
                {topSpaces.map((space, idx) => (
                  <div
                    key={space.id}
                    className="admin-dashboard__space-item"
                    style={{ borderColor: colors.borderColor }}
                  >
                    <div className="admin-dashboard__space-rank"># {idx + 1}</div>
                    <div className="admin-dashboard__space-info">
                      <div style={{ color: colors.textPrimary, fontWeight: 600 }}>
                        {space.name}
                      </div>
                      <div
                        style={{
                          color: colors.textSecondary,
                          fontSize: '0.85rem',
                        }}
                      >
                        ₹{space.price}/hr • ⭐ {space.rating}
                      </div>
                    </div>
                    <div
                      className="admin-dashboard__space-capacity"
                      style={{ color: colors.textMuted }}
                    >
                      👥 {space.capacity}
                    </div>
                  </div>
                ))}
              </div>
            </section>
          </div>
        )}

        {/* Spaces Tab */}
        {activeTab === 'spaces' && (
          <section
            className="admin-dashboard__section"
            style={{
              backgroundColor: colors.cardBg,
              borderColor: colors.borderColor,
            }}
          >
            <div className="admin-dashboard__section-header">
              <h2 style={{ color: colors.textPrimary }}>Manage Spaces</h2>
              <button
                className="admin-dashboard__btn-add"
                style={{
                  backgroundColor: colors.adminAccent,
                  color: '#fff',
                }}
              >
                + Add New Space
              </button>
            </div>

            <div className="admin-dashboard__spaces-table">
              <div className="admin-dashboard__table-header">
                <div>Space Name</div>
                <div>Price</div>
                <div>Rating</div>
                <div>Bookings</div>
                <div>Actions</div>
              </div>

              {sampleSpaces.map((space) => (
                <div
                  key={space.id}
                  className="admin-dashboard__table-row"
                  style={{
                    borderColor: colors.borderColor,
                    backgroundColor:
                      selectedSpace === space.id ? colors.surfaceVariant : 'transparent',
                  }}
                >
                  <div style={{ color: colors.textPrimary, fontWeight: 500 }}>
                    {space.name}
                  </div>
                  <div style={{ color: colors.adminAccent }}>₹{space.price}</div>
                  <div style={{ color: colors.adminAccent2 }}>⭐ {space.rating}</div>
                  <div style={{ color: colors.textSecondary }}>12</div>
                  <div className="admin-dashboard__row-actions">
                    <button
                      className="admin-dashboard__btn-small"
                      onClick={() => setSelectedSpace(space.id)}
                      style={{
                        backgroundColor: colors.adminAccent,
                        color: '#fff',
                      }}
                    >
                      Edit
                    </button>
                    <button
                      className="admin-dashboard__btn-small admin-dashboard__btn-danger"
                      style={{
                        backgroundColor: '#ff4757',
                        color: '#fff',
                      }}
                    >
                      Delete
                    </button>
                  </div>
                </div>
              ))}
            </div>
          </section>
        )}

        {/* Bookings Tab */}
        {activeTab === 'bookings' && (
          <section
            className="admin-dashboard__section"
            style={{
              backgroundColor: colors.cardBg,
              borderColor: colors.borderColor,
            }}
          >
            <h2 style={{ color: colors.textPrimary }}>Recent Bookings</h2>
            <div className="admin-dashboard__bookings-list">
              {[
                { id: 'b1', space: 'Urban Hub', status: 'active', date: 'Today', price: 2700 },
                { id: 'b2', space: 'Cafe Works', status: 'upcoming', date: 'Tomorrow', price: 1800 },
                { id: 'b3', space: 'The Hive', status: 'completed', date: 'Apr 10', price: 4000 },
                { id: 'b4', space: 'Studio 54', status: 'cancelled', date: 'Apr 5', price: 1350 },
              ].map((booking) => (
                <div
                  key={booking.id}
                  className="admin-dashboard__booking-item"
                  style={{ borderColor: colors.borderColor }}
                >
                  <div>
                    <div style={{ color: colors.textPrimary, fontWeight: 600 }}>
                      {booking.space}
                    </div>
                    <div style={{ color: colors.textSecondary, fontSize: '0.85rem' }}>
                      {booking.date}
                    </div>
                  </div>
                  <div
                    style={{
                      padding: '0.4rem 0.8rem',
                      borderRadius: '0.3rem',
                      fontSize: '0.8rem',
                      fontWeight: 600,
                      color: '#fff',
                      backgroundColor:
                        booking.status === 'active'
                          ? '#00C9A7'
                          : booking.status === 'upcoming'
                          ? '#4DD0E1'
                          : booking.status === 'cancelled'
                          ? '#ff4757'
                          : colors.adminAccent2,
                    }}
                  >
                    {booking.status.toUpperCase()}
                  </div>
                  <div style={{ color: colors.adminAccent, fontWeight: 700 }}>
                    ₹{booking.price}
                  </div>
                </div>
              ))}
            </div>
          </section>
        )}

        {/* Revenue Tab */}
        {activeTab === 'revenue' && (
          <section
            className="admin-dashboard__section"
            style={{
              backgroundColor: colors.cardBg,
              borderColor: colors.borderColor,
            }}
          >
            <h2 style={{ color: colors.textPrimary }}>Revenue Trend</h2>
            <div className="admin-dashboard__revenue-chart">
              <div className="admin-dashboard__chart-bars">
                {revenueData.map((data) => {
                  const maxAmount = Math.max(...revenueData.map((d) => d.amount));
                  const height = (data.amount / maxAmount) * 100;
                  return (
                    <div
                      key={data.month}
                      className="admin-dashboard__chart-bar-wrapper"
                    >
                      <div
                        className="admin-dashboard__chart-bar"
                        style={{
                          height: `${height}%`,
                          backgroundColor: colors.adminAccent,
                        }}
                        title={`₹${data.amount}`}
                      />
                      <div
                        className="admin-dashboard__chart-label"
                        style={{ color: colors.textSecondary }}
                      >
                        {data.month}
                      </div>
                    </div>
                  );
                })}
              </div>
            </div>

            <div className="admin-dashboard__revenue-summary">
              <div
                className="admin-dashboard__summary-item"
                style={{ borderColor: colors.borderColor }}
              >
                <div style={{ color: colors.textSecondary }}>Total Revenue</div>
                <div style={{ color: colors.adminAccent, fontSize: '1.5rem', fontWeight: 800 }}>
                  ₹{revenueData.reduce((sum, d) => sum + d.amount, 0).toLocaleString()}
                </div>
              </div>
              <div
                className="admin-dashboard__summary-item"
                style={{ borderColor: colors.borderColor }}
              >
                <div style={{ color: colors.textSecondary }}>Average per Month</div>
                <div style={{ color: colors.adminAccent2, fontSize: '1.5rem', fontWeight: 800 }}>
                  ₹
                  {Math.round(
                    revenueData.reduce((sum, d) => sum + d.amount, 0) / revenueData.length
                  ).toLocaleString()}
                </div>
              </div>
              <div
                className="admin-dashboard__summary-item"
                style={{ borderColor: colors.borderColor }}
              >
                <div style={{ color: colors.textSecondary }}>Monthly Growth</div>
                <div style={{ color: '#00C9A7', fontSize: '1.5rem', fontWeight: 800 }}>
                  +{stats.monthlyGrowth}%
                </div>
              </div>
            </div>
          </section>
        )}
      </div>
    </div>
  );
};

export default AdminDashboardPage;
