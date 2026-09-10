// src/js/components/filters.js

import { isRegionalChannel, isProbablyOffline, getChannelScore } from '../utils/channelfilter.js';
import { initAllDropdowns } from '../utils/dropdown.js';

let filterCallback;

export function initFilters(onChange) {
  filterCallback = onChange;

  // === DESKTOP FILTERS (integrated in left panel) ===
  const desktopFilterToggle = document.getElementById('desktopFilterToggle');
  const desktopFiltersContent = document.getElementById('desktopFiltersContent');
  if (desktopFilterToggle && desktopFiltersContent) {
    desktopFilterToggle.addEventListener('click', () => {
      desktopFiltersContent.classList.toggle('open');
      desktopFilterToggle.classList.toggle('open');
    });
  }

  // Desktop search (in left panel)
  const desktopSearchInput = document.getElementById('desktopSearchInput');
  if (desktopSearchInput) desktopSearchInput.addEventListener('input', handleFilterChange);

  // Desktop region select (in left panel)
  const desktopRegionSelect = document.getElementById('desktopRegionSelect');
  if (desktopRegionSelect) desktopRegionSelect.addEventListener('change', handleDesktopRegionChange);

  // Desktop category select (in left panel)
  const desktopCategorySelect = document.getElementById('desktopCategorySelect');
  if (desktopCategorySelect) desktopCategorySelect.addEventListener('change', handleFilterChange);

  // Desktop quality select (in left panel)
  const desktopQualitySelect = document.getElementById('desktopQualitySelect');
  if (desktopQualitySelect) desktopQualitySelect.addEventListener('change', handleFilterChange);

  // Desktop sort select (in left panel)
  const desktopSortSelect = document.getElementById('desktopSortSelect');
  if (desktopSortSelect) desktopSortSelect.addEventListener('change', handleFilterChange);

  // Desktop hide regional checkbox (in left panel)
  const desktopHideRegional = document.getElementById('desktopHideRegional');
  if (desktopHideRegional) desktopHideRegional.addEventListener('change', handleFilterChange);

  // Desktop hide offline checkbox (in left panel)
  const desktopHideOffline = document.getElementById('desktopHideOffline');
  if (desktopHideOffline) desktopHideOffline.addEventListener('change', handleFilterChange);

  // Desktop favorites only checkbox (in left panel)
  const desktopFavoritesOnly = document.getElementById('desktopFavoritesOnly');
  if (desktopFavoritesOnly) desktopFavoritesOnly.addEventListener('change', handleFilterChange);

  // === MOBILE SIDEBAR FILTERS ===
  const sidebarRegionSelect = document.getElementById('sidebarRegionSelect');
  if (sidebarRegionSelect) sidebarRegionSelect.addEventListener('change', handleSidebarRegionChange);

  const sidebarCategorySelect = document.getElementById('sidebarCategorySelect');
  if (sidebarCategorySelect) sidebarCategorySelect.addEventListener('change', handleFilterChange);

  const sidebarQualitySelect = document.getElementById('sidebarQualitySelect');
  if (sidebarQualitySelect) sidebarQualitySelect.addEventListener('change', handleFilterChange);

  const sidebarSortSelect = document.getElementById('sidebarSortSelect');
  if (sidebarSortSelect) sidebarSortSelect.addEventListener('change', handleFilterChange);

  const sidebarHideRegional = document.getElementById('sidebarHideRegional');
  if (sidebarHideRegional) sidebarHideRegional.addEventListener('change', handleFilterChange);

  const sidebarHideOffline = document.getElementById('sidebarHideOffline');
  if (sidebarHideOffline) sidebarHideOffline.addEventListener('change', handleFilterChange);

  const sidebarFavoritesOnly = document.getElementById('sidebarFavoritesOnly');
  if (sidebarFavoritesOnly) sidebarFavoritesOnly.addEventListener('change', handleFilterChange);

  // Sidebar search input
  const sidebarSearchInput = document.getElementById('sidebarSearchInput');
  if (sidebarSearchInput) sidebarSearchInput.addEventListener('input', handleFilterChange);

  // Initialize custom dropdowns
  initAllDropdowns();

  // Update filter stats initially
  updateFilterStats();
}

function handleFilterChange(e) {
  // Sync checkboxes across desktop and sidebar
  if (e && e.target && e.target.type === 'checkbox') {
    const isChecked = e.target.checked;
    const id = e.target.id;

    if (id.includes('HideRegional')) {
      const el1 = document.getElementById('sidebarHideRegional');
      const el2 = document.getElementById('desktopHideRegional');
      if (el1) el1.checked = isChecked;
      if (el2) el2.checked = isChecked;
    }

    if (id.includes('HideOffline')) {
      const el1 = document.getElementById('sidebarHideOffline');
      const el2 = document.getElementById('desktopHideOffline');
      if (el1) el1.checked = isChecked;
      if (el2) el2.checked = isChecked;
    }

    if (id.includes('FavoritesOnly')) {
      const el1 = document.getElementById('sidebarFavoritesOnly');
      const el2 = document.getElementById('desktopFavoritesOnly');
      if (el1) el1.checked = isChecked;
      if (el2) el2.checked = isChecked;
    }
  }

  if (typeof filterCallback === 'function') {
    filterCallback();
  }
}

export function applyFilters(channels) {
  const isMobile = window.innerWidth < 768;

  const desktopSearchInput = document.getElementById('desktopSearchInput');
  const sidebarSearchInput = document.getElementById('sidebarSearchInput');
  const search = (isMobile ? (sidebarSearchInput?.value || '') : (desktopSearchInput?.value || '')).toLowerCase().trim();

  const category = (isMobile
    ? document.getElementById('sidebarCategorySelect')?.value
    : document.getElementById('desktopCategorySelect')?.value) || '';

  const quality = (isMobile
    ? document.getElementById('sidebarQualitySelect')?.value
    : document.getElementById('desktopQualitySelect')?.value) || 'all';

  const sort = (isMobile
    ? document.getElementById('sidebarSortSelect')?.value
    : document.getElementById('desktopSortSelect')?.value) || 'smart';

  const hideRegional = (isMobile
    ? document.getElementById('sidebarHideRegional')?.checked
    : document.getElementById('desktopHideRegional')?.checked) ?? false;

  const hideOffline = (isMobile
    ? document.getElementById('sidebarHideOffline')?.checked
    : document.getElementById('desktopHideOffline')?.checked) ?? false;

  const favoritesOnly = (isMobile
    ? document.getElementById('sidebarFavoritesOnly')?.checked
    : document.getElementById('desktopFavoritesOnly')?.checked) ?? false;

  let filtered = [...channels];

  // Search filter
  if (search) {
    filtered = filtered.filter(ch =>
      (ch.name || '').toLowerCase().includes(search) ||
      (ch.category || '').toLowerCase().includes(search)
    );
  }

  // Category filter
  if (category) {
    filtered = filtered.filter(ch => {
      if (!ch.category) return false;
      const cats = ch.category.split(';').map(c => c.trim());
      return cats.includes(category);
    });
  }

  // Quality filter
  if (quality === 'hd') {
    filtered = filtered.filter(ch => ch.quality >= 720);
  } else if (quality === 'fhd') {
    filtered = filtered.filter(ch => ch.quality >= 1080);
  }

  // Hide regional channels
  if (hideRegional) {
    filtered = filtered.filter(ch => !isRegionalChannel(ch));
  }

  // Hide potentially offline channels
  if (hideOffline) {
    filtered = filtered.filter(ch => !isProbablyOffline(ch));
  }

  // Favorites only - match by channel name
  if (favoritesOnly) {
    const favorites = JSON.parse(localStorage.getItem('tivy_favorites') || '[]');
    const favNames = new Set(favorites.map(f => f.name));
    filtered = filtered.filter(ch => favNames.has(ch.name));
  }

  // Sort with smart scoring
  filtered.sort((a, b) => {
    if (sort === 'name') return (a.name || '').localeCompare(b.name || '');
    if (sort === 'quality') return (b.quality || 0) - (a.quality || 0);
    if (sort === 'category') return (a.category || '').localeCompare(b.category || '');
    if (sort === 'smart') {
      return getChannelScore(b) - getChannelScore(a);
    }
    return 0;
  });

  // Update categories dropdown
  updateCategories(channels);

  // Update all stats
  updateFilterStats(filtered.length);

  return filtered;
}

function updateCategories(channels) {
  const allCats = [];
  channels.forEach(ch => {
    if (ch.category) {
      ch.category.split(';').forEach(c => {
        const trimmed = c.trim();
        if (trimmed) allCats.push(trimmed);
      });
    }
  });
  const categories = [...new Set(allCats)].sort();

  // Update desktop category select
  const desktopCategorySelect = document.getElementById('desktopCategorySelect');
  if (desktopCategorySelect) {
    const currentValue = desktopCategorySelect.value;
    desktopCategorySelect.innerHTML = '<option value="">All</option>';
    categories.forEach(cat => {
      const option = document.createElement('option');
      option.value = cat;
      option.textContent = cat;
      desktopCategorySelect.appendChild(option);
    });
    desktopCategorySelect.value = currentValue;
    if (desktopCategorySelect._tivyDropdown) desktopCategorySelect._tivyDropdown.update();
  }

  // Update sidebar category select
  const sidebarCategorySelect = document.getElementById('sidebarCategorySelect');
  if (sidebarCategorySelect) {
    const currentValue = sidebarCategorySelect.value;
    sidebarCategorySelect.innerHTML = '<option value="">All</option>';
    categories.forEach(cat => {
      const option = document.createElement('option');
      option.value = cat;
      option.textContent = cat;
      sidebarCategorySelect.appendChild(option);
    });
    sidebarCategorySelect.value = currentValue;
    if (sidebarCategorySelect._tivyDropdown) sidebarCategorySelect._tivyDropdown.update();
  }
}

function updateFilterStats(count) {
  const favorites = JSON.parse(localStorage.getItem('tivy_favorites') || '[]');

  // Desktop stats (left panel)
  const desktopStatChannels = document.getElementById('desktopStatChannels');
  if (desktopStatChannels && count !== undefined) {
    desktopStatChannels.textContent = count.toString();
  }

  const desktopStatFavorites = document.getElementById('desktopStatFavorites');
  if (desktopStatFavorites) {
    desktopStatFavorites.textContent = favorites.length.toString();
  }

  // Sidebar stats
  const sidebarStatChannels = document.getElementById('sidebarStatChannels');
  if (sidebarStatChannels && count !== undefined) {
    sidebarStatChannels.textContent = count.toString();
  }

  const sidebarStatFavorites = document.getElementById('sidebarStatFavorites');
  if (sidebarStatFavorites) {
    sidebarStatFavorites.textContent = favorites.length.toString();
  }

  // Top sidebar header count
  const sidebarHeaderCount = document.getElementById('sidebarChannelCount');
  if (sidebarHeaderCount && count !== undefined) {
    sidebarHeaderCount.textContent = count.toString();
  }
}

// Desktop region change (left panel)
async function handleDesktopRegionChange(e) {
  const region = e.target.value;
  if (window.loadChannels) {
    const sidebarSelect = document.getElementById('sidebarRegionSelect');
    if (sidebarSelect) {
      sidebarSelect.value = region;
      if (sidebarSelect._tivyDropdown) sidebarSelect._tivyDropdown.update();
    }
    await window.loadChannels(region === 'ALL' ? null : region);
  }
}

// Sidebar region change
async function handleSidebarRegionChange(e) {
  const region = e.target.value;
  if (window.loadChannels) {
    const desktopSelect = document.getElementById('desktopRegionSelect');
    if (desktopSelect) {
      desktopSelect.value = region;
      if (desktopSelect._tivyDropdown) desktopSelect._tivyDropdown.update();
    }
    await window.loadChannels(region === 'ALL' ? null : region);
  }
}