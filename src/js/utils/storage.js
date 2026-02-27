// src/utils/storage.js

const THEME_KEY = 'tivy_theme';
const FAVORITES_KEY = 'tivy_favorites';

// Theme functions
export function getTheme() {
    return localStorage.getItem(THEME_KEY) || 'dark';
}

export function toggleTheme() {
    const current = getTheme();
    const newTheme = current === 'dark' ? 'light' : 'dark';
    localStorage.setItem(THEME_KEY, newTheme);
    return newTheme;
}

// Favorites functions
export function getFavorites() {
    return JSON.parse(localStorage.getItem(FAVORITES_KEY) || '[]');
}

export function saveFavorites(favorites) {
    localStorage.setItem(FAVORITES_KEY, JSON.stringify(favorites));
}

export function isFavorite(channelName) {
    const favorites = getFavorites();
    return favorites.some(f => f.name === channelName);
}

/**
 * Toggle favorite for a channel.
 * Always store a normalized object so player + grids stay in sync.
 */
export function toggleFavorite(channel) {
    const favorites = getFavorites();
    const name = typeof channel === 'string' ? channel : channel.name;
    const index = favorites.findIndex(f => f.name === name);

    if (index > -1) {
        favorites.splice(index, 1);
        showToast('Removed from favorites');
    } else {
        const normalized =
            typeof channel === 'string'
                ? { name }
                : {
                      name: channel.name,
                      logo: channel.logo || '',
                      category: channel.category || 'General',
                      quality: channel.quality || '720p',
                      country: channel.country || channel.region || ''
                  };
        favorites.push(normalized);
        showToast('Added to favorites');
    }

    saveFavorites(favorites);
    return index === -1; // true if added, false if removed
}

// Toast notification
export function showToast(message, type = 'info') {
    const toast = document.getElementById('toast');
    if (!toast) return;

    toast.textContent = message;
    toast.className = `toast ${type} show`;

    setTimeout(() => {
        toast.classList.remove('show');
    }, 3000);
}

// Expose globally for HTML onclick handlers
window.toggleFavorite = toggleFavorite;
window.isFavorite = isFavorite;
window.getFavorites = getFavorites;