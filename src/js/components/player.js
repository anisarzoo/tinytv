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

  // Reset pause flag on new channel
  userPaused = false;

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
        availableLevels = data.levels;
        setupQualitySelector(data.levels);

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

function setupQualitySelector(levels) {
  const qualityBtn = document.getElementById('qualityBtn');
  const modal = document.getElementById('qualityModal');
  const optionsContainer = document.getElementById('qualityOptions');

  if (!qualityBtn || !modal || !optionsContainer) return;

  optionsContainer.innerHTML = '';

  // Add Auto option
  const autoBtn = document.createElement('button');
  autoBtn.className = 'quality-option';
  autoBtn.textContent = 'Auto (Recommended)';
  autoBtn.onclick = () => {
    if (hls) {
      hls.currentLevel = -1;
      qualityBtn.textContent = 'Auto';
      showToast('Quality: Auto');
    }
    modal.style.display = 'none';
  };
  optionsContainer.appendChild(autoBtn);

  // Add quality levels
  levels.forEach((level, index) => {
    const btn = document.createElement('button');
    btn.className = 'quality-option';
    const resolution = level.height || 'Unknown';
    btn.textContent = `${resolution}p`;
    btn.onclick = () => {
      if (hls) {
        hls.currentLevel = index;
        qualityBtn.textContent = `${resolution}p`;
        showToast(`Quality: ${resolution}p`);
      }
      modal.style.display = 'none';
    };
    optionsContainer.appendChild(btn);
  });

  qualityBtn.textContent = 'Auto';
  qualityBtn.onclick = () => {
    modal.style.display = 'flex';
  };
  modal.onclick = (e) => {
    if (e.target === modal) modal.style.display = 'none';
  };
}

function setupBasicQualityOptions() {
  const qualityBtn = document.getElementById('qualityBtn');
  if (!qualityBtn) return;
  qualityBtn.textContent = 'Auto';
  qualityBtn.onclick = () => {
    showToast('Quality control adapts automatically for this stream');
  };
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
