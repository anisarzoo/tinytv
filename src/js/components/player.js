import { showToast } from '../utils/storage.js';

let video, hls;
let currentChannel;
let availableLevels = [];
let isDestroying = false;
let userPaused = false; // Track manual pause

export function initPlayer() {
  video = document.getElementById('video');

  video.addEventListener('play', () => {
    userPaused = false; // User resumed playback
    const centerPlayBtn = document.getElementById('centerPlayBtn');
    if (centerPlayBtn) centerPlayBtn.style.display = 'none';
    hideLoading();
  });

  video.addEventListener('pause', () => {
    userPaused = true; // User manually paused
    const centerPlayBtn = document.getElementById('centerPlayBtn');
    if (centerPlayBtn) centerPlayBtn.style.display = 'flex';
  });

  video.addEventListener('waiting', showLoading);
  video.addEventListener('canplay', hideLoading);

  // Update quality options as soon as stream video dimensions become available
  video.addEventListener('loadedmetadata', () => {
    if (availableLevels && availableLevels.length <= 1) {
      setupQualitySelector(availableLevels);
    }
  });

  video.addEventListener('resize', () => {
    if (availableLevels && availableLevels.length <= 1) {
      setupQualitySelector(availableLevels);
    }
  });

  video.addEventListener('error', () => {
    hideLoading();
    showToast('Stream error. Try another channel.', 'error');
  });

  // Click video to play/pause
  video.addEventListener('click', () => {
    togglePlayPause();
  });

  // Setup default quality options on init
  setupBasicQualityOptions();

  setupPlayerFavOverlay();

  // Dismiss quality menu on outside click or Escape
  const qualityMenuEl = document.getElementById('qualityMenu');
  if (qualityMenuEl) {
    qualityMenuEl.addEventListener('touchstart', (e) => {
      e.stopPropagation();
    }, { passive: true });
    qualityMenuEl.addEventListener('touchmove', (e) => {
      e.stopPropagation();
    }, { passive: true });
    qualityMenuEl.addEventListener('wheel', (e) => {
      e.stopPropagation();
    }, { passive: true });
  }

  document.addEventListener('click', (e) => {
    const menu = document.getElementById('qualityMenu');
    if (!menu || !menu.classList.contains('show')) return;
    const btnBottom = document.getElementById('qualityBtn');
    const btnTop = document.getElementById('qualityBtnTop');
    if (menu.contains(e.target) || (btnBottom && btnBottom.contains(e.target)) || (btnTop && btnTop.contains(e.target))) {
      return;
    }
    closeQualityMenu();
  });

  document.addEventListener('keydown', (e) => {
    if (e.key === 'Escape') {
      closeQualityMenu();
    }
  });
}

function setupPlayerFavOverlay() {
  const menuBtn = document.getElementById('playerFavMenuBtn');
  const overlay = document.getElementById('playerFavOverlay');
  const closeBtn = document.getElementById('closePlayerFav');

  if (menuBtn && overlay) {
    menuBtn.addEventListener('click', (e) => {
      e.stopPropagation();
      overlay.classList.toggle('show');

      // Re-render favorites to ensure current active channel is matched
      if (overlay.classList.contains('show') && typeof window.state !== 'undefined') {
        import('./channelgrid.js').then(({ renderFavoritesGrid }) => {
          renderFavoritesGrid(window.state.allChannels, window.playChannel);
        });
      }
    });
  }

  if (closeBtn && overlay) {
    closeBtn.addEventListener('click', (e) => {
      e.stopPropagation();
      overlay.classList.remove('show');
    });
  }

  // Close on click outside the overlay (but inside video container)
  const videoContainer = document.getElementById('videoContainer');
  if (videoContainer && overlay) {
    videoContainer.addEventListener('click', (e) => {
      if (!overlay.contains(e.target) && overlay.classList.contains('show')) {
        overlay.classList.remove('show');
      }
    });
  }
}

export function loadStream(channel) {
  currentChannel = channel;
  showLoading(channel);

  // Reset pause flag on new channel and close quality popover
  userPaused = false;
  currentQualityIndex = -1;
  closeQualityMenu();

  // OPTIMIZATION 1: Abort previous video load immediately
  if (video && !video.paused) {
    video.pause();
  }
  if (video) {
    video.removeAttribute('src');
    video.load(); // Clear buffer fast
  }

  // OPTIMIZATION 2: Fast HLS cleanup (non-blocking)
  if (hls && !isDestroying) {
    isDestroying = true;
    try {
      hls.stopLoad(); // Stop network requests immediately
      hls.detachMedia();
      hls.destroy();
    } catch (e) {
      console.warn('HLS cleanup:', e);
    }
    hls = null;
    isDestroying = false;
  }

  if (!channel || !channel.url) {
    hideLoading();
    showToast('Channel link is missing or broken.', 'error');
    return;
  }

  if (channel.url.includes('.m3u8')) {
    if (typeof Hls !== 'undefined' && Hls.isSupported()) {
      // OPTIMIZATION 3: Aggressive HLS config for instant loading
      hls = new Hls({
        enableWorker: true,
        lowLatencyMode: false,

        // FAST LOADING - Reduce initial buffer
        maxBufferLength: 10,        // Was 30 → Less buffering = faster start
        maxMaxBufferLength: 20,     // Was 60 → Quick channel switch
        maxBufferSize: 10 * 1000 * 1000, // 10MB buffer max
        maxBufferHole: 0.5,         // Fill gaps faster

        // INSTANT START
        startLevel: -1,             // Auto quality
        autoStartLoad: true,        // Start loading immediately
        startFragPrefetch: true,    // Prefetch first segment

        // FAST MANIFEST
        manifestLoadingTimeOut: 5000,     // Was 10000
        manifestLoadingMaxRetry: 1,       // Was 3 - fail fast
        manifestLoadingRetryDelay: 500,   // Was 1000

        // FAST FRAGMENTS
        fragLoadingTimeOut: 10000,        // Was 20000
        fragLoadingMaxRetry: 2,           // Was 6 - fail fast
        fragLoadingRetryDelay: 500,       // Quick retry

        // AGGRESSIVE ABR (Adaptive Bitrate)
        abrEwmaDefaultEstimate: 500000,   // Start with lower quality = faster
        abrBandWidthFactor: 0.8,          // Conservative bandwidth estimate
        abrBandWidthUpFactor: 0.6,        // Quick quality upgrade
        abrMaxWithRealBitrate: true,

        // FAST SEEKING
        liveSyncDurationCount: 2,         // Was 3
        liveMaxLatencyDurationCount: 5,   // Was 10

        // NETWORK OPTIMIZATION
        xhrSetup: function (xhr, url) {
          xhr.timeout = 8000; // 8s timeout for fast failure
        }
      });

      hls.loadSource(channel.url);
      hls.attachMedia(video);

      // Only auto-play on FIRST fragment, not every fragment
      let hasPlayed = false;
      hls.on(Hls.Events.FRAG_BUFFERED, () => {
        if (!hasPlayed && video.paused && video.readyState >= 2 && !userPaused) {
          hasPlayed = true;
          video.play().catch(e => console.log('Auto-play prevented:', e));
        }
      });

      hls.on(Hls.Events.MANIFEST_PARSED, (event, data) => {
        availableLevels = data.levels || [];
        setupQualitySelector(availableLevels);

        // Force play immediately
        const playPromise = video.play();
        if (playPromise !== undefined) {
          playPromise.catch(err => {
            if (err.name !== 'AbortError') {
              console.log('Play prevented:', err);
            }
          });
        }
      });

      hls.on(Hls.Events.LEVEL_LOADED, () => {
        if (hls && hls.levels && hls.levels.length > 0) {
          availableLevels = hls.levels;
          if (availableLevels.length <= 1) {
            setupQualitySelector(availableLevels);
          }
        }
      });

      hls.on(Hls.Events.ERROR, (event, data) => {
        if (data.fatal) {
          hideLoading();
          switch (data.type) {
            case Hls.ErrorTypes.NETWORK_ERROR:
              console.error('Network or CORS error:', data);
              showToast(`${currentChannel?.name || 'Channel'} stream restricted. Skipping to next...`, 'warning');
              if (window.handleNextChannel) {
                setTimeout(window.handleNextChannel, 1500);
              }
              break;
            case Hls.ErrorTypes.MEDIA_ERROR:
              console.error('Media error, trying to recover...');
              hls.recoverMediaError();
              break;
            default:
              console.error('Fatal error, cannot recover');
              hls.destroy();
              break;
          }
        }
      });

    } else if (video.canPlayType('application/vnd.apple.mpegurl')) {
      // Native HLS (Safari/iOS) - Already optimized
      video.src = channel.url;
      video.load();
      video.play().catch(e => console.log('Native HLS play prevented:', e));
      setupBasicQualityOptions();
    }
  } else {
    // OPTIMIZATION 5: Direct video (MP4, etc.)
    video.src = channel.url;
    video.load();
    video.play().catch(e => console.log('Direct video play prevented:', e));
    setupBasicQualityOptions();
  }
}

export function togglePlayPause() {
  if (!video) return;
  if (video.paused) {
    const playPromise = video.play();
    if (playPromise !== undefined) {
      playPromise.catch(err => {
        if (err.name !== 'AbortError') {
          console.log('Play prevented:', err);
        }
      });
    }
  } else {
    video.pause();
  }
}

export function seekVideo(seconds) {
  if (video) video.currentTime += seconds;
}

let currentQualityIndex = -1;

export function closeQualityMenu() {
  const menu = document.getElementById('qualityMenu');
  const btnBottom = document.getElementById('qualityBtn');
  const btnTop = document.getElementById('qualityBtnTop');
  if (menu) menu.classList.remove('show');
  if (btnBottom) btnBottom.setAttribute('aria-expanded', 'false');
  if (btnTop) btnTop.setAttribute('aria-expanded', 'false');
}

export function toggleQualityMenu(e) {
  if (e) {
    e.stopPropagation();
    e.preventDefault();
  }
  const menu = document.getElementById('qualityMenu');
  const btnBottom = document.getElementById('qualityBtn');
  const btnTop = document.getElementById('qualityBtnTop');
  if (!menu) return;
  const isOpen = menu.classList.toggle('show');
  if (btnBottom) btnBottom.setAttribute('aria-expanded', isOpen ? 'true' : 'false');
  if (btnTop) btnTop.setAttribute('aria-expanded', isOpen ? 'true' : 'false');
  if (isOpen) {
    const activeBtn = menu.querySelector('.quality-option-btn.active');
    if (activeBtn) {
      activeBtn.scrollIntoView({ block: 'nearest' });
    }
  }
}

function getLevelDetails(lvl, originalIndex, totalLevels) {
  let height = (lvl && lvl.height) ? lvl.height : 0;

  // 1. Check attrs.RESOLUTION (e.g. "1280x720")
  if (!height && lvl && lvl.attrs && lvl.attrs.RESOLUTION) {
    const parts = String(lvl.attrs.RESOLUTION).toLowerCase().split('x');
    if (parts.length === 2) {
      const parsed = parseInt(parts[1], 10);
      if (!isNaN(parsed) && parsed > 0) height = parsed;
    }
  }

  // 2. Check lvl.name (e.g. "720p", "1080p")
  if (!height && lvl && lvl.name) {
    const match = String(lvl.name).match(/(\d{3,4})p?/i);
    if (match) {
      const parsed = parseInt(match[1], 10);
      if (!isNaN(parsed) && parsed > 0) height = parsed;
    }
  }

  // 3. Check HTML5 video element dimensions if height is still 0
  if (!height && video && video.videoHeight > 0 && totalLevels <= 1) {
    height = video.videoHeight;
  }

  if (height > 0) {
    return {
      height,
      label: `${height}p`,
      badge: height >= 720 ? 'HD' : ''
    };
  }

  // 4. Bitrate estimation fallback if available
  if (lvl && lvl.bitrate && lvl.bitrate > 0) {
    const kbps = Math.round(lvl.bitrate / 1000);
    if (kbps >= 3500) return { height: 1080, label: '1080p', badge: 'HD' };
    if (kbps >= 2000) return { height: 720, label: '720p', badge: 'HD' };
    if (kbps >= 800) return { height: 480, label: '480p', badge: '' };
    return { height: 0, label: `${kbps} kbps`, badge: '' };
  }

  // 5. If multiple levels exist without resolution metadata
  if (totalLevels > 1) {
    const tierNames = ['High Quality', 'Medium Quality', 'Standard Quality', 'Low Quality'];
    const label = tierNames[originalIndex] || `Option ${originalIndex + 1}`;
    return { height: 0, label, badge: originalIndex === 0 ? 'HQ' : '' };
  }

  // 6. Single stream with unknown metadata
  return { height: 0, label: 'Source', badge: '' };
}

function setupQualitySelector(levels) {
  const qualityBtn = document.getElementById('qualityBtn');
  const qualityBtnTop = document.getElementById('qualityBtnTop');
  const menu = document.getElementById('qualityMenu');
  const optionsContainer = document.getElementById('qualityOptions');

  if (!menu || !optionsContainer) return;

  optionsContainer.innerHTML = '';

  const renderOption = (label, index, isAuto = false, badgeText = '') => {
    const btn = document.createElement('button');
    btn.className = 'quality-option-btn' + (currentQualityIndex === index ? ' active' : '');
    btn.type = 'button';
    btn.setAttribute('role', 'menuitem');

    const badgeHtml = badgeText ? `<span class="quality-option-badge">${badgeText}</span>` : '';

    btn.innerHTML = `
      <span class="quality-option-check">
        <svg viewBox="0 0 24 24" width="11" height="11" fill="none" stroke="currentColor" stroke-width="2.8" stroke-linecap="round" stroke-linejoin="round">
          <polyline points="20 6 9 17 4 12"></polyline>
        </svg>
      </span>
      <span class="quality-option-label">${label}</span>
      ${badgeHtml}
    `;

    btn.onclick = (e) => {
      e.stopPropagation();
      currentQualityIndex = index;
      if (hls) {
        hls.currentLevel = index;
      }
      const titleLabel = isAuto ? 'Auto' : label;
      const titleText = `Quality: ${titleLabel}`;
      if (qualityBtn) qualityBtn.title = titleText;
      if (qualityBtnTop) qualityBtnTop.title = titleText;
      showToast(`Quality: ${titleLabel}`);

      optionsContainer.querySelectorAll('.quality-option-btn').forEach(b => b.classList.remove('active'));
      btn.classList.add('active');

      closeQualityMenu();
    };

    optionsContainer.appendChild(btn);
  };

  // Always show "Auto" as first option
  renderOption('Auto', -1, true);

  const validLevels = (levels && levels.length > 0) ? levels : [];

  if (validLevels.length > 0) {
    // Map and sort levels descending by height / bitrate
    const mapped = validLevels.map((lvl, idx) => ({
      lvl,
      originalIndex: idx,
      details: getLevelDetails(lvl, idx, validLevels.length)
    }));

    mapped.sort((a, b) => (b.details.height || b.lvl.bitrate || 0) - (a.details.height || a.lvl.bitrate || 0));

    mapped.forEach(({ originalIndex, details }) => {
      renderOption(details.label, originalIndex, false, details.badge);
    });
  } else {
    // If no levels manifest yet, show detected video resolution
    const h = (video && video.videoHeight > 0) ? video.videoHeight : 1080;
    renderOption(`${h}p`, 0, false, h >= 720 ? 'HD' : '');
  }

  const defaultTitle = currentQualityIndex === -1 ? 'Quality: Auto' : (qualityBtn ? qualityBtn.title : 'Quality Settings');
  if (qualityBtn) {
    qualityBtn.title = defaultTitle;
    qualityBtn.onclick = toggleQualityMenu;
  }
  if (qualityBtnTop) {
    qualityBtnTop.title = defaultTitle;
    qualityBtnTop.onclick = toggleQualityMenu;
  }
}

function setupBasicQualityOptions() {
  const qualityBtn = document.getElementById('qualityBtn');
  const qualityBtnTop = document.getElementById('qualityBtnTop');
  const optionsContainer = document.getElementById('qualityOptions');

  if (qualityBtn) qualityBtn.title = 'Quality: Auto';
  if (qualityBtnTop) qualityBtnTop.title = 'Quality: Auto';

  if (optionsContainer) {
    const height = (video && video.videoHeight > 0) ? `${video.videoHeight}p` : '1080p';
    const isHD = !video || video.videoHeight >= 720;
    optionsContainer.innerHTML = `
      <button class="quality-option-btn active" type="button" role="menuitem">
        <span class="quality-option-check">
          <svg viewBox="0 0 24 24" width="11" height="11" fill="none" stroke="currentColor" stroke-width="2.8" stroke-linecap="round" stroke-linejoin="round">
            <polyline points="20 6 9 17 4 12"></polyline>
          </svg>
        </span>
        <span class="quality-option-label">Auto</span>
      </button>
      <button class="quality-option-btn" type="button" role="menuitem">
        <span class="quality-option-check">
          <svg viewBox="0 0 24 24" width="11" height="11" fill="none" stroke="currentColor" stroke-width="2.8" stroke-linecap="round" stroke-linejoin="round">
            <polyline points="20 6 9 17 4 12"></polyline>
          </svg>
        </span>
        <span class="quality-option-label">${height}</span>
        ${isHD ? '<span class="quality-option-badge">HD</span>' : ''}
      </button>
    `;
    const btns = optionsContainer.querySelectorAll('.quality-option-btn');
    if (btns[0]) btns[0].onclick = (e) => { e.stopPropagation(); closeQualityMenu(); };
    if (btns[1]) btns[1].onclick = (e) => { e.stopPropagation(); closeQualityMenu(); };
  }
  if (qualityBtn) qualityBtn.onclick = toggleQualityMenu;
  if (qualityBtnTop) qualityBtnTop.onclick = toggleQualityMenu;
}

function showLoading(possibleChannel) {
  const overlay = document.getElementById('videoLoading');
  const logo = document.getElementById('loadingLogo');
  const placeholder = document.getElementById('loadingPlaceholder');
  const nameEl = document.getElementById('loadingChannelName');

  if (!overlay) return;

  // If called via event listener, the first argument is an Event, not the channel.
  const channel = (possibleChannel && typeof possibleChannel.name === 'string')
    ? possibleChannel
    : currentChannel;

  if (channel) {
    if (nameEl) nameEl.textContent = channel.name;
    if (logo && placeholder) {
      if (channel.logo) {
        logo.src = channel.logo;
        logo.style.display = 'block';
        placeholder.style.display = 'none';
      } else {
        logo.style.display = 'none';
        placeholder.textContent = channel.name[0] || 'TV';
        placeholder.style.display = 'flex';
      }
    }
  }

  overlay.style.display = 'flex';
  overlay.style.opacity = '1';
}

function hideLoading() {
  const overlay = document.getElementById('videoLoading');
  if (!overlay) return;
  overlay.style.opacity = '0';
  setTimeout(() => {
    overlay.style.display = 'none';
  }, 500);
}

// Expose globally for HTML/controls compatibility
window.togglePlayPause = togglePlayPause;
