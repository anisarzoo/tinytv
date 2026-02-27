// Simple validation to check if stream URL is accessible
export async function validateChannel(url) {
    try {
        const controller = new AbortController();
        const timeout = setTimeout(() => controller.abort(), 5000);
        
        const response = await fetch(url, {
            method: 'HEAD',
            signal: controller.signal,
            mode: 'no-cors' // Bypass CORS for validation
        });
        
        clearTimeout(timeout);
        return response.ok || response.type === 'opaque'; // opaque means no-cors worked
    } catch (error) {
        return false;
    }
}

// Batch validate channels (limited to avoid overwhelming the browser)
export async function batchValidateChannels(channels, limit = 10) {
    const results = [];
    
    for (let i = 0; i < channels.length; i += limit) {
        const batch = channels.slice(i, i + limit);
        const batchResults = await Promise.all(
            batch.map(async (channel) => ({
                ...channel,
                isOnline: await validateChannel(channel.url)
            }))
        );
        results.push(...batchResults);
    }
    
    return results;
}
