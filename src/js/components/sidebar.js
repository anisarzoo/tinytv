// src/js/components/sidebar.js


export function initSidebar() {
  const menuBtn = document.getElementById('menuBtn');
  const closeSidebarBtn = document.getElementById('closeSidebar');
  const overlay = document.getElementById('overlay');

  if (menuBtn) {
    menuBtn.onclick = openSidebar;
  }

  if (closeSidebarBtn) {
    closeSidebarBtn.onclick = closeSidebar;
  }

  if (overlay) {
    overlay.onclick = closeSidebar;
  }

  // Toggle filter dropdown in sidebar
  const sidebarFilterToggle = document.getElementById('sidebarFilterToggle');
  const sidebarFiltersContent = document.getElementById('sidebarFiltersContent');

  if (sidebarFilterToggle && sidebarFiltersContent) {
    sidebarFilterToggle.addEventListener('click', () => {
      sidebarFiltersContent.classList.toggle('open');
      const icon = sidebarFilterToggle.querySelector('.dropdown-icon');
      if (icon) {
        icon.style.transform = sidebarFiltersContent.classList.contains('open')
          ? 'rotate(180deg)'
          : 'rotate(0deg)';
      }
    });
  }

  // Sidebar search functionality:
  // now only updates the input; real filtering is done in filters.js via handleFilterChange
  const sidebarSearchInput = document.getElementById('sidebarSearchInput');
  if (sidebarSearchInput) {
    sidebarSearchInput.addEventListener('input', () => {
      // filters.js listens to this input and recomputes state.filteredChannels
      // No DOM-level filtering here to avoid desync
    });
  }

  // Mobile swipe gesture support
  initSwipeGesture();
}

// UPDATED: swipe works on whole screen except video player
// and is easier to trigger (wider edge, shorter distance, more vertical tolerance)
function initSwipeGesture() {
  const swipeTarget = document.body;
  const videoContainer = document.getElementById('videoContainer');

  if (!swipeTarget) return;

  const edgeLimit = 80;          // px from left edge
  const swipeThreshold = 40;     // min horizontal distance
  const verticalThreshold = 50;  // max vertical drift

  let startX = 0;
  let startY = 0;
  let isSwiping = false;

  swipeTarget.addEventListener(
    'touchstart',
    (e) => {
      // Ignore if touch started inside video player
      if (videoContainer && videoContainer.contains(e.target)) return;

      startX = e.touches[0].clientX;
      startY = e.touches[0].clientY;
      isSwiping = true;
    },
    { passive: true }
  );

  swipeTarget.addEventListener(
    'touchmove',
    (e) => {
      if (!isSwiping || !e.touches.length) return;

      // Ignore moves inside player
      if (videoContainer && videoContainer.contains(e.target)) return;

      const currentX = e.touches[0].clientX;
      const currentY = e.touches[0].clientY;
      const deltaX = currentX - startX;
      const deltaY = Math.abs(currentY - startY);

      // Only act on mostly horizontal swipe, starting near left edge
      if (deltaY < Math.abs(deltaX) && deltaX > 0 && startX < edgeLimit) {
        const progress = Math.min(deltaX / 100, 1);
        const content = document.querySelector('.content');
        if (content) {
          content.style.transform = `translateX(${progress * 30}px)`;
        }
      }
    },
    { passive: true }
  );

  swipeTarget.addEventListener(
    'touchend',
    (e) => {
      if (!isSwiping) return;

      // Ignore if touch ended inside player
      if (videoContainer && videoContainer.contains(e.target)) {
        isSwiping = false;
        return;
      }

      const endX = e.changedTouches[0].clientX;
      const endY = e.changedTouches[0].clientY;
      const deltaX = endX - startX;
      const deltaY = Math.abs(endY - startY);

      const content = document.querySelector('.content');
      if (content) {
        content.style.transform = '';
      }

      // Valid left-to-right swipe from left edge
      if (deltaX > swipeThreshold && deltaY < verticalThreshold && startX < edgeLimit) {
        openSidebar();
      }

      isSwiping = false;
    },
    { passive: true }
  );
}

function openSidebar() {
  const sidebar = document.getElementById('sidebar');
  const overlay = document.getElementById('overlay');

  if (sidebar) sidebar.classList.add('open');
  if (overlay) overlay.classList.add('show');
}

function closeSidebar() {
  const sidebar = document.getElementById('sidebar');
  const overlay = document.getElementById('overlay');

  if (sidebar) sidebar.classList.remove('open');
  if (overlay) overlay.classList.remove('show');
}


