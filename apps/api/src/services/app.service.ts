// GitHub Releases API proxy with in-memory caching
// Fetches latest release from GitHub to serve app version info

const GITHUB_REPO = "fairpricedayalbagh/idealhomeplanet";
const CACHE_TTL_MS = 5 * 60 * 1000; // 5 minutes

interface VersionInfo {
  version: string;
  buildNumber: number;
  downloadUrl: string;
  releaseNotes: string;
  releasedAt: string;
}

let cache: { data: VersionInfo; fetchedAt: number } | null = null;

export async function getLatestVersion(): Promise<VersionInfo | null> {
  // Return cached data if fresh
  if (cache && Date.now() - cache.fetchedAt < CACHE_TTL_MS) {
    return cache.data;
  }

  try {
    const res = await fetch(
      `https://api.github.com/repos/${GITHUB_REPO}/releases/latest`,
      {
        headers: {
          Accept: "application/vnd.github.v3+json",
          "User-Agent": "IdealHomePlanet-API",
        },
      }
    );

    if (!res.ok) {
      console.error(`GitHub API responded with ${res.status}`);
      return cache?.data ?? null;
    }

    const release = await res.json();

    // Extract version from tag_name (e.g. "v1.2.0+5" → "1.2.0", buildNumber 5)
    const tag: string = release.tag_name ?? "";
    const stripped = tag.replace(/^v/, "");
    const [versionPart, buildPart] = stripped.split("+");
    const version = versionPart || "0.0.0";
    const buildNumber = buildPart ? parseInt(buildPart, 10) : 1;

    // Find APK asset
    const apkAsset = (release.assets ?? []).find(
      (a: any) => a.name?.endsWith(".apk")
    );

    if (!apkAsset) {
      console.error("No APK asset found in latest release");
      return cache?.data ?? null;
    }

    const data: VersionInfo = {
      version,
      buildNumber,
      downloadUrl: apkAsset.browser_download_url,
      releaseNotes: release.body ?? "",
      releasedAt: release.published_at ?? "",
    };

    cache = { data, fetchedAt: Date.now() };
    return data;
  } catch (err) {
    console.error("Failed to fetch GitHub release:", err);
    return cache?.data ?? null;
  }
}
