// src/js/app.js

import { initPlayer, loadStream } from './components/player.js';
import { renderChannelGrid, renderSidebarChannels, renderFavoritesGrid } from './components/channelgrid.js';
import { initSidebar } from './components/sidebar.js';
import { initFilters, applyFilters } from './components/filters.js';
import { initControls, showChannelOverlay } from './components/controls.js';
import { showToast, getTheme, toggleTheme } from './utils/storage.js';
import { parseM3U } from './utils/m3uparser.js';

// Global State
export const state = {
    allChannels: [],
    filteredChannels: [],
    currentChannel: null,
    currentIndex: 0,
    isDesktop: window.innerWidth >= 768
};

// Prev / Next handlers
function handlePrev() {
    const newIndex = state.currentIndex - 1;
    if (newIndex >= 0) {
        playChannel(state.filteredChannels[newIndex], newIndex);
    } else {
        showToast('Already at first channel');
    }
}

function handleNext() {
    const newIndex = state.currentIndex + 1;
    if (newIndex < state.filteredChannels.length) {
        playChannel(state.filteredChannels[newIndex], newIndex);
    } else {
        showToast('Already at last channel');
    }
}

// App init
export async function initApp() {
    console.log('Tivy: Starting app init...');
    // Apply theme
    document.body.className = getTheme();

    // Initialize components
    initPlayer();
    initSidebar();
    initFilters(handleFilterChange);
    initControls(handlePrev, handleNext);

    // Event listeners
    setupEventListeners();

    // Load initial channels
    console.log('Tivy: Fetching channels...');
    loadChannels('IN').finally(() => {
        console.log('Tivy: Load sequence finished');
        removeSplash();
    });

    // Fail-safe: Hide splash after 5s regardless
    setTimeout(() => {
        console.log('Tivy: Fail-safe timeout triggered');
        removeSplash();
    }, 5000);

    // Handle resize
    window.addEventListener('resize', handleResize);
}

function removeSplash() {
    const splash = document.getElementById('splash');
    const app = document.getElementById('app');

    if (splash && !splash.classList.contains('hide')) {
        console.log('Tivy: Hiding splash screen...');
        splash.classList.add('hide');
        if (app) {
            app.style.setProperty('display', 'flex', 'important');
            app.style.visibility = 'visible';
            app.style.opacity = '1';
        }

        // Remove from DOM after transition
        setTimeout(() => {
            splash.remove();
        }, 800);
    }
}

// Theme + player overlay events
function setupEventListeners() {
    const themeBtn = document.getElementById('themeBtn');
    if (themeBtn) {
        themeBtn.onclick = () => {
            toggleTheme();
            document.body.className = getTheme();
            showToast('Theme changed');
        };
    }

    // Show controls on touch/mouse move
    const videoContainer = document.getElementById('videoContainer');
    if (!videoContainer) return;

    let hideTimeout;
    const showControls = () => {
        const topBar = document.getElementById('topBar');
        const bottomBar = document.getElementById('bottomBar');
        if (topBar) topBar.classList.add('show');
        if (bottomBar) bottomBar.classList.add('show');

        clearTimeout(hideTimeout);
        hideTimeout = setTimeout(() => {
            const video = document.getElementById('video');
            if (!video || video.paused) return;
            if (topBar) topBar.classList.remove('show');
            if (bottomBar) bottomBar.classList.remove('show');
        }, 3000);
    };

    videoContainer.addEventListener('touchstart', showControls);
    videoContainer.addEventListener('mousemove', showControls);
    videoContainer.addEventListener('click', showControls);
}

// Fetch and parse IPTV playlists
async function loadChannels(region) {
    console.log(`Tivy: Loading channels for ${region}...`);
    showToast('Loading channels...');
    try {
        let text = '';
        if (!region || region === 'ALL') {
            const url = 'https://iptv-org.github.io/iptv/index.m3u';
            const response = await fetch(url);
            text = await response.text();
            state.allChannels = parseM3U(text, 'ALL');
        } else {
            const url = `https://iptv-org.github.io/iptv/countries/${region.toLowerCase()}.m3u`;
            const response = await fetch(url);
            text = await response.text();
            state.allChannels = parseM3U(text, region);
        }

        console.log(`Tivy: Successfully parsed ${state.allChannels.length} channels`);
        // Apply filters + render
        handleFilterChange();
        showToast(`${state.allChannels.length} channels loaded`);

        // 🔥 AUTO-PLAY RANDOM CHANNEL ON STARTUP
        if (state.filteredChannels.length > 0 && !state.currentChannel) {
            console.log('Tivy: Auto-playing random channel...');
            const randomIndex = Math.floor(Math.random() * Math.min(state.filteredChannels.length, 20));
            playChannel(state.filteredChannels[randomIndex], randomIndex);
        }
    } catch (error) {
        console.error('Tivy: Load error:', error);
        showToast('Failed to load channels', 'error');
    }
}

// When filters change
function handleFilterChange() {
    state.filteredChannels = applyFilters(state.allChannels);
    renderChannels();
    updateStats();
}

// UNIFIED rendering - favorites work same way on both mobile and desktop
function renderChannels() {
    // Desktop: show channel grid on left
    if (state.isDesktop) {
        renderChannelGrid(state.filteredChannels, playChannel);
    }

    // UNIFIED: Render favorites below video (both mobile and desktop)
    renderFavoritesGrid(state.allChannels, playChannel);

    // Sidebar list (hamburger menu) in all modes
    renderSidebarChannels(state.filteredChannels, playChannel);
}

// Stats in filter panel
function updateStats() {
    const channelCount = document.getElementById('channelCount');
    if (channelCount) {
        channelCount.textContent = `${state.filteredChannels.length}`;
    }
}

// Play channel and update UI
export function playChannel(channel, index) {
    if (!channel) return;

    // FALLBACK: If channel has no URL (old favorites), look it up in master list
    if (!channel.url && channel.name) {
        const found = state.allChannels.find(c => c.name === channel.name);
        if (found) {
            channel = found;
        }
    }

    state.currentChannel = channel;
    state.currentIndex = index;
    loadStream(channel);
    showChannelOverlay(channel); // updates heart state in player

    // Update active states in desktop/mobile lists
    document.querySelectorAll('.channel-card').forEach((card, i) => {
        card.classList.toggle('active', i === index);
    });
    document.querySelectorAll('.favorite-card').forEach((card, i) => {
        card.classList.toggle('active', i === index);
    });

    // Close sidebar + filter panel on mobile
    if (!state.isDesktop) {
        const sidebar = document.getElementById('sidebar');
        const overlay = document.getElementById('overlay');
        const filterPanel = document.getElementById('filterPanel');
        if (sidebar) sidebar.classList.remove('open');
        if (overlay) overlay.classList.remove('show');
        if (filterPanel) filterPanel.classList.remove('open');
    }
}

// Handle breakpoint switch
function handleResize() {
    const wasDesktop = state.isDesktop;
    state.isDesktop = window.innerWidth >= 768;
    if (wasDesktop !== state.isDesktop) {
        renderChannels();
    }
}

// Expose for filters and HTML
window.loadChannels = loadChannels;
window.handleFilterChange = handleFilterChange;
window.state = state;
window.playChannel = playChannel;

// Handle broken channel logos gracefully
window.handleImageError = function (img) {
    img.style.display = 'none';
    const placeholder = img.nextElementSibling;
    if (placeholder && placeholder.classList.contains('channel-placeholder')) {
        placeholder.style.display = 'flex';
    }
};