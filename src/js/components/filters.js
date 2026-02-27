// src/js/components/filters.js

import { isRegionalChannel, isProbablyOffline, getChannelScore } from '../utils/channelFilter.js';

let filterCallback;

export function initFilters(onChange) {
  filterCallback = onChange;

  // Desktop filter panel (OLD - now hidden)
  const filterBtn = document.getElementById('filterBtn');
  const closeFilter = document.getElementById('closeFilter');
  const filterPanel = document.getElementById('filterPanel');

  if (filterBtn) {
    filterBtn.addEventListener('click', () => {
      filterPanel.classList.add('open');
    });
  }

  if (closeFilter) {
    closeFilter.addEventListener('click', () => {
      filterPanel.classList.remove('open');
    });
  }

  // OLD Desktop filter inputs (in right panel - still works if present)
  const searchInput = document.getElementById('searchInput');
  if (searchInput) searchInput.addEventListener('input', handleFilterChange);

  const regionSelect = document.getElementById('regionSelect');
  if (regionSelect) regionSelect.addEventListener('change', handleRegionChange);

  const categorySelect = document.getElementById('categorySelect');
  if (categorySelect) categorySelect.addEventListener('change', handleFilterChange);

  const qualitySelect = document.getElementById('qualitySelect');
  if (qualitySelect) qualitySelect.addEventListener('change', handleFilterChange);

  const sortSelect = document.getElementById('sortSelect');
  if (sortSelect) sortSelect.addEventListener('change', handleFilterChange);

  const hideRegional = document.getElementById('hideRegional');
  if (hideRegional) hideRegional.addEventListener('change', handleFilterChange);

  const hideOffline = document.getElementById('hideOffline');
  if (hideOffline) hideOffline.addEventListener('change', handleFilterChange);

  const favoritesOnly = document.getElementById('favoritesOnly');
  if (favoritesOnly) favoritesOnly.addEventListener('change', handleFilterChange);

  // === NEW DESKTOP FILTERS (integrated in left panel) ===

  // Toggle filter section open/close
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

  // Mobile sidebar filter inputs
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

  // Sidebar search input should also trigger filtering
  const sidebarSearchInput = document.getElementById('sidebarSearchInput');
  if (sidebarSearchInput) sidebarSearchInput.addEventListener('input', handleFilterChange);

  // Update filter stats initially
  updateFilterStats();
}

function handleFilterChange() {
  if (typeof filterCallback === 'function') {
    filterCallback();
  }
}

export function applyFilters(channels) {
  // Get values from desktop (new left panel), old desktop panel, or sidebar
  const isMobile = window.innerWidth < 768;

  // Search input priority: new desktop > old desktop > sidebar
  const desktopNewSearchInput = document.getElementById('desktopSearchInput');
  const desktopOldSearchInput = document.getElementById('searchInput');
  const sidebarSearchInput = document.getElementById('sidebarSearchInput');

  const search = (
    isMobile
      ? (sidebarSearchInput?.value || '')
      : (desktopNewSearchInput?.value || desktopOldSearchInput?.value || '')
  ).toLowerCase();

  // Category: new desktop > old desktop > sidebar
  const category = isMobile
    ? document.getElementById('sidebarCategorySelect')?.value || ''
    : document.getElementById('desktopCategorySelect')?.value || 
      document.getElementById('categorySelect')?.value || '';

  // Quality: new desktop > old desktop > sidebar
  const quality = isMobile
    ? document.getElementById('sidebarQualitySelect')?.value || 'all'
    : document.getElementById('desktopQualitySelect')?.value || 
      document.getElementById('qualitySelect')?.value || 'all';

  // Sort: new desktop > old desktop > sidebar
  const sort = isMobile
    ? document.getElementById('sidebarSortSelect')?.value || 'smart'
    : document.getElementById('desktopSortSelect')?.value || 
      document.getElementById('sortSelect')?.value || 'smart';

  // Hide regional: new desktop > old desktop > sidebar
  const hideRegional = isMobile
    ? document.getElementById('sidebarHideRegional')?.checked || false
    : document.getElementById('desktopHideRegional')?.checked || 
      document.getElementById('hideRegional')?.checked || false;

  // Hide offline: new desktop > old desktop > sidebar
  const hideOffline = isMobile
    ? document.getElementById('sidebarHideOffline')?.checked || false
    : document.getElementById('desktopHideOffline')?.checked || 
      document.getElementById('hideOffline')?.checked || false;

  // Favorites only (no new desktop control for this yet)
  const favoritesOnly = isMobile
    ? document.getElementById('sidebarFavoritesOnly')?.checked || false
    : document.getElementById('favoritesOnly')?.checked || false;

  let filtered = [...channels];

  // Search filter
  if (search) {
    filtered = filtered.filter(ch =>
      ch.name.toLowerCase().includes(search) ||
      (ch.category || '').toLowerCase().includes(search)
    );
  }

  // Category filter
  if (category) {
    filtered = filtered.filter(ch => ch.category === category);
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

  // Favorites only
  if (favoritesOnly) {
    const favorites = JSON.parse(localStorage.getItem('tivy_favorites') || '[]');
    filtered = filtered.filter(ch =>
      favorites.some(f => f.id === ch.id)
    );
  }

  // Sort with smart scoring
  filtered.sort((a, b) => {
    if (sort === 'name') return a.name.localeCompare(b.name);
    if (sort === 'quality') return b.quality - a.quality;
    if (sort === 'category') return a.category.localeCompare(b.category);
    if (sort === 'smart') {
      return getChannelScore(b) - getChannelScore(a);
    }
    return 0;
  });

  // Update categories dropdown (all three: new desktop, old desktop, sidebar)
  updateCategories(channels);

  // Update all stats
  updateFilterStats(filtered.length);

  return filtered;
}

function updateCategories(channels) {
  const categories = [...new Set(channels.map(ch => ch.category))].sort();

  // Update OLD desktop category select
  const categorySelect = document.getElementById('categorySelect');
  if (categorySelect) {
    const currentValue = categorySelect.value;
    categorySelect.innerHTML = '<option value="">All Categories</option>';
    categories.forEach(cat => {
      const option = document.createElement('option');
      option.value = cat;
      option.textContent = cat;
      categorySelect.appendChild(option);
    });
    categorySelect.value = currentValue;
  }

  // Update NEW desktop category select (in left panel)
  const desktopCategorySelect = document.getElementById('desktopCategorySelect');
  if (desktopCategorySelect) {
    const currentValue = desktopCategorySelect.value;
    desktopCategorySelect.innerHTML = '<option value="">All Categories</option>';
    categories.forEach(cat => {
      const option = document.createElement('option');
      option.value = cat;
      option.textContent = cat;
      desktopCategorySelect.appendChild(option);
    });
    desktopCategorySelect.value = currentValue;
  }

  // Update sidebar category select
  const sidebarCategorySelect = document.getElementById('sidebarCategorySelect');
  if (sidebarCategorySelect) {
    const currentValue = sidebarCategorySelect.value;
    sidebarCategorySelect.innerHTML = '<option value="">All Categories</option>';
    categories.forEach(cat => {
      const option = document.createElement('option');
      option.value = cat;
      option.textContent = cat;
      sidebarCategorySelect.appendChild(option);
    });
    sidebarCategorySelect.value = currentValue;
  }
}

function updateFilterStats(count) {
  const favorites = JSON.parse(localStorage.getItem('tivy_favorites') || '[]');

  // OLD Desktop stats (right panel)
  const channelCount = document.getElementById('channelCount');
  if (channelCount && count !== undefined) {
    channelCount.textContent = count.toString();
  }

  const favoriteCount = document.getElementById('favoriteCount');
  if (favoriteCount) {
    favoriteCount.textContent = favorites.length.toString();
  }

  // NEW Desktop stats (left panel)
  const desktopStatChannels = document.getElementById('desktopStatChannels');
  if (desktopStatChannels && count !== undefined) {
    desktopStatChannels.textContent = count.toString();
  }

  const desktopStatFavorites = document.getElementById('desktopStatFavorites');
  if (desktopStatFavorites) {
    desktopStatFavorites.textContent = favorites.length.toString();
  }

  // Sidebar stats (cards in filter section)
  const sidebarStatChannels = document.getElementById('sidebarStatChannels');
  if (sidebarStatChannels && count !== undefined) {
    sidebarStatChannels.textContent = count.toString();
  }

  const sidebarStatFavorites = document.getElementById('sidebarStatFavorites');
  if (sidebarStatFavorites) {
    sidebarStatFavorites.textContent = favorites.length.toString();
  }

  // Top sidebar header "X channels"
  const sidebarHeaderCount = document.getElementById('sidebarChannelCount');
  if (sidebarHeaderCount && count !== undefined) {
    sidebarHeaderCount.textContent = count.toString();
  }
}

// OLD Desktop region change (right panel)
async function handleRegionChange(e) {
  const region = e.target.value;
  if (window.loadChannels) {
    document.getElementById('filterPanel')?.classList.remove('open');
    await window.loadChannels(region === 'ALL' ? null : region);
  }
}

// NEW Desktop region change (left panel)
async function handleDesktopRegionChange(e) {
  const region = e.target.value;
  if (window.loadChannels) {
    // Sync with old desktop select if present
    const oldDesktopSelect = document.getElementById('regionSelect');
    if (oldDesktopSelect) oldDesktopSelect.value = region;

    // Sync with sidebar select
    const sidebarSelect = document.getElementById('sidebarRegionSelect');
    if (sidebarSelect) sidebarSelect.value = region;

    await window.loadChannels(region === 'ALL' ? null : region);
  }
}

// Sidebar region change: sync with both desktop panels
async function handleSidebarRegionChange(e) {
  const region = e.target.value;
  if (window.loadChannels) {
    const desktopSelect = document.getElementById('regionSelect');
    if (desktopSelect) desktopSelect.value = region;

    const newDesktopSelect = document.getElementById('desktopRegionSelect');
    if (newDesktopSelect) newDesktopSelect.value = region;

    await window.loadChannels(region === 'ALL' ? null : region);
  }
}