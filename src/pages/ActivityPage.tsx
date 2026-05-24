import React, { useState } from 'react';
import { useDarkMode } from '@/hooks';
import { getThemeColors } from '@/utils/theme';
import { sampleSpaces } from '@/data/fixtures';
import './ActivityPage.css';

// ─────────────────────────────────────────────────────────────────────────────
// ACTIVITY PAGE
// (Replaces lib/pages/activity_page.dart)
//
// Shows:
// - Booking history with status
// - Upcoming bookings
// - Past bookings
// - Filter by status
// ─────────────────────────────────────────────────────────────────────────────

interface Booking {
  id: string;
  spaceId: string;
  spaceName: string;
  spaceThumbnail: string;
  date: string;
  startTime: string;
  endTime: string;
  status: 'upcoming' | 'active' | 'completed' | 'cancelled';
  totalPrice: number;
  numberOfPeople: number;
  specialRequests?: string;
}

const ActivityPage: React.FC = () => {
  const { isDarkMode } = useDarkMode();
  const colors = getThemeColors(isDarkMode);

  const [filterStatus, setFilterStatus] = useState<'all' | 'upcoming' | 'active' | 'completed' | 'cancelled'>('all');

  // Sample booking data
  const bookings: Booking[] = [
    {
      id: 'booking_001',
      spaceId: '1',
      spaceName: 'Urban Hub',
      spaceThumbnail: 'https://images.unsplash.com/photo-1606786016944-80fae1b216ca?w=400&h=300&fit=crop',
      date: 'Today',
      startTime: '10:00 AM',
      endTime: '3:00 PM',
      status: 'active',
      totalPrice: 2700,
      numberOfPeople: 3,
    },
    {
      id: 'booking_002',
      spaceId: '2',
      spaceName: 'Cafe Works',
      spaceThumbnail: 'https://images.unsplash.com/photo-1552664730-d307ca884978?w=400&h=300&fit=crop',
      date: 'Tomorrow',
      startTime: '2:00 PM',
      endTime: '6:00 PM',
      status: 'upcoming',
      totalPrice: 1800,
      numberOfPeople: 2,
      specialRequests: 'Window seating preferred',
    },
    {
      id: 'booking_003',
      spaceId: '3',
      spaceName: 'The Hive',
      spaceThumbnail: 'https://images.unsplash.com/photo-1497366216548-37526070297c?w=400&h=300&fit=crop',
      date: 'Apr 10, 2024',
      startTime: '9:00 AM',
      endTime: '5:00 PM',
      status: 'completed',
      totalPrice: 4000,
      numberOfPeople: 4,
    },
    {
      id: 'booking_004',
      spaceId: '4',
      spaceName: 'Studio 54',
      spaceThumbnail: 'https://images.unsplash.com/photo-1442512595331-e89e73853f31?w=400&h=300&fit=crop',
      date: 'Apr 5, 2024',
      startTime: '11:00 AM',
      endTime: '2:00 PM',
      status: 'cancelled',
      totalPrice: 1350,
      numberOfPeople: 1,
    },
    {
      id: 'booking_005',
      spaceId: '5',
      spaceName: 'Green Desk',
      spaceThumbnail: 'https://images.unsplash.com/photo-1557672172-298e090d0f80?w=400&h=300&fit=crop',
      date: 'Apr 3, 2024',
      startTime: '10:00 AM',
      endTime: '4:00 PM',
      status: 'completed',
      totalPrice: 3000,
      numberOfPeople: 5,
    },
  ];

  const filteredBookings = bookings.filter(
    (booking) => filterStatus === 'all' || booking.status === filterStatus
  );

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'active':
        return '#00C9A7';
      case 'upcoming':
        return '#4DD0E1';
      case 'completed':
        return colors.textMuted;
      case 'cancelled':
        return '#ff4757';
      default:
        return colors.textSecondary;
    }
  };

  const getStatusLabel = (status: string) => {
    switch (status) {
      case 'active':
        return 'Active Now';
      case 'upcoming':
        return 'Upcoming';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status;
    }
  };

  const statuses = ['all', 'upcoming', 'active', 'completed', 'cancelled'] as const;

  return (
    <div className="activity-page" style={{ backgroundColor: colors.bg, color: colors.textPrimary }}>
      {/* Header */}
      <div
        className="activity-page__header"
        style={{
          backgroundColor: colors.cardBg,
          borderColor: colors.borderColor,
        }}
      >
        <h1>My Bookings</h1>
        <p style={{ color: colors.textSecondary }}>
          {filteredBookings.length} booking{filteredBookings.length !== 1 ? 's' : ''}
        </p>
      </div>

      {/* Filter Tabs */}
      <div
        className="activity-page__filters"
        style={{
          backgroundColor: colors.cardBg,
          borderColor: colors.borderColor,
        }}
      >
        {statuses.map((status) => (
          <button
            key={status}
            className={`activity-page__filter-tab ${filterStatus === status ? 'active' : ''}`}
            onClick={() => setFilterStatus(status)}
            style={{
              color: filterStatus === status ? '#00C9A7' : colors.textSecondary,
              borderBottomColor: filterStatus === status ? '#00C9A7' : 'transparent',
            }}
          >
            {status === 'all' ? 'All' : getStatusLabel(status)}
          </button>
        ))}
      </div>

      {/* Bookings List */}
      <div className="activity-page__content">
        {filteredBookings.length > 0 ? (
          <div className="activity-page__bookings-list">
            {filteredBookings.map((booking) => (
              <div
                key={booking.id}
                className="activity-page__booking-card"
                style={{
                  backgroundColor: colors.cardBg,
                  borderColor: colors.borderColor,
                }}
              >
                {/* Image */}
                <img
                  src={booking.spaceThumbnail}
                  alt={booking.spaceName}
                  className="activity-page__booking-image"
                  onError={(e) => {
                    (e.target as HTMLImageElement).src = 'data:image/svg+xml,%3Csvg xmlns="http://www.w3.org/2000/svg" width="400" height="300"%3E%3Crect fill="%23ddd" width="400" height="300"/%3E%3C/svg%3E';
                  }}
                />

                {/* Content */}
                <div className="activity-page__booking-content">
                  <div className="activity-page__booking-header">
                    <h3 style={{ color: colors.textPrimary }}>
                      {booking.spaceName}
                    </h3>
                    <div
                      className="activity-page__booking-status"
                      style={{
                        backgroundColor: getStatusColor(booking.status),
                        color: booking.status === 'cancelled' ? 'white' : '#0B1426',
                      }}
                    >
                      {getStatusLabel(booking.status)}
                    </div>
                  </div>

                  <div className="activity-page__booking-details">
                    <div className="activity-page__detail-row">
                      <span style={{ color: colors.textSecondary }}>📅 Date</span>
                      <span style={{ color: colors.textPrimary }}>{booking.date}</span>
                    </div>

                    <div className="activity-page__detail-row">
                      <span style={{ color: colors.textSecondary }}>🕐 Time</span>
                      <span style={{ color: colors.textPrimary }}>
                        {booking.startTime} - {booking.endTime}
                      </span>
                    </div>

                    <div className="activity-page__detail-row">
                      <span style={{ color: colors.textSecondary }}>👥 People</span>
                      <span style={{ color: colors.textPrimary }}>
                        {booking.numberOfPeople}
                      </span>
                    </div>

                    {booking.specialRequests && (
                      <div className="activity-page__detail-row">
                        <span style={{ color: colors.textSecondary }}>📝 Notes</span>
                        <span style={{ color: colors.textSecondary }}>
                          {booking.specialRequests}
                        </span>
                      </div>
                    )}
                  </div>

                  <div className="activity-page__booking-footer">
                    <div
                      className="activity-page__booking-price"
                      style={{ color: '#00C9A7' }}
                    >
                      ₹{booking.totalPrice}
                    </div>

                    <div className="activity-page__booking-actions">
                      {booking.status === 'upcoming' && (
                        <button
                          className="activity-page__btn-cancel"
                          onClick={() =>
                            alert('Cancellation request submitted')
                          }
                        >
                          Cancel Booking
                        </button>
                      )}

                      {booking.status === 'active' && (
                        <button
                          className="activity-page__btn-view"
                          onClick={() =>
                            alert('Opening space details...')
                          }
                        >
                          View Details
                        </button>
                      )}

                      {booking.status === 'completed' && (
                        <button
                          className="activity-page__btn-review"
                          onClick={() =>
                            alert('Opening review form...')
                          }
                        >
                          Leave Review
                        </button>
                      )}
                    </div>
                  </div>
                </div>
              </div>
            ))}
          </div>
        ) : (
          <div
            className="activity-page__empty"
            style={{ color: colors.textSecondary }}
          >
            <p>No bookings found.</p>
            <button
              onClick={() => setFilterStatus('all')}
              style={{
                backgroundColor: '#00C9A7',
                color: '#0B1426',
                border: 'none',
                padding: '0.75rem 1.5rem',
                borderRadius: '0.5rem',
                cursor: 'pointer',
                marginTop: '1rem',
              }}
            >
              View All Bookings
            </button>
          </div>
        )}
      </div>
    </div>
  );
};

export default ActivityPage;
