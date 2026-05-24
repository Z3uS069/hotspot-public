import React from 'react';
import QRCode from 'qrcode.react';
import { useDarkMode } from '@/hooks';
import { getThemeColors } from '@/utils/theme';
import { sampleSpaces } from '@/data/fixtures';
import './MyQRCodePage.css';

// ─────────────────────────────────────────────────────────────────────────────
// MY QR CODE PAGE
// (Replaces lib/pages/my_qr_code_page.dart)
//
// Shows:
// - QR codes for user spaces
// - Download/share functionality
// - QR code management
// ─────────────────────────────────────────────────────────────────────────────

const MyQRCodePage: React.FC = () => {
  const { isDarkMode } = useDarkMode();
  const colors = getThemeColors(isDarkMode);

  const qrCodeRef = React.useRef<HTMLDivElement>(null);

  const handleDownloadQR = (spaceName: string) => {
    if (qrCodeRef.current) {
      const element = qrCodeRef.current.querySelector('canvas');
      if (element) {
        const link = document.createElement('a');
        link.href = element.toDataURL('image/png');
        link.download = `${spaceName}-qrcode.png`;
        link.click();
      }
    }
  };

  return (
    <div className="my-qr-code-page" style={{ backgroundColor: colors.bg, color: colors.textPrimary }}>
      {/* Header */}
      <div
        className="my-qr-code-page__header"
        style={{
          backgroundColor: colors.cardBg,
          borderColor: colors.borderColor,
        }}
      >
        <h1>My QR Codes</h1>
        <p style={{ color: colors.textSecondary }}>
          Generate and manage QR codes for your spaces
        </p>
      </div>

      {/* Content */}
      <div className="my-qr-code-page__content">
        <div className="my-qr-code-page__grid">
          {sampleSpaces.map((space) => (
            <div
              key={space.id}
              className="my-qr-code-page__card"
              style={{
                backgroundColor: colors.cardBg,
                borderColor: colors.borderColor,
              }}
            >
              {/* Space Info */}
              <div className="my-qr-code-page__space-info">
                <h3 style={{ color: colors.textPrimary, margin: '0 0 0.5rem 0' }}>
                  {space.name}
                </h3>
                <p
                  style={{
                    color: colors.textSecondary,
                    fontSize: '0.85rem',
                    margin: 0,
                  }}
                >
                  📍 {space.address}
                </p>
              </div>

              {/* QR Code */}
              <div
                className="my-qr-code-page__qr-container"
                ref={qrCodeRef}
              >
                <QRCode
                  value={`hotspot://space/${space.id}`}
                  size={150}
                  level="H"
                  includeMargin={true}
                  fgColor={isDarkMode ? '#ffffff' : '#000000'}
                  bgColor={isDarkMode ? '#152238' : '#ffffff'}
                />
              </div>

              {/* Actions */}
              <div className="my-qr-code-page__actions">
                <button
                  className="my-qr-code-page__btn-download"
                  onClick={() => handleDownloadQR(space.name)}
                  style={{
                    backgroundColor: '#00C9A7',
                    color: '#0B1426',
                  }}
                >
                  ⬇️ Download
                </button>
                <button
                  className="my-qr-code-page__btn-share"
                  onClick={() => alert(`Sharing QR code for ${space.name}`)}
                  style={{
                    borderColor: colors.borderColor,
                    color: colors.textPrimary,
                  }}
                >
                  📤 Share
                </button>
              </div>

              {/* Stats */}
              <div
                className="my-qr-code-page__stats"
                style={{ borderColor: colors.borderColor }}
              >
                <div>
                  <div style={{ color: colors.textMuted, fontSize: '0.8rem' }}>
                    Scans
                  </div>
                  <div style={{ color: colors.textPrimary, fontWeight: 700 }}>
                    {Math.floor(Math.random() * 500) + 50}
                  </div>
                </div>
                <div>
                  <div style={{ color: colors.textMuted, fontSize: '0.8rem' }}>
                    Views
                  </div>
                  <div style={{ color: colors.textPrimary, fontWeight: 700 }}>
                    {Math.floor(Math.random() * 1000) + 200}
                  </div>
                </div>
              </div>
            </div>
          ))}
        </div>

        {/* Instructions */}
        <section
          className="my-qr-code-page__instructions"
          style={{
            backgroundColor: colors.cardBg,
            borderColor: colors.borderColor,
          }}
        >
          <h2 style={{ color: colors.textPrimary }}>How to Use QR Codes</h2>
          <ol style={{ color: colors.textSecondary, lineHeight: 1.8 }}>
            <li>Generate QR codes for each of your spaces above</li>
            <li>Download and print the QR codes</li>
            <li>Place them at your space entrance or on signage</li>
            <li>Users can scan to quickly access your space details</li>
            <li>Track scans and views in the analytics</li>
          </ol>
        </section>
      </div>
    </div>
  );
};

export default MyQRCodePage;
