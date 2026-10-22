enum SourceType { fast, curated, iptvOrg, custom }

class PlaylistSource {
  final String id;
  final String name;
  final String description;
  final String url;
  final SourceType type;
  final String badge;

  const PlaylistSource({
    required this.id,
    required this.name,
    required this.description,
    required this.url,
    required this.type,
    required this.badge,
  });

  static const List<PlaylistSource> predefinedSources = [
    PlaylistSource(
      id: 'samsung_all',
      name: 'Samsung TV Plus (Global)',
      description: 'Official 24/7 FAST channels with 99% uptime',
      url: 'https://raw.githubusercontent.com/BuddyChewChew/app-m3u-generator/refs/heads/main/playlists/samsungtvplus_all.m3u',
      type: SourceType.fast,
      badge: 'FAST 99%',
    ),
    PlaylistSource(
      id: 'pluto_all',
      name: 'Pluto TV (Global)',
      description: '300+ movie, news, entertainment & series channels',
      url: 'https://raw.githubusercontent.com/BuddyChewChew/app-m3u-generator/refs/heads/main/playlists/plutotv_all.m3u',
      type: SourceType.fast,
      badge: 'FAST 99%',
    ),
    PlaylistSource(
      id: 'plex_all',
      name: 'Plex TV (Global)',
      description: 'High-quality live streams across all genres',
      url: 'https://raw.githubusercontent.com/BuddyChewChew/app-m3u-generator/refs/heads/main/playlists/plex_all.m3u',
      type: SourceType.fast,
      badge: 'FAST 95%',
    ),
    PlaylistSource(
      id: 'free_tv',
      name: 'Free-TV Worldwide',
      description: 'Community-curated legal international channels',
      url: 'https://raw.githubusercontent.com/Free-TV/IPTV/master/playlist.m3u8',
      type: SourceType.curated,
      badge: 'Curated',
    ),
    PlaylistSource(
      id: 'iptv_in',
      name: 'IPTV-Org India (IN)',
      description: 'National and regional Indian broadcast channels',
      url: 'https://iptv-org.github.io/iptv/countries/in.m3u',
      type: SourceType.iptvOrg,
      badge: 'India',
    ),
    PlaylistSource(
      id: 'iptv_us',
      name: 'IPTV-Org USA (US)',
      description: 'American news, sports, local and broadcast TV',
      url: 'https://iptv-org.github.io/iptv/countries/us.m3u',
      type: SourceType.iptvOrg,
      badge: 'USA',
    ),
    PlaylistSource(
      id: 'iptv_uk',
      name: 'IPTV-Org United Kingdom (GB)',
      description: 'British news, entertainment, and public broadcasts',
      url: 'https://iptv-org.github.io/iptv/countries/gb.m3u',
      type: SourceType.iptvOrg,
      badge: 'UK',
    ),
    PlaylistSource(
      id: 'iptv_pk',
      name: 'IPTV-Org Pakistan (PK)',
      description: 'Pakistani news, drama, and entertainment channels',
      url: 'https://iptv-org.github.io/iptv/countries/pk.m3u',
      type: SourceType.iptvOrg,
      badge: 'Pakistan',
    ),
    PlaylistSource(
      id: 'iptv_ae',
      name: 'IPTV-Org UAE (AE)',
      description: 'Middle Eastern and UAE broadcast networks',
      url: 'https://iptv-org.github.io/iptv/countries/ae.m3u',
      type: SourceType.iptvOrg,
      badge: 'UAE',
    ),
  ];
}
