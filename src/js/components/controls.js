// src/js/components/controls.js

import { showToast, toggleFavorite, isFavorite } from '../utils/storage.js';

export function initControls(onPrev, onNext) {
  const video = document.getElementById('video');
  const volumeSlider = document.getElementById('volumeSlider');
  const centerPlayBtn = document.getElementById('centerPlayBtn');
  const videoContainer = document.getElementById('videoContainer');
  const progressBar = document.getElementById('progressBar');
  const progressFill = document.getElementById('progressFill');

  // Play / Pause toggle
  window.togglePlayPause = () => {
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
  };

  // Volume + mute
  window.toggleMute = () => {
    video.muted = !video.muted;
    updateVolumeIcon(video.muted);
    if (volumeSlider) {
      volumeSlider.value = video.muted ? 0 : video.volume * 100;
      updateVolumeTrail(volumeSlider.value);
    }
  };

  if (volumeSlider) {
    volumeSlider.addEventListener('input', (e) => {
      const value = e.target.value;
      video.volume = value / 100;
      video.muted = value == 0;
      updateVolumeIcon(video.muted);
      updateVolumeTrail(value);
    });

    // FIXED: Initialize volume slider gradient on load
    const initialVolume = video.volume * 100 || 100;
    volumeSlider.value = initialVolume;
    updateVolumeTrail(initialVolume);
  }

  // Keep controls + center play in sync
  video.addEventListener('play', () => {
    updatePlayButton(false);
    if (centerPlayBtn) centerPlayBtn.style.display = 'none';
  });

  video.addEventListener('pause', () => {
    updatePlayButton(true);
    if (centerPlayBtn) centerPlayBtn.style.display = 'flex';
  });

  video.addEventListener('ended', () => {
    if (onNext) onNext();
  });

  video.addEventListener('error', (e) => {
    console.error('Video error:', e);
    showToast('Failed to load stream', 'error');
  });

  // === PROGRESS / SEEK ===
  video.addEventListener('timeupdate', () => {
    if (!video.duration || isNaN(video.duration) || !progressFill) return;
    const percent = (video.currentTime / video.duration) * 100;
    progressFill.style.width = `${percent}%`;
  });

  let isSeeking = false;
  const seek = (clientX) => {
    if (!video.duration || isNaN(video.duration)) return;
    const rect = progressBar.getBoundingClientRect();
    const x = Math.min(Math.max(clientX - rect.left, 0), rect.width);
    const percent = x / rect.width;
    video.currentTime = percent * video.duration;
    if (progressFill) progressFill.style.width = `${percent * 100}%`;
  };

  if (progressBar && progressFill) {
    progressBar.addEventListener('mousedown', (e) => {
      isSeeking = true;
      seek(e.clientX);
    });

    window.addEventListener('mousemove', (e) => {
      if (isSeeking) seek(e.clientX);
    });

    window.addEventListener('mouseup', () => {
      isSeeking = false;
    });

    progressBar.addEventListener('touchstart', (e) => {
      isSeeking = true;
      seek(e.touches[0].clientX);
    }, { passive: true });

    window.addEventListener('touchmove', (e) => {
      if (isSeeking) seek(e.touches[0].clientX);
    }, { passive: true });

    window.addEventListener('touchend', () => {
      isSeeking = false;
    });
  }

  // === FULLSCREEN ===
  window.toggleFullscreen = () => {
    if (!document.fullscreenElement) {
      videoContainer.requestFullscreen().catch(err => {
        console.error('Fullscreen error:', err);
      });
    } else {
      document.exitFullscreen();
    }
  };

  // NEW: Double-click video to toggle fullscreen
  let lastClickTime = 0;
  const doubleClickDelay = 300; // ms

  videoContainer.addEventListener('click', (e) => {
    const currentTime = new Date().getTime();
    const timeDiff = currentTime - lastClickTime;

    if (timeDiff < doubleClickDelay && timeDiff > 0) {
      // Double-click detected
      window.toggleFullscreen();
      e.preventDefault();
      e.stopPropagation();
    }

    lastClickTime = currentTime;
  });

  // Alternative: Use native dblclick event (more reliable)
  videoContainer.addEventListener('dblclick', (e) => {
    window.toggleFullscreen();
    e.preventDefault();
    e.stopPropagation();
  });

  // Prev / Next
  window.handlePrevChannel = onPrev;
  window.handleNextChannel = onNext;

  // Favorite (heart) from player
  window.toggleFavoriteBtn = () => {
    if (!window.currentChannel) return;
    toggleFavorite(window.currentChannel);
    updateFavoriteButton();
    if (window.handleFilterChange) {
      window.handleFilterChange();
    }
  };

  // Quality modal
  window.showQualityModal = () => {
    const modal = document.getElementById('qualityModal');
    const options = document.getElementById('qualityOptions');
    if (modal && options) {
      options.innerHTML = `
        <div class="quality-option" onclick="setQuality('auto')">Auto (Recommended)</div>
        <div class="quality-option" onclick="setQuality('1080p')">1080p Full HD</div>
        <div class="quality-option" onclick="setQuality('720p')">720p HD</div>
        <div class="quality-option" onclick="setQuality('480p')">480p SD</div>
      `;
      modal.style.display = 'flex';
      modal.onclick = (e) => {
        if (e.target === modal) modal.style.display = 'none';
      };
    }
  };

  window.setQuality = (quality) => {
    const modal = document.getElementById('qualityModal');
    const qualityBtn = document.getElementById('qualityBtn');
    if (qualityBtn) qualityBtn.textContent = quality === 'auto' ? 'Auto' : quality;
    if (modal) modal.style.display = 'none';
  };

  // Volume slider gradient trail - FIXED
  function updateVolumeTrail(value) {
    const slider = document.getElementById('volumeSlider');
    if (!slider) return;
    const percentage = value;
    slider.style.background = `linear-gradient(to right,
      #f43f5e 0%,
      #ec4899 ${percentage}%,
      rgba(148,163,184,0.4) ${percentage}%,
      rgba(148,163,184,0.4) 100%)`;
  }

  // Update play / pause icons
  function updatePlayButton(paused) {
    const playIcon = document.querySelector('.play-icon');
    const pauseIcon = document.querySelector('.pause-icon');
    if (!playIcon || !pauseIcon) return;
    if (paused) {
      playIcon.style.display = 'block';
      pauseIcon.style.display = 'none';
    } else {
      playIcon.style.display = 'none';
      pauseIcon.style.display = 'block';
    }
  }

  // Volume icon (muted vs normal)
  function updateVolumeIcon(muted) {
    const volumeIcon = document.querySelector('.volume-icon');
    if (!volumeIcon) return;
    if (muted) {
      volumeIcon.innerHTML = `<polygon points="11 5 6 9 2 9 2 15 6 15 11 19 11 5"></polygon><line x1="23" y1="9" x2="17" y2="15"></line><line x1="17" y1="9" x2="23" y2="15"></line>`;
    } else {
      volumeIcon.innerHTML = `<polygon points="11 5 6 9 2 9 2 15 6 15 11 19 11 5"></polygon><path d="M19.07 4.93a10 10 0 0 1 0 14.14M15.54 8.46a5 5 0 0 1 0 7.07"></path>`;
    }
  }

  // Update player heart
  function updateFavoriteButton() {
    if (!window.currentChannel) return;
    const favBtn = document.getElementById('favBtn');
    if (!favBtn) return;
    const fav = isFavorite(window.currentChannel.name);
    favBtn.classList.toggle('fav-active', fav);
  }

  // Expose for grid buttons
  window.toggleFavoriteFromGrid = function (channel) {
    toggleFavorite(channel);
    if (window.handleFilterChange) {
      window.handleFilterChange();
    }
    if (window.updateFavoriteButton) {
      window.updateFavoriteButton();
    }
  };

  window.updateFavoriteButton = updateFavoriteButton;
}

// Called when channel changes
export function showChannelOverlay(channel) {
  const channelTitle = document.getElementById('channelTitle');
  const channelMeta = document.getElementById('channelMeta');

  if (channelTitle) channelTitle.textContent = channel.name;
  if (channelMeta) {
    const q = channel.quality;
    const qualityLabel = q >= 720 ? `${q}p` : 'SD';
    const cat = (channel.category || 'General').split(';')[0].trim();
    channelMeta.textContent = `${cat} • ${qualityLabel}`;
  }

  window.currentChannel = channel;

  // Refresh heart in player
  const favBtn = document.getElementById('favBtn');
  if (favBtn) {
    const fav = isFavorite(channel.name);
    favBtn.classList.toggle('fav-active', fav);
  }
}
