import { isFavorite, getFavorites, toggleFavorite } from '../utils/storage.js';

// ---- PERFORMANCE SETTINGS (OPTIMIZED FOR LOWER END DEVICES) ----
const INITIAL_LOAD_COUNT = 50;
const BATCH_LOAD_COUNT = 40;
const SCROLL_THRESHOLD = 500; // Load more when within 500px of bottom

// State to keep track of rendering progress
let gridState = {
    channels: [],
    onPlay: null,
    renderedCount: 0,
    container: null,
    isInitial: true
};

let sidebarState = {
    channels: [],
    onPlay: null,
    renderedCount: 0,
    container: null,
    isInitial: true
};

// 🔥 BULLETPROOF FAVORITES COUNT UPDATE - ALL 6 locations
window.updateFavoritesCount = function () {
    const favorites = getFavorites();
    const elements = [
        document.getElementById('favoriteCount'),
        document.getElementById('sidebarStatFavorites'),
        document.getElementById('desktopStatFavorites'),
        document.querySelector('.desktop-stats .desktop-stat-item:last-child strong'),
        document.getElementById('favCount'),
        document.querySelector('.favorites-header .fav-count')
    ];

    elements.forEach(el => {
        if (el) el.textContent = favorites.length.toString();
    });
};

// 🔥 SAFE IMAGE ERROR HANDLER
window.handleImageError = function (img) {
    if (!img) return;
    img.style.display = 'none';
    const placeholder = img.parentElement.querySelector('.channel-placeholder');
    if (placeholder) placeholder.style.display = 'flex';
};

// 🔥 GLOBAL FAV SYNC - Updates PLAYER HEART + ALL COUNTS + GRIDS
window.syncAllFavorites = function (channelName) {
    // Update player heart button
    if (typeof window.updateFavoriteButton === 'function') {
        window.updateFavoriteButton();
    }

    // Update all counts
    if (typeof window.updateFavoritesCount === 'function') {
        window.updateFavoritesCount();
    }

    // Reload all grids sharing state
    if (window.state && window.playChannel) {
        renderFavoritesGrid(window.state.allChannels, window.playChannel);

        // Sync Sidebar (Crucial if favorites are toggled elsewhere)
        if (window.state.filteredChannels) {
            renderSidebarChannels(window.state.filteredChannels, window.playChannel);
            renderChannelGrid(window.state.filteredChannels, window.playChannel);
        }
    }
};

// Desktop channel grid (left side) - INCREMENTAL RENDER
export function renderChannelGrid(channels, onPlay) {
    const grid = document.getElementById('channelGrid');
    if (!grid) return;

    // Reset state for new list
    gridState.channels = channels;
    gridState.onPlay = onPlay;
    gridState.renderedCount = 0;
    gridState.container = grid;
    gridState.isInitial = true;

    grid.innerHTML = '';

    // Clean up previous listeners
    grid.onscroll = null;

    if (channels.length === 0) {
        grid.innerHTML = `
            <div class="empty-state">
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <circle cx="12" cy="12" r="10"></circle>
                    <line x1="12" y1="18" x2="12" y2="12"></line>
                    <line x1="12" y1="6" x2="12.01" y2="6"></line>
                </svg>
                <h3>No channels found</h3>
                <p>Try adjusting filters or region.</p>
            </div>
        `;
        return;
    }

    // Load first batch
    loadMoreGrid();

    // Attach scroll listener for infinite scroll
    grid.onscroll = () => {
        if (grid.scrollTop + grid.offsetHeight >= grid.scrollHeight - SCROLL_THRESHOLD) {
            loadMoreGrid();
        }
    };
}

function loadMoreGrid() {
    if (gridState.renderedCount >= gridState.channels.length) return;

    const start = gridState.renderedCount;
    const end = Math.min(start + (gridState.isInitial ? INITIAL_LOAD_COUNT : BATCH_LOAD_COUNT), gridState.channels.length);
    const batch = gridState.channels.slice(start, end);

    const fragment = document.createDocumentFragment();

    batch.forEach((ch, localIdx) => {
        const globalIdx = start + localIdx;
        const card = createChannelCard(ch, globalIdx, gridState.onPlay);
        fragment.appendChild(card);
    });

    gridState.container.appendChild(fragment);
    gridState.renderedCount = end;
    gridState.isInitial = false;
}

// Internal reusable card creator
function createChannelCard(ch, idx, onPlay) {
    const card = document.createElement('div');
    card.className = 'channel-card';
    card.setAttribute('data-channel-id', ch.id || '');
    card.setAttribute('data-idx', idx);

    const logoUrl = ch.logo || '';
    const hasLogo = logoUrl !== '';
    const favorite = isFavorite(ch.name);

    card.innerHTML = `
        <img class="channel-logo" loading="lazy" src="${logoUrl}" alt="${ch.name}" style="${hasLogo ? '' : 'display:none'}" onerror="window.handleImageError(this)">
        <div class="channel-placeholder" style="${hasLogo ? 'display:none' : 'display:flex'}">${ch.name?.[0] || 'TV'}</div>
        <div class="channel-info">
            <div class="channel-name">${ch.name}</div>
            <div class="channel-meta">
                <span class="channel-category">${(ch.category || 'General').split(';')[0].trim()}</span>
                ${ch.quality ? `<span class="quality-badge">${ch.quality}p</span>` : ''}
            </div>
        </div>
        <button class="channel-fav ${favorite ? 'fav-active' : ''}" data-name="${ch.name}">
            <svg class="fav-icon" viewBox="0 0 24 24" aria-hidden="true">
                <path d="M12.1 4.3c-1.7-1.8-4.6-1.8-6.3 0-1.7 1.8-1.7 4.7 0 6.5l6.2 6.4 6.2-6.4c1.7-1.8 1.7-4.7 0-6.5-1.7-1.8-4.6-1.8-6.3 0z"></path>
            </svg>
        </button>
    `;

    card.addEventListener('click', (e) => {
        const favBtn = card.querySelector('.channel-fav');
        if (favBtn && favBtn.contains(e.target)) return;
        if (onPlay) onPlay(ch, idx);
    });

    const favBtn = card.querySelector('.channel-fav');
    if (favBtn) {
        favBtn.addEventListener('click', (e) => {
            e.stopPropagation();
            toggleFavorite(ch);
            favBtn.classList.toggle('fav-active', isFavorite(ch.name));
            window.syncAllFavorites(ch.name);
        });
    }

    return card;
}

// 🔥 FIXED FAVORITES GRID - RENDERS DIRECTLY FROM STORAGE
export function renderFavoritesGrid(allChannels, onPlay) {
    const favGrid = document.getElementById('favoritesGrid');
    const favEmpty = document.getElementById('favoritesEmpty');
    const playerFavList = document.getElementById('playerFavList');

    const favorites = getFavorites();
    window.updateFavoritesCount();

    // 1. Render to main favorites grid (Mobile)
    if (favGrid) {
        if (favorites.length === 0) {
            if (favEmpty) favEmpty.style.display = 'block';
            favGrid.innerHTML = '';
        } else {
            if (favEmpty) favEmpty.style.display = 'none';
            favGrid.innerHTML = '';
            renderToGrid(favGrid, favorites, onPlay, 'favorite-card');
        }
    }

    // 2. Render to player favorites overlay (Desktop/Fullscreen)
    if (playerFavList) {
        playerFavList.innerHTML = '';
        if (favorites.length === 0) {
            playerFavList.innerHTML = '<div class="favorites-empty"><p>No favorites yet.</p></div>';
        } else {
            renderToGrid(playerFavList, favorites, onPlay, 'player-fav-item');
        }
    }
}

// Helper to render channel items to a container
function renderToGrid(container, channels, onPlay, className) {
    channels.forEach((ch, idx) => {
        const item = document.createElement('div');
        item.className = className;

        const logoUrl = ch.logo || '';
        const hasLogo = logoUrl !== '';

        if (className === 'player-fav-item') {
            item.innerHTML = `
                <div class="channel-logo">
                    <img src="${logoUrl}" alt="${ch.name}" style="${hasLogo ? '' : 'display:none'}" onerror="window.handleImageError(this)">
                    <div class="channel-placeholder" style="${hasLogo ? 'display:none' : 'display:flex'}">${ch.name?.[0] || 'TV'}</div>
                </div>
                <div class="info">
                    <div class="name">${ch.name}</div>
                    <div class="meta">${(ch.category || 'General').split(';')[0].trim()} ${ch.quality ? `• ${ch.quality}p` : ''}</div>
                </div>
            `;
        } else {
            // Original favorite-card style
            item.innerHTML = `
                <div class="channel-logo">
                    <img src="${logoUrl}" alt="${ch.name}" style="${hasLogo ? '' : 'display:none'}" onerror="window.handleImageError(this)">
                    <div class="channel-placeholder" style="${hasLogo ? 'display:none' : 'display:flex'}">${ch.name?.[0] || 'TV'}</div>
                </div>
                <div class="channel-info">
                    <div class="channel-title">${ch.name}</div>
                    <div class="channel-meta">
                        <span>${(ch.category || 'General').split(';')[0].trim()}</span>
                        ${ch.quality ? `<span>${ch.quality}p</span>` : ''}
                    </div>
                </div>
                <button class="channel-fav fav-active" data-name="${ch.name}">
                    <svg class="fav-icon" viewBox="0 0 24 24" aria-hidden="true">
                        <path d="M12.1 4.3c-1.7-1.8-4.6-1.8-6.3 0-1.7 1.8-1.7 4.7 0 6.5l6.2 6.4 6.2-6.4c1.7-1.8 1.7-4.7 0-6.5-1.7-1.8-4.6-1.8-6.3 0z"></path>
                    </svg>
                </button>
            `;
        }

        item.addEventListener('click', (e) => {
            const favBtn = item.querySelector('.channel-fav');
            if (favBtn && favBtn.contains(e.target)) return;
            if (onPlay) onPlay(ch, idx);

            // Close player overlay if open
            if (className === 'player-fav-item') {
                const overlay = document.getElementById('playerFavOverlay');
                if (overlay) overlay.classList.remove('show');
            }
        });

        const favBtn = item.querySelector('.channel-fav');
        if (favBtn) {
            favBtn.addEventListener('click', (e) => {
                e.stopPropagation();
                toggleFavorite(ch);
                window.syncAllFavorites(ch.name);
            });
        }

        container.appendChild(item);
    });
}

// Sidebar channel list rendering - INCREMENTAL RENDER
export function renderSidebarChannels(channels, onPlay) {
    const container = document.getElementById('sidebarChannels');
    if (!container) return;

    // Reset sidebar state
    sidebarState.channels = channels;
    sidebarState.onPlay = onPlay;
    sidebarState.renderedCount = 0;
    sidebarState.container = container;
    sidebarState.isInitial = true;

    container.innerHTML = '';
    container.onscroll = null;

    if (channels.length > 0) {
        loadMoreSidebar();

        container.onscroll = () => {
            if (container.scrollTop + container.offsetHeight >= container.scrollHeight - SCROLL_THRESHOLD) {
                loadMoreSidebar();
            }
        };
    }

    // Update sidebar channel count
    const sidebarChannelCount = document.getElementById('sidebarChannelCount');
    if (sidebarChannelCount) {
        sidebarChannelCount.textContent = channels.length.toString();
    }
}

function loadMoreSidebar() {
    if (sidebarState.renderedCount >= sidebarState.channels.length) return;

    const start = sidebarState.renderedCount;
    const end = Math.min(start + (sidebarState.isInitial ? INITIAL_LOAD_COUNT : BATCH_LOAD_COUNT), sidebarState.channels.length);
    const batch = sidebarState.channels.slice(start, end);

    const fragment = document.createDocumentFragment();

    batch.forEach((ch, localIdx) => {
        const globalIdx = start + localIdx;
        const card = createSidebarItem(ch, globalIdx, sidebarState.onPlay);
        fragment.appendChild(card);
    });

    sidebarState.container.appendChild(fragment);
    sidebarState.renderedCount = end;
    sidebarState.isInitial = false;
}

function createSidebarItem(ch, idx, onPlay) {
    const card = document.createElement('div');
    card.className = 'sidebar-channel';
    card.setAttribute('data-name', ch.name);
    card.setAttribute('data-category', ch.category || 'General');

    const logoUrl = ch.logo || '';
    const hasLogo = logoUrl !== '';
    const favorite = isFavorite(ch.name);
    const needsScroll = ch.name.length > 25;

    card.innerHTML = `
        <div class="channel-icon">
            <img loading="lazy" src="${logoUrl}" alt="${ch.name}" style="${hasLogo ? '' : 'display:none'}" onerror="window.handleImageError(this)">
            <div class="channel-placeholder" style="${hasLogo ? 'display:none' : 'display:flex'}">${ch.name?.[0] || 'TV'}</div>
        </div>
        <div class="channel-text">
            <div class="channel-name ${needsScroll ? 'scrolling' : ''}">
                ${needsScroll ? `<span class="channel-name-inner">${ch.name}</span>` : ch.name}
            </div>
            <div class="channel-meta">
                <span>${(ch.category || 'General').split(';')[0].trim()}</span>
                ${ch.quality ? `<span class="quality">${ch.quality}p</span>` : ''}
            </div>
        </div>
        <button class="channel-fav ${favorite ? 'fav-active' : ''}" data-name="${ch.name}">
            <svg class="fav-icon" viewBox="0 0 24 24" aria-hidden="true">
                <path d="M12.1 4.3c-1.7-1.8-4.6-1.8-6.3 0-1.7 1.8-1.7 4.7 0 6.5l6.2 6.4 6.2-6.4c1.7-1.8 1.7-4.7 0-6.5-1.7-1.8-4.6-1.8-6.3 0z"></path>
            </svg>
        </button>
    `;

    card.addEventListener('click', (e) => {
        const favBtn = card.querySelector('.channel-fav');
        if (favBtn && favBtn.contains(e.target)) return;
        if (onPlay) onPlay(ch, idx);
    });

    const favBtn = card.querySelector('.channel-fav');
    if (favBtn) {
        favBtn.addEventListener('click', (e) => {
            e.stopPropagation();
            toggleFavorite(ch);
            favBtn.classList.toggle('fav-active', isFavorite(ch.name));
            window.syncAllFavorites(ch.name);
        });
    }

    return card;
}
