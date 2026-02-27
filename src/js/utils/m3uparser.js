export function parseM3U(content, region) {
  const lines = content.split('\n');
  const channelMap = new Map();
  let current = {};

  for (let i = 0; i < lines.length; i++) {
    const line = lines[i].trim();

    if (line.startsWith('#EXTINF:')) {
      const rawName = line.match(/,(.+)$/)?.[1]?.trim() || 'Unknown';
      const logo = line.match(/tvg-logo="([^"]+)"/)?.[1] || '';
      const category = line.match(/group-title="([^"]+)"/)?.[1] || 'General';
      const tvgId = line.match(/tvg-id="([^"]+)"/)?.[1] || '';
      const quality = extractQuality(rawName);

      const cleanedName = cleanChannelName(rawName);

      // Skip clearly broken / UA-like entries
      if (isGarbageName(cleanedName)) {
        continue;
      }

      current = {
        name: cleanedName || 'Unknown',
        logo,
        category,
        region,
        quality,
        tvgId
      };
    } else if (line && !line.startsWith('#')) {
      // URL line
      if (!current.name) continue;

      current.url = line;
      current.id = `${region}_${channelMap.size}_${Date.now()}`;

      // DEDUPLICATION: Keep only the highest quality version of the channel
      const existing = channelMap.get(current.name);
      if (!existing || current.quality > existing.quality) {
        channelMap.set(current.name, { ...current });
      }

      current = {};
    }
  }

  return Array.from(channelMap.values());
}

function extractQuality(name) {
  if (name.includes('4K') || name.includes('2160p')) return 2160;
  if (name.includes('1080p') || name.includes('FHD') || name.includes('Full HD')) return 1080;
  if (name.includes('720p') || name.includes('HD')) return 720;
  if (name.includes('480p')) return 480;
  if (name.includes('360p')) return 360;
  return 576;
}

function cleanChannelName(name) {
  // Remove quality indicators and bracket content from name
  return name
    .replace(/\[[^\]]*\]/g, '') // REMOVE [brackets] like [Geo-blocked], [Not 24/7]
    .replace(/\s*\(?\d+p\)?/gi, '')
    .replace(/\s*\(?4K\)?/gi, '')
    .replace(/\s*\(?(FHD|HD|SD)\)?/gi, '')
    .trim();
}

// Heuristic to drop UA-like garbage names
function isGarbageName(name) {
  if (!name) return true;
  const lower = name.toLowerCase();

  // Contains obvious UA fragments
  if (
    lower.includes('like gecko') ||
    lower.includes('safari/') ||
    lower.includes('chrome/') ||
    lower.includes('edg/') ||
    lower.includes('mozilla/')
  ) {
    return true;
  }

  // Extremely long with lots of slashes = probably headers/UA
  if (name.length > 80 && (name.includes('/') || name.includes(';'))) {
    return true;
  }

  return false;
}