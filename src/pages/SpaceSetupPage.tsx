import React, { useState } from 'react';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { useDarkMode } from '@/hooks';
import { getAdminThemeColors } from '@/utils/theme';
import { SpaceSetupSchema, SpaceSetupFormData } from '@/utils/validation';
import './SpaceSetupPage.css';

// ─────────────────────────────────────────────────────────────────────────────
// SPACE SETUP PAGE
// (Replaces lib/pages/space_setup_page.dart)
//
// Shows:
// - Form to add new spaces
// - Form to edit existing spaces
// - Image upload
// - Amenities selection
// - Pricing setup
// ─────────────────────────────────────────────────────────────────────────────

const amenitiesList = [
  'WiFi',
  'Coffee',
  'Parking',
  'Meeting Room',
  'Kitchen',
  'Gym',
  'Cafe',
  'Lounge',
  'Conference Room',
  'Garden',
  'High Speed Internet',
  'Tech Support',
];

const SpaceSetupPage: React.FC = () => {
  const { isDarkMode } = useDarkMode();
  const colors = getAdminThemeColors(isDarkMode);

  const {
    register,
    handleSubmit,
    formState: { errors },
    watch,
    setValue,
  } = useForm<SpaceSetupFormData>({
    resolver: zodResolver(SpaceSetupSchema),
    defaultValues: {
      name: '',
      address: '',
      description: '',
      price: 500,
      capacity: 10,
      imageUrl: '',
      amenities: [],
      startTime: '08:00',
      endTime: '20:00',
    },
  });

  const [selectedAmenities, setSelectedAmenities] = useState<string[]>([]);
  const [successMessage, setSuccessMessage] = useState<string>('');
  const imageUrl = watch('imageUrl');

  const toggleAmenity = (amenity: string) => {
    const updated = selectedAmenities.includes(amenity)
      ? selectedAmenities.filter((a) => a !== amenity)
      : [...selectedAmenities, amenity];
    setSelectedAmenities(updated);
    setValue('amenities', updated);
  };

  const onSubmit = (data: SpaceSetupFormData) => {
    const spaceData = {
      ...data,
      amenities: selectedAmenities,
    };
    console.log('Creating new space:', spaceData);
    setSuccessMessage('Space created successfully!');
    setTimeout(() => setSuccessMessage(''), 3000);
  };

  return (
    <div className="space-setup-page" style={{ backgroundColor: colors.bg, color: colors.textPrimary }}>
      {/* Header */}
      <div
        className="space-setup-page__header"
        style={{
          backgroundColor: colors.cardBg,
          borderColor: colors.borderColor,
        }}
      >
        <h1>Setup New Space</h1>
        <p style={{ color: colors.textSecondary }}>Add a new co-working space</p>
      </div>

      {/* Form */}
      <div className="space-setup-page__content">
        {successMessage && (
          <div
            className="space-setup-page__success-message"
            style={{
              backgroundColor: '#00C9A7',
              color: '#fff',
            }}
          >
            ✓ {successMessage}
          </div>
        )}

        <form
          onSubmit={handleSubmit(onSubmit)}
          className="space-setup-page__form"
          style={{
            backgroundColor: colors.cardBg,
            borderColor: colors.borderColor,
          }}
        >
          {/* Basic Information */}
          <section className="space-setup-page__section">
            <h2 style={{ color: colors.textPrimary }}>Basic Information</h2>

            <div className="space-setup-page__form-group">
              <label style={{ color: colors.textPrimary }}>Space Name *</label>
              <input
                type="text"
                placeholder="e.g., Urban Hub"
                style={{
                  backgroundColor: colors.bg,
                  color: colors.textPrimary,
                  borderColor: errors.name ? '#ff4757' : colors.borderColor,
                }}
                {...register('name')}
              />
              {errors.name && (
                <div className="space-setup-page__error">{errors.name.message}</div>
              )}
            </div>

            <div className="space-setup-page__form-group">
              <label style={{ color: colors.textPrimary }}>Address *</label>
              <input
                type="text"
                placeholder="123 Main Street, City"
                style={{
                  backgroundColor: colors.bg,
                  color: colors.textPrimary,
                  borderColor: errors.address ? '#ff4757' : colors.borderColor,
                }}
                {...register('address')}
              />
              {errors.address && (
                <div className="space-setup-page__error">{errors.address.message}</div>
              )}
            </div>

            <div className="space-setup-page__form-group">
              <label style={{ color: colors.textPrimary }}>Description *</label>
              <textarea
                placeholder="Describe your space..."
                style={{
                  backgroundColor: colors.bg,
                  color: colors.textPrimary,
                  borderColor: errors.description ? '#ff4757' : colors.borderColor,
                }}
                {...register('description')}
              />
              {errors.description && (
                <div className="space-setup-page__error">
                  {errors.description.message}
                </div>
              )}
            </div>
          </section>

          {/* Pricing & Capacity */}
          <section className="space-setup-page__section">
            <h2 style={{ color: colors.textPrimary }}>Pricing & Capacity</h2>

            <div className="space-setup-page__form-row">
              <div className="space-setup-page__form-group">
                <label style={{ color: colors.textPrimary }}>
                  Price per Hour (₹) *
                </label>
                <input
                  type="number"
                  min="0"
                  placeholder="500"
                  style={{
                    backgroundColor: colors.bg,
                    color: colors.textPrimary,
                    borderColor: errors.price ? '#ff4757' : colors.borderColor,
                  }}
                  {...register('price', { valueAsNumber: true })}
                />
                {errors.price && (
                  <div className="space-setup-page__error">{errors.price.message}</div>
                )}
              </div>

              <div className="space-setup-page__form-group">
                <label style={{ color: colors.textPrimary }}>
                  Capacity (People) *
                </label>
                <input
                  type="number"
                  min="1"
                  placeholder="10"
                  style={{
                    backgroundColor: colors.bg,
                    color: colors.textPrimary,
                    borderColor: errors.capacity ? '#ff4757' : colors.borderColor,
                  }}
                  {...register('capacity', { valueAsNumber: true })}
                />
                {errors.capacity && (
                  <div className="space-setup-page__error">
                    {errors.capacity.message}
                  </div>
                )}
              </div>
            </div>
          </section>

          {/* Availability */}
          <section className="space-setup-page__section">
            <h2 style={{ color: colors.textPrimary }}>Availability</h2>

            <div className="space-setup-page__form-row">
              <div className="space-setup-page__form-group">
                <label style={{ color: colors.textPrimary }}>Opening Time</label>
                <input
                  type="time"
                  style={{
                    backgroundColor: colors.bg,
                    color: colors.textPrimary,
                    borderColor: colors.borderColor,
                  }}
                  {...register('startTime')}
                />
              </div>

              <div className="space-setup-page__form-group">
                <label style={{ color: colors.textPrimary }}>Closing Time</label>
                <input
                  type="time"
                  style={{
                    backgroundColor: colors.bg,
                    color: colors.textPrimary,
                    borderColor: errors.endTime ? '#ff4757' : colors.borderColor,
                  }}
                  {...register('endTime')}
                />
                {errors.endTime && (
                  <div className="space-setup-page__error">
                    {errors.endTime.message}
                  </div>
                )}
              </div>
            </div>
          </section>

          {/* Image */}
          <section className="space-setup-page__section">
            <h2 style={{ color: colors.textPrimary }}>Image</h2>

            <div className="space-setup-page__form-group">
              <label style={{ color: colors.textPrimary }}>Image URL *</label>
              <input
                type="text"
                placeholder="https://example.com/image.jpg"
                style={{
                  backgroundColor: colors.bg,
                  color: colors.textPrimary,
                  borderColor: errors.imageUrl ? '#ff4757' : colors.borderColor,
                }}
                {...register('imageUrl')}
              />
              {errors.imageUrl && (
                <div className="space-setup-page__error">
                  {errors.imageUrl.message}
                </div>
              )}

              {imageUrl && (
                <div className="space-setup-page__image-preview">
                  <img
                    src={imageUrl}
                    alt="Preview"
                    onError={(e) => {
                      (e.target as HTMLImageElement).src =
                        'data:image/svg+xml,%3Csvg xmlns="http://www.w3.org/2000/svg" width="400" height="300"%3E%3Crect fill="%23ddd" width="400" height="300"/%3E%3C/svg%3E';
                    }}
                  />
                </div>
              )}
            </div>
          </section>

          {/* Amenities */}
          <section className="space-setup-page__section">
            <h2 style={{ color: colors.textPrimary }}>Amenities *</h2>
            {errors.amenities && (
              <div className="space-setup-page__error">
                {errors.amenities.message}
              </div>
            )}
            <div className="space-setup-page__amenities-grid">
              {amenitiesList.map((amenity) => (
                <button
                  key={amenity}
                  type="button"
                  className={`space-setup-page__amenity-btn ${
                    selectedAmenities.includes(amenity) ? 'active' : ''
                  }`}
                  onClick={() => toggleAmenity(amenity)}
                  style={{
                    backgroundColor: selectedAmenities.includes(amenity)
                      ? colors.adminAccent
                      : colors.surfaceVariant,
                    color: selectedAmenities.includes(amenity)
                      ? '#fff'
                      : colors.textSecondary,
                    borderColor: colors.borderColor,
                  }}
                >
                  {amenity}
                </button>
              ))}
            </div>
          </section>

          {/* Form Actions */}
          <div className="space-setup-page__form-actions">
            <button
              type="submit"
              className="space-setup-page__btn-submit"
              style={{
                backgroundColor: colors.adminAccent,
                color: '#fff',
              }}
            >
              Create Space
            </button>
            <button
              type="button"
              className="space-setup-page__btn-cancel"
              onClick={() => alert('Cancelled')}
              style={{
                borderColor: colors.borderColor,
                color: colors.textPrimary,
              }}
            >
              Cancel
            </button>
          </div>
        </form>
      </div>
    </div>
  );
};

export default SpaceSetupPage;
