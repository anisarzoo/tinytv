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
  const sidebar = document.getElementById('sidebar');

  if (!swipeTarget) return;

  const edgeLimit = 80;          // px from left edge to OPEN
  const swipeThreshold = 50;     // min distance to toggle
  const verticalThreshold = 60;  // max vertical drift

  let startX = 0;
  let startY = 0;
  let isSwiping = false;

  swipeTarget.addEventListener(
    'touchstart',
    (e) => {
      // Ignore if touch started inside video player (important for seeker/volume)
      if (videoContainer && videoContainer.contains(e.target)) return;

      startX = e.touches[0].clientX;
      startY = e.touches[0].clientY;
      isSwiping = true;
    },
    { passive: true }
  );

  let rafId = null;

  swipeTarget.addEventListener(
    'touchmove',
    (e) => {
      if (!isSwiping || !e.touches.length) return;
      if (videoContainer && videoContainer.contains(e.target)) return;

      const currentX = e.touches[0].clientX;
      const currentY = e.touches[0].clientY;
      const deltaX = currentX - startX;
      const deltaY = Math.abs(currentY - startY);

      // Only act on mostly horizontal swipe
      if (deltaY > Math.abs(deltaX)) return;

      const isOpen = sidebar && sidebar.classList.contains('open');

      // Cancel previous frame if it hasn't run yet
      if (rafId) cancelAnimationFrame(rafId);

      rafId = requestAnimationFrame(() => {
        if (!isOpen && deltaX > 0 && startX < edgeLimit) {
          // OPENING FEEDBACK: subtle push on content
          const progress = Math.min(deltaX / 100, 1);
          const content = document.querySelector('.content');
          if (content) {
            content.style.transform = `translateX(${progress * 30}px)`;
          }
        } else if (isOpen && deltaX < 0) {
          // CLOSING FEEDBACK: slide sidebar back slightly
          const progress = Math.min(Math.abs(deltaX) / 100, 1);
          if (sidebar) {
            sidebar.style.transform = `translateX(-${progress * 20}%)`;
          }
        }
      });
    },
    { passive: true }
  );

  swipeTarget.addEventListener(
    'touchend',
    (e) => {
      if (!isSwiping) return;
      if (rafId) cancelAnimationFrame(rafId);

      const endX = e.changedTouches[0].clientX;
      const endY = e.changedTouches[0].clientY;
      const deltaX = endX - startX;
      const deltaY = Math.abs(endY - startY);

      const isOpen = sidebar && sidebar.classList.contains('open');
      const content = document.querySelector('.content');

      // RESET STYLES
      if (content) content.style.transform = '';
      if (sidebar) sidebar.style.transform = '';

      // CHECK TRIGGER
      if (deltaY < verticalThreshold) {
        if (!isOpen && deltaX > swipeThreshold && startX < edgeLimit) {
          openSidebar();
        } else if (isOpen && deltaX < -swipeThreshold) {
          closeSidebar();
        }
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


