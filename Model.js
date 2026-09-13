function parseCache(text) {
    try {
        const cache = JSON.parse(text);
        return cache && cache.schemaVersion === 1 ? cache : null;
    } catch (_) {
        return null;
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

    return "T-" + pad(hours) + ":" + pad(minutes) + ":" + pad(seconds);
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

function formatWeekdayDate(isoTime, utcCalendar = true) {
    const date = new Date(isoTime);
    if (isNaN(date.getTime()))
        return "TBD";

    const weekday = utcCalendar ? date.getUTCDay() : date.getDay();
    return ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"][weekday] + ", " + formatNetDate(isoTime, utcCalendar);
}

function formatAfterNext(launch) {
    if (!launch)
        return "";

    const time = launch.timePrecision === "tbd" ? "TBD" : "NET " + formatWeekdayDate(launch.net, launch.timePrecision !== "exact");
    return launch.mission ? time + " · " + launch.mission : time;
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

    const next = cache.next;
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

function pad(number) {
    return number < 10 ? "0" + number : String(number);
}
