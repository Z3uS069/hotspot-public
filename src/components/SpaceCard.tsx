import React, { useState } from 'react';
import { SpaceModel } from '@/models';
import { useDarkMode } from '@/hooks';
import { useAppStore } from '@/store';
import { AppScreen } from '@/types/app';
import { getThemeColors } from '@/utils/theme';
import './SpaceCard.css';

interface SpaceCardProps {
  space: SpaceModel;
  onSelect?: (spaceId: string) => void;
}

/**
 * SpaceCard - Displays a single co-working space card
 * (Replaces lib/widgets/space_card.dart)
 *
 * Shows:
 * - Space image with gradient overlay
 * - Name and rating
 * - Address and distance
 * - Price and capacity
 * - Tag badge if present
 * - Interactive selection
 */
const SpaceCard: React.FC<SpaceCardProps> = ({ space, onSelect }) => {
  const { isDarkMode } = useDarkMode();
  const colors = getThemeColors(isDarkMode);
  const setScreen = useAppStore((state) => state.setScreen);
  const setSpaceDetailsId = useAppStore((state) => state.setSpaceDetailsId);
  const [isPressed, setIsPressed] = useState(false);

  const handleSelect = () => {
    setSpaceDetailsId(space.id);
    setScreen(AppScreen.SpaceDetails);
    onSelect?.(space.id);
  };

  return (
    <div
      className={`space-card ${isPressed ? 'pressed' : ''}`}
      onClick={handleSelect}
      onMouseDown={() => setIsPressed(true)}
      onMouseUp={() => setIsPressed(false)}
      onMouseLeave={() => setIsPressed(false)}
      style={{
        backgroundColor: colors.cardBg,
        borderColor: colors.borderColor,
        '--text-primary': colors.textPrimary,
        '--text-secondary': colors.textSecondary,
        '--text-muted': colors.textMuted,
        '--border-color': colors.borderColor,
      } as React.CSSProperties & Record<string, string>}
    >
      {/* Image Section */}
      <div className="space-card__image-wrapper">
        <img
          src={space.imageUrl}
          alt={space.name}
          className="space-card__image"
          onError={(e) => {
            (e.target as HTMLImageElement).src = 'data:image/svg+xml,%3Csvg xmlns="http://www.w3.org/2000/svg" width="400" height="300"%3E%3Crect fill="%23ddd" width="400" height="300"/%3E%3C/svg%3E';
          }}
        />
        {/* Gradient Overlay */}
        <div className="space-card__overlay" />

        {/* Tag Badge */}
        {space.tag && (
          <div className="space-card__tag">
            {space.tag}
          </div>
        )}
      </div>

      {/* Info Section */}
      <div className="space-card__info">
        {/* Name */}
        <h3
          className="space-card__name"
          style={{ color: colors.textPrimary }}
        >
          {space.name}
        </h3>

        {/* Rating */}
        <div
          className="space-card__rating"
          style={{ color: colors.textSecondary }}
        >
          <span className="space-card__rating-icon">⭐</span>
          <span>{space.rating.toFixed(1)}</span>
          <span className="space-card__review-count">
            ({space.reviewCount})
          </span>
        </div>

        {/* Address */}
        <p
          className="space-card__address"
          style={{ color: colors.textSecondary }}
        >
          📍 {space.address}
        </p>

        {/* Distance */}
        {space.distanceKm !== undefined && (
          <p
            className="space-card__distance"
            style={{ color: colors.textMuted }}
          >
            {space.distanceKm.toFixed(1)} km away
          </p>
        )}

        {/* Price and Capacity */}
        <div className="space-card__footer">
          <div className="space-card__price" style={{ color: '#00C9A7' }}>
            ₹{space.price}<span>/hr</span>
          </div>
          <div
            className="space-card__capacity"
            style={{ color: colors.textMuted }}
          >
            👥 {space.capacity} people
          </div>
        </div>
      </div>
    </div>
  );
};

export default SpaceCard;
