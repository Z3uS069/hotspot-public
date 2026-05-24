import React, { useState } from 'react';
import { SpaceModel, ReviewModel } from '@/models';
import { useDarkMode } from '@/hooks';
import { getThemeColors } from '@/utils/theme';
import { sampleSpaces, sampleReviews } from '@/data/fixtures';
import './SpaceDetailsPage.css';

interface SpaceDetailsPageProps {
  spaceId: string;
  onBack: () => void;
}

// ─────────────────────────────────────────────────────────────────────────────
// SPACE DETAILS PAGE
// (Replaces lib/pages/space_details_page.dart)
//
// Shows:
// - Full space details with image
// - Booking packages
// - Reviews and ratings
// - Booking form
// ─────────────────────────────────────────────────────────────────────────────

const SpaceDetailsPage: React.FC<SpaceDetailsPageProps> = ({ spaceId, onBack }) => {
  const { isDarkMode } = useDarkMode();
  const colors = getThemeColors(isDarkMode);

  // Get space from fixtures
  const space = sampleSpaces.find((s) => s.id === spaceId);
  if (!space) {
    return (
      <div style={{ padding: '2rem', color: colors.textSecondary }}>
        Space not found
      </div>
    );
  }

  // Get reviews for this space
  const spaceReviews = sampleReviews.filter((r) => r.spaceId === spaceId);

  const [isSaved, setIsSaved] = useState(space.isFavorite);
  const [selectedPackage, setSelectedPackage] = useState('p1');
  const [bookingNotes, setBookingNotes] = useState('');
  const [showBookingForm, setShowBookingForm] = useState(false);

  const packages = [
    { id: 'p1', name: 'Hot Desk', price: space.price, capacity: 1 },
    { id: 'p2', name: 'Private Office', price: space.price * 3, capacity: 4 },
    { id: 'p3', name: 'Board Room', price: space.price * 5, capacity: 8 },
    { id: 'p4', name: 'Event Space', price: space.price * 10, capacity: 50 },
  ];

  const handleBooking = () => {
    alert(`Booked ${selectedPackage} at ${space.name}!`);
    setShowBookingForm(false);
  };

  return (
    <div
      className="space-details"
      style={{ backgroundColor: colors.bg, color: colors.textPrimary }}
    >
      {/* Header/Image Section */}
      <div className="space-details__header">
        <img
          src={space.imageUrl}
          alt={space.name}
          className="space-details__image"
          onError={(e) => {
            (e.target as HTMLImageElement).src =
              'data:image/svg+xml,%3Csvg xmlns="http://www.w3.org/2000/svg" width="800" height="400"%3E%3Crect fill="%23ddd" width="800" height="400"/%3E%3C/svg%3E';
          }}
        />
        <div className="space-details__header-overlay" />

        {/* Header Buttons */}
        <div className="space-details__header-buttons">
          <button
            className="space-details__btn-back"
            onClick={onBack}
            style={{
              backgroundColor: colors.cardBg,
              color: colors.textPrimary,
            }}
            title="Back"
          >
            ←
          </button>
          <button
            className="space-details__btn-favorite"
            onClick={() => setIsSaved(!isSaved)}
            style={{
              backgroundColor: colors.cardBg,
              color: isSaved ? '#00C9A7' : colors.textPrimary,
            }}
            title={isSaved ? 'Remove from saved' : 'Save to favorites'}
          >
            {isSaved ? '❤️' : '🤍'}
          </button>
        </div>

        {/* Space Info Overlay */}
        <div className="space-details__info-overlay">
          <h1 style={{ color: colors.textPrimary }}>{space.name}</h1>

          <div className="space-details__meta">
            <div className="space-details__rating">
              <span>⭐ {space.rating.toFixed(1)}</span>
              <span style={{ color: colors.textSecondary }}>
                ({space.reviewCount} reviews)
              </span>
            </div>
            <div
              className="space-details__hours"
              style={{ color: colors.textSecondary }}
            >
              🕐 {space.availability.startTime} - {space.availability.endTime}
            </div>
          </div>
        </div>
      </div>

      {/* Content Section */}
      <div className="space-details__content">
        {/* Basic Info */}
        <section
          className="space-details__section"
          style={{
            backgroundColor: colors.cardBg,
            borderColor: colors.borderColor,
          }}
        >
          <h2 style={{ color: colors.textPrimary }}>Location & Details</h2>

          <div className="space-details__detail-row">
            <span className="space-details__detail-label">📍 Address</span>
            <span style={{ color: colors.textSecondary }}>{space.address}</span>
          </div>

          <div className="space-details__detail-row">
            <span className="space-details__detail-label">📝 Description</span>
            <span style={{ color: colors.textSecondary }}>
              {space.description}
            </span>
          </div>

          <div className="space-details__detail-row">
            <span className="space-details__detail-label">👥 Capacity</span>
            <span style={{ color: colors.textSecondary }}>
              Up to {space.capacity} people
            </span>
          </div>
        </section>

        {/* Amenities */}
        <section
          className="space-details__section"
          style={{
            backgroundColor: colors.cardBg,
            borderColor: colors.borderColor,
          }}
        >
          <h2 style={{ color: colors.textPrimary }}>Amenities</h2>
          <div className="space-details__amenities">
            {space.amenities.map((amenity) => (
              <div
                key={amenity}
                className="space-details__amenity-tag"
                style={{
                  backgroundColor: colors.surfaceVariant,
                  color: colors.textSecondary,
                  borderColor: colors.borderColor,
                }}
              >
                {amenity}
              </div>
            ))}
          </div>
        </section>

        {/* Pricing Packages */}
        <section
          className="space-details__section"
          style={{
            backgroundColor: colors.cardBg,
            borderColor: colors.borderColor,
          }}
        >
          <h2 style={{ color: colors.textPrimary }}>Pricing Packages</h2>
          <div className="space-details__packages">
            {packages.map((pkg) => (
              <button
                key={pkg.id}
                className={`space-details__package ${
                  selectedPackage === pkg.id ? 'active' : ''
                }`}
                onClick={() => setSelectedPackage(pkg.id)}
                style={{
                  borderColor:
                    selectedPackage === pkg.id ? '#00C9A7' : colors.borderColor,
                  backgroundColor:
                    selectedPackage === pkg.id
                      ? 'rgba(0, 201, 167, 0.05)'
                      : 'transparent',
                  color: colors.textPrimary,
                }}
              >
                <div className="space-details__package-name">{pkg.name}</div>
                <div
                  className="space-details__package-price"
                  style={{ color: '#00C9A7' }}
                >
                  ₹{pkg.price}
                </div>
                <div
                  className="space-details__package-capacity"
                  style={{ color: colors.textSecondary, fontSize: '0.85rem' }}
                >
                  Up to {pkg.capacity} people
                </div>
              </button>
            ))}
          </div>

          <button
            className="space-details__btn-book"
            onClick={() => setShowBookingForm(!showBookingForm)}
            style={{
              backgroundColor: '#00C9A7',
              color: '#0B1426',
            }}
          >
            {showBookingForm ? 'Cancel' : 'Book Now'}
          </button>

          {/* Booking Form */}
          {showBookingForm && (
            <div className="space-details__booking-form">
              <div className="space-details__form-group">
                <label style={{ color: colors.textPrimary }}>Date</label>
                <input
                  type="date"
                  style={{
                    backgroundColor: colors.bg,
                    color: colors.textPrimary,
                    borderColor: colors.borderColor,
                  }}
                />
              </div>

              <div className="space-details__form-group">
                <label style={{ color: colors.textPrimary }}>Start Time</label>
                <input
                  type="time"
                  style={{
                    backgroundColor: colors.bg,
                    color: colors.textPrimary,
                    borderColor: colors.borderColor,
                  }}
                />
              </div>

              <div className="space-details__form-group">
                <label style={{ color: colors.textPrimary }}>End Time</label>
                <input
                  type="time"
                  style={{
                    backgroundColor: colors.bg,
                    color: colors.textPrimary,
                    borderColor: colors.borderColor,
                  }}
                />
              </div>

              <div className="space-details__form-group">
                <label style={{ color: colors.textPrimary }}>
                  Special Requests
                </label>
                <textarea
                  value={bookingNotes}
                  onChange={(e) => setBookingNotes(e.target.value)}
                  placeholder="Any special requests?"
                  style={{
                    backgroundColor: colors.bg,
                    color: colors.textPrimary,
                    borderColor: colors.borderColor,
                  }}
                />
              </div>

              <button
                className="space-details__btn-confirm"
                onClick={handleBooking}
                style={{
                  backgroundColor: '#00C9A7',
                  color: '#0B1426',
                }}
              >
                Confirm Booking
              </button>
            </div>
          )}
        </section>

        {/* Reviews */}
        {spaceReviews.length > 0 && (
          <section
            className="space-details__section"
            style={{
              backgroundColor: colors.cardBg,
              borderColor: colors.borderColor,
            }}
          >
            <h2 style={{ color: colors.textPrimary }}>Reviews</h2>
            <div className="space-details__reviews">
              {spaceReviews.map((review) => (
                <div
                  key={review.id}
                  className="space-details__review"
                  style={{ borderColor: colors.borderColor }}
                >
                  <div className="space-details__review-header">
                    <div>
                      <div
                        className="space-details__review-name"
                        style={{ color: colors.textPrimary }}
                      >
                        {review.userName}
                      </div>
                      <div
                        className="space-details__review-rating"
                        style={{ color: colors.textSecondary }}
                      >
                        ⭐ {review.rating}
                      </div>
                    </div>
                    <img
                      src={review.userAvatar}
                      alt={review.userName}
                      className="space-details__review-avatar"
                    />
                  </div>
                  <p
                    className="space-details__review-comment"
                    style={{ color: colors.textSecondary }}
                  >
                    {review.comment}
                  </p>
                  <div
                    className="space-details__review-helpful"
                    style={{ color: colors.textMuted }}
                  >
                    👍 {review.helpfulCount} found this helpful
                  </div>
                </div>
              ))}
            </div>
          </section>
        )}
      </div>
    </div>
  );
};

export default SpaceDetailsPage;
