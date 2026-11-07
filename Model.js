function parseCache(text) {
    try {
        const cache = JSON.parse(text);
        return cache && (cache.schemaVersion === 2 || cache.schemaVersion === 3) && Array.isArray(cache.launches) ? cache : null;
    } catch (_) {
        return null;
    }
}

function nextLaunch(cache) {
    return cache && Array.isArray(cache.launches) ? cache.launches[0] || null : null;
}

function launchStatus(launch) {
    if (!launch)
        return "";

    switch (launch.statusId) {
    case 5: return "Hold";
    case 8: return "TBC";
    case 6: return "In flight";
    default: return "";
    }
}

function formatCountdown(ms) {
    const totalSeconds = Math.max(0, Math.floor(ms / 1000));
    const days = Math.floor(totalSeconds / 86400);
    const hours = Math.floor((totalSeconds % 86400) / 3600);
    const minutes = Math.floor((totalSeconds % 3600) / 60);
    const seconds = totalSeconds % 60;

    if (days > 0)
        return "T-" + days + "d " + hours + "h";

    if (hours > 0)
        return "T-" + hours + "h " + minutes + "m";

    return "T-" + pad(hours) + ":" + pad(minutes) + ":" + pad(seconds);
}

function launchPhoto(launch) {
    if (!launch)
        return "";

    switch (launch.rocketFamily) {
    case "Falcon 9": return "assets/falcon-launchpad.jpg";
    case "Falcon Heavy": return "assets/heavy-launchpad.jpg";
    case "Starship": return "assets/starship-launchpad.jpg";
    default: return "";
    }
}

function formatNetDate(isoTime, utcCalendar = true) {
    const date = new Date(isoTime);
    if (isNaN(date.getTime()))
        return "TBD";

    const month = utcCalendar ? date.getUTCMonth() : date.getMonth();
    const day = utcCalendar ? date.getUTCDate() : date.getDate();
    return ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"][month] + " " + day;
}

function formatLocalTime(isoTime) {
    const date = new Date(isoTime);
    return isNaN(date.getTime()) ? "TBD" : date.toLocaleString();
}

function formatShortTime(isoTime) {
    const date = new Date(isoTime);
    return isNaN(date.getTime()) ? "TBD" : pad(date.getHours()) + ":" + pad(date.getMinutes());
}

function launchTimeLabel(next, nowMs) {
    if (!next)
        return "TBD";

    if (deriveFreshState(next, nowMs).state === "launching")
        return "Launching";

    if (next.timePrecision === "exact")
        return formatLocalTime(next.net);

    if (next.timePrecision === "net")
        return "NET " + formatNetDate(next.net, true);

    return "TBD";
}

function deriveState(cache, nowMs) {
    if (!cache)
        return { state: "loading", label: "Loading", stale: false };

    const next = nextLaunch(cache);
    const expiresAt = Date.parse(cache.expiresAt);
    const isStale = !isNaN(expiresAt) && nowMs > expiresAt;
    const fresh = deriveFreshState(next, nowMs);

    if (isStale)
        return { state: "stale", label: fresh.label + " · Stale", stale: true };

    return fresh;
}

function deriveFreshState(next, nowMs) {
    if (!next)
        return { state: "tbd", label: "TBD", stale: false };

    const launchTime = Date.parse(next.net);
    if (next.statusId === 6 || (next.timePrecision === "exact" && !isNaN(launchTime) && launchTime <= nowMs))
        return { state: "launching", label: "Launching", stale: false };

    if (next.timePrecision === "exact" && !isNaN(launchTime))
        return { state: "countdown", label: formatCountdown(launchTime - nowMs), stale: false };

    if (next.timePrecision === "net")
        return { state: "net", label: "NET " + formatNetDate(next.net, true), stale: false };

    return { state: "tbd", label: "TBD", stale: false };
}

function formatUpcomingTime(launch) {
    if (!launch)
        return "TBD";

    return launch.timePrecision === "exact" ? formatNetDate(launch.net, false) + " " + formatShortTime(launch.net)
        : launch.timePrecision === "net" ? "NET " + formatNetDate(launch.net)
        : "TBD";
}

function formatUpcomingLine(launch) {
    if (!launch)
        return "";

    const parts = [formatUpcomingTime(launch)];
    if (launch.rocket)
        parts.push(launch.rocket);
    if (launch.mission)
        parts.push(launch.mission);

    return parts.join(" · ");
}

function pad(number) {
    return number < 10 ? "0" + number : String(number);
}
