// src/utils/channelFilter.js

import { isFavorite, getFavorites } from './storage.js';

// ---- CONFIG FOR PERFORMANCE ----
const MAX_CHANNELS_ALL_REGION = 800;         // hard cap when region = ALL
const MAX_AFTER_FILTERING_PER_REGION = 600;  // cap per normal region
const MIN_QUALITY_FOR_ALL_REGION = 576;      // drop SD noise on ALL
// --------------------------------

// STRICT regional/local channel detection - Prefer to filter regional, keep nationals
export function isRegionalChannel(channel) {
  const name = (channel.name || '').toLowerCase();
  const category = (channel.category || '').toLowerCase();

  // 1) Pan‑India national brands you always want to KEEP (never regional)
  const nationalWhitelist = [
    // Hindi / English national news
    'aaj tak', 'abp news', 'news18 india', 'zee news', 'india tv', 'news nation', 'news 24', 'good news today', 'dd news', 'dd india', 'ndtv 24x7', 'ndtv india', 'wion', 'times now', 'mirror now', 'et now', 'republic tv', 'republic bharat', 'news x',
    'zee business', 'cnbc tv18', 'cnbc awaaz', 'cnbc', 'et now swadesh', 'cnbc bajar',
    'history tv18', 'gyandarshan', 'tv brics', 'travelxp', 'discovery', 'animal planet', 'nat geo', 'tlc', 'investigation discovery',
    'b4u movies', 'maha movie', 'b4u music', 'mastiii', 'e 24', 'shemaroo tv', 'shemaroo josh', 'abzy movies', 'abzy dhakad',
    'dd sports', 'dd national', 'star sports', 'sony sports', 'sports18', 'euro sport',
    'star plus', 'sony tv', 'colors', 'zee tv', 'star gold', 'sony max', 'zee cinema', '&pictures', '&flix', '&privé',
    'nick', 'disney', 'pogo', 'hungama', 'sonic', 'cartoon network',
    'mtv', '9xm', 'vhl', 'zoom', 'vh1', '9x jalwa'
  ];

  for (const allowed of nationalWhitelist) {
    if (name.includes(allowed)) {
      return false; // definitely not regional
    }
  }

  // 2) Strong regional / language cues
  const regionalLanguages = [
    // Indian languages
    'tamil', 'telugu', 'kannada', 'malayalam', 'bengali', 'bangla', 'marathi', 'gujarati', 'punjabi', 'bhojpuri', 'odia', 'assamese', 'urdu regional', 'konkani', 'tulu', 'mizo', 'khasi', 'garo', 'nepali', 'maithili',
    'hmtv', 'lokmat', 'maza', 'majha', 'taas', 'sambad', 'khabar', 'kannur', 'nagaland', 'raj news', 'raj tv', 'raj digital', 'prudent', 'prime9', 'vtv news', 'dy 365', 'hornbill', 'samay', 'samachar', 'kashish', 'subhavaartha', 'janam tv', 'twenty four news', 'reporter tv', 'news live', 'news daily 24', 'pratham khabar', 'time vision', 'venad', 'abp ganga', 'abp majha', 'abp ananda', 'abp asmita', 'abp sanjha', 'abp desam', 'abp nadu', 'zee 24 taas', 'zee 24 kalak', 'zee bihar', 'zee madhya pradesh', 'zee m.p.', 'zee chhattisgarh', 'zee rajasthan', 'zee salaam', 'zee 24 ghanta', 'zee tamil', 'zee telugu', 'zee kannada', 'zee keralam', 'zee sarthak', 'zee punjab',
    'news18 punjab', 'news18 rajasthan', 'news18 bihar', 'news18 gujarat', 'news18 tamil', 'news18 kerala', 'news18 odia', 'news18 kannada', 'news18 assam', 'news18 madhya pradesh', 'news18 up', 'news18 nct', 'news18 bihar',
    'subin tv', 'zee news malayalam', 'pitaara', 'zb cinema', 'tv9', 'manoranjan', 'mh 1', 'mh1', 'ptc', 'polimer', 'makkal', 'sirippoli', 'kappa tv', 'jan tv', 'maiboli', 'vanitha tv', 'vasanth tv', 'peppers tv', 'isai aruvi', 'songdew', 'tribe tv', 'manorama', 'surya tv', 'sun tv', 'suriyan', 'sooriyan', 'etv', 'mazhavil', 'ibc 24', 'inews', 'jk 24x7', 'kairali', 'media one', 'public tv', 't news', 'aakaash aath', 'amrita', 'tarang', 'vaanavil', 'sakshi', 'thanthi', 'tv5 news', 'v6 news', 'asianet news', 'gemini tv', '9x jhakaas', '9x tashan', 'cvr', 'mntv', 'chardikla', 'anandham', 'nk tv', 'hamdard tv', 'ultimate tv', '10 tv', '99 tv', 'abn andhra jyoti', 'ananda barta', 'big tv', 'moon tv', 'yoganadam news', 'zb cartoon', 'zb tv', 'alankar tv', 'kcl tv', 'ntc tv', 'pulari tv', 'madhimugam', 'mantavya', 'puthiya thalaimurai', 'zillarbarta news', 'vbc news', 'kaumudy tv', 'nandighosha', 'chithiram', 'jeevan tv', 'starnet', 'ccv', 'kalaignar', 'captain tv', 'mega tv', 'news7 tamil', 'sathiyam', 'vasanth', 'vendhar', 'lotus news'
  ];
  if (regionalLanguages.some(k => name.includes(k))) {
    return true;
  }

  // 3) Explicit Indian state / region / city names – treat as regional
  const regionalNames = [
    'andhra pradesh', 'telangana', 'karnataka', 'tamil nadu', 'kerala', 'uttar pradesh', 'uttarakhand', 'bihar', 'jharkhand', 'rajasthan', 'gujarat', 'maharashtra', 'punjab', 'haryana', 'himachal', 'jammu', 'kashmir', 'west bengal', 'assam', 'nagaland', 'goa', 'odisha', 'sikkim', 'manipur', 'tripura', 'mizoram', 'arunachal', 'meghalaya', 'chhattisgarh', 'madhya pradesh', 'delhi ncr', 'mumbai', 'kolkata', 'chennai', 'bangalore', 'hyderabad', 'ahmedabad', 'pune', 'surat', 'jaipur', 'lucknow', 'kanpur', 'nagpur', 'indore', 'thane', 'bhopal', 'visakhapatnam', 'patna', 'vadodara', 'ghaziabad', 'ludhiana', 'agra', 'nashik', 'faridabad', 'meerut', 'rajkot', 'kalyan', 'vasai-virar', 'varanasi', 'srinagar', 'aurangabad', 'dhanbad', 'amritsar', 'navi mumbai', 'allahabad', 'ranchi', 'haora', 'coimbatore', 'jabalpur', 'gwalior', 'vijayawada', 'jodhpur', 'madurai', 'raipur', 'kota', 'guwahati', 'chandigarh', 'solapur', 'hubli-dharwad', 'bareilly', 'moradabad', 'mysore', 'gurgaon', 'aligarh', 'jalandhar', 'tiruchirappalli', 'bhubaneswar', 'salem', 'mira-bhayandar', 'warangal', 'thiruvananthapuram', 'guntur', 'bhilai', 'saharanpur', 'gorakhpur', 'bikaner', 'amravati', 'noida', 'jamshedpur', 'bhilai', 'cuttack', 'firozabad', 'kochi', 'nellore', 'bhavnagar', 'dehradun', 'durgapur', 'asansol', 'rourkela', 'nanded', 'kolhapur', 'ajmer', 'akola', 'gulbarga', 'jamnagar', 'uval', 'shivamogga', 'shimla', 'imphal', 'agartala', 'aizawl', 'kohima', 'shillong', 'itanagar', 'gangtok', 'panaji'
  ];
  if (regionalNames.some(k => name.includes(k))) {
    return true;
  }

  // 4) Specific patterns you do not want in the main national list
  const filterPatterns = [
    /\bgeo-blocked\b/i,
    /\bnot\s*24\/7\b/i,
    /\btest\b/i,
    /\bdemo\b/i,
    /\bsample\b/i,
    /cable/i,
    /local/i,
    /community/i,
    // DD regional channels (keep only DD National / Sports / News / India via whitelist)
    /^dd\s(?!national|sports|news|india)/i
  ];
  if (filterPatterns.some(p => p.test(name))) {
    return true;
  }

  // 5) Category-based cleanup (devotional / legislative / undefined etc.)
  const regionalCategories = [
    'regional',
    'devotional',
    'bhakti',
    'religious',
    'spiritual',
    'legislative',
    'culture',
    'undefined'
  ];
  if (regionalCategories.some(c => category.includes(c))) {
    return true;
  }

  // Default: keep channel (treated as non‑regional)
  return false;
}

// IMPROVED: Filter out broken/offline channels based on URL patterns
export function isProbablyOffline(channel) {
  const url = (channel.url || '').toLowerCase();
  const name = (channel.name || '').toLowerCase();

  // 1) Known bad / unstable hosts and query patterns
  const problematicPatterns = [
    'd35j504z0x2vu2.cloudfront.net', 'd35j504z0x1ykv.cloudfront.net', 'd3j504z0x1ykv.cloudfront.net',
    'amagi.tv/playlist.m3u8', 'akamaized.net/110923', 'akamaized.net/i/live', '.akamaized.net/live',
    'aasthaott.akamaized', 'utkalbongo.com', 'live-stream.utkal', 'p-ntv.fcdn.cz', 'live.indosat.com', 'ott.indosat.id',
    // internal/loopback
    '127.0.0.1', 'localhost', '0.0.0.0', '192.168.', '10.0.0.',
    // temporary/proxy/github raw
    'githubusercontent.com/raw/', 'proxy?', 'cgi-bin', 'bit.ly/', 'tinyurl.com/', 't.me/',
    // common dead/expired tokens or session keys
    '.m3u8?token=', '.m3u8?auth=', '.m3u8?key=', 'signature=', 'exp=', 'policy=',
    'chunklist_b', 'temp.', 'test.', 'demo.', 'sample.'
  ];
  for (const pattern of problematicPatterns) {
    if (url.includes(pattern)) return true;
  }

  // 2) Plain HTTP IP streams (no domain), very unstable in practice
  if (url.startsWith('http://') &&
    url.match(/^http:\/\/\d{1,3}(\.\d{1,3}){3}/)) {
    return true;
  }

  // 3) Suspiciously short or malformed URLs
  if (url.length < 25 || !url.includes('.')) {
    return true;
  }

  // For this app, non‑HLS URLs are more likely to be dead
  if (!url.endsWith('.m3u8') && !url.includes('.m3u8?')) {
    return true;
  }

  // 4) Name hints of low quality / dead test feeds
  const veryLowQualityIndicators = [
    '144p', '240p', '360p', 'low quality', 'lq', 'mobile only', 'backup', 'test', 'demo', 'sample',
    'offline', 'down', 'not working', 'broken', 'dead', 'removed'
  ];
  for (const indicator of veryLowQualityIndicators) {
    if (name.includes(indicator)) return true;
  }

  // 5) Combined heuristic: if both name and URL look suspicious
  const suspiciousWords = ['local', 'cable', 'lan only', 'office', 'private'];
  if (suspiciousWords.some(w => name.includes(w)) && url.startsWith('http://')) {
    return true;
  }

  return false;
}

// Prioritize channels based on quality and reliability
export function getChannelScore(channel) {
  let score = 0;
  const name = (channel.name || '').toLowerCase();
  const category = (channel.category || '').toLowerCase();

  // Base score by quality
  if (channel.quality >= 2160) score += 100;
  else if (channel.quality >= 1080) score += 70;
  else if (channel.quality >= 720) score += 50;
  else if (channel.quality >= 576) score += 20;
  else score += 5;

  // Extra score for well-known national brands
  const nationalChannels = [
    'aaj tak',
    'ndtv',
    'zee news',
    'india today',
    'news18',
    'star plus',
    'zee tv',
    'sony',
    'colors',
    'discovery',
    '9xm',
    'mtv',
    'cartoon network',
    'pogo'
  ];
  for (const national of nationalChannels) {
    if (name.includes(national)) {
      score += 80;
      break;
    }
  }

  // Popular categories
  const popularCategories = {
    news: 40,
    sports: 40,
    movies: 35,
    entertainment: 30,
    music: 25,
    kids: 20
  };
  for (const [cat, points] of Object.entries(popularCategories)) {
    if (category.includes(cat)) {
      score += points;
      break;
    }
  }

  // Penalize regional and offline channels
  if (isRegionalChannel(channel)) {
    score -= 100;
  }
  if (isProbablyOffline(channel)) {
    score -= 60;
  }

  const undesirableCategories = ['devotional', 'religious', 'undefined', 'legislative'];
  for (const cat of undesirableCategories) {
    if (category.includes(cat)) {
      score -= 40;
      break;
    }
  }

  // Favorites boost
  if (isFavorite(channel.name)) {
    score += 60;
  }

  return score;
}

// MAIN FILTER used by app.js (HARD regional filter + performance caps)
export function applyFilters(allChannels) {
  const searchInput = document.getElementById('searchInput');
  const regionSelect = document.getElementById('regionSelect');
  const categorySelect = document.getElementById('categorySelect');
  const qualitySelect = document.getElementById('qualitySelect');
  const sortSelect = document.getElementById('sortSelect');
  const hideRegionalCheckbox = document.getElementById('hideRegional');
  const hideOfflineCheckbox = document.getElementById('hideOffline');
  const favoritesOnlyCheckbox = document.getElementById('favoritesOnly');

  const searchTerm = (searchInput?.value || '').toLowerCase().trim();
  const region = regionSelect?.value || 'IN';
  const categoryFilter = (categorySelect?.value || '').toLowerCase();
  const qualityFilter = qualitySelect?.value || 'all';
  const sortBy = sortSelect?.value || 'smart';
  const hideOffline = !!hideOfflineCheckbox?.checked;
  const favoritesOnly = !!favoritesOnlyCheckbox?.checked;

  const favorites = getFavorites();
  const favNames = new Set(
    favorites
      .filter(f => !f.country || f.country === region)
      .map(f => f.name)
  );

  let list = allChannels;

  // PERFORMANCE: when region = ALL, drop obviously low-quality + regional early
  if (region === 'ALL') {
    list = list.filter(ch => !isRegionalChannel(ch));
    list = list.filter(ch => (parseInt(ch.quality, 10) || 0) >= MIN_QUALITY_FOR_ALL_REGION);
    if (hideOffline) {
      list = list.filter(ch => !isProbablyOffline(ch));
    }
    // pre-sort by score and cap
    list.sort((a, b) => getChannelScore(b) - getChannelScore(a));
    if (list.length > MAX_CHANNELS_ALL_REGION) {
      list = list.slice(0, MAX_CHANNELS_ALL_REGION);
    }
  } else {
    // HARD regional filter for normal regions
    list = list.filter(ch => !isRegionalChannel(ch));
  }

  if (hideOffline && region !== 'ALL') {
    list = list.filter(ch => !isProbablyOffline(ch));
  }

  if (favoritesOnly) {
    list = list.filter(ch => favNames.has(ch.name));
  }

  if (categoryFilter) {
    list = list.filter(
      ch => (ch.category || '').toLowerCase() === categoryFilter
    );
  }

  if (qualityFilter !== 'all') {
    const q =
      qualityFilter === 'hd'
        ? 720
        : qualityFilter === 'fhd'
          ? 1080
          : parseInt(qualityFilter, 10);

    if (!isNaN(q)) {
      list = list.filter(ch => {
        const cq = parseInt(ch.quality, 10);
        return !isNaN(cq) && cq >= q;
      });
    }
  }

  if (searchTerm) {
    list = list.filter(ch => {
      const n = (ch.name || '').toLowerCase();
      const cat = (ch.category || '').toLowerCase();
      const country = (ch.country || '').toLowerCase();
      return (
        n.includes(searchTerm) ||
        cat.includes(searchTerm) ||
        country.includes(searchTerm)
      );
    });
  }

  // FINAL cap per normal region to avoid 1000+ cards on low‑end devices
  if (region !== 'ALL' && list.length > MAX_AFTER_FILTERING_PER_REGION) {
    // sort once by score, then trim
    list.sort((a, b) => getChannelScore(b) - getChannelScore(a));
    list = list.slice(0, MAX_AFTER_FILTERING_PER_REGION);
  } else if (region === 'ALL') {
    // Already pre-sorted above; keep order
  } else {
    // sort based on selected mode
    switch (sortBy) {
      case 'name':
        list.sort((a, b) => (a.name || '').localeCompare(b.name || ''));
        break;
      case 'quality':
        list.sort(
          (a, b) =>
            (parseInt(b.quality, 10) || 0) - (parseInt(a.quality, 10) || 0)
        );
        break;
      case 'category':
        list.sort((a, b) =>
          (a.category || '').localeCompare(b.category || '')
        );
        break;
      case 'favorites':
        list.sort((a, b) => {
          const af = favNames.has(a.name) ? 1 : 0;
          const bf = favNames.has(b.name) ? 1 : 0;
          if (af !== bf) return bf - af;
          return (a.name || '').localeCompare(b.name || '');
        });
        break;
      case 'smart':
      default:
        list.sort((a, b) => getChannelScore(b) - getChannelScore(a));
        break;
    }
  }

  return list;
}

// Export filter statistics
export function getFilterStats(channels) {
  const stats = {
    total: channels.length,
    regional: 0,
    offline: 0,
    hd: 0,
    fullHd: 0,
    major: 0
  };

  channels.forEach(ch => {
    if (isRegionalChannel(ch)) stats.regional++;
    if (isProbablyOffline(ch)) stats.offline++;
    if (ch.quality >= 720) stats.hd++;
    if (ch.quality >= 1080) stats.fullHd++;
    if (getChannelScore(ch) > 50) stats.major++;
  });

  return stats;
}
