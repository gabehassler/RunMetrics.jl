using LightXML, TimeZones, DataFrames

export parse_tcx
export parse_laps

struct Trackpoint
    dt::ZonedDateTime
    distance::Float64
    altitude::Float64
    hr::Float64
    speed::Float64
    pos::Tuple{Float64, Float64}
end

function parse_trackpoint(tp::XMLElement)
    @assert name(tp) == "Trackpoint"
    dt = ZonedDateTime(content(find_element(tp, "Time")))
    distance = parse(Float64, content(find_element(tp, "DistanceMeters")))
    altitude = parse(Float64, content(find_element(tp, "AltitudeMeters")))
    hr = parse(Float64, content(find_element(tp, "HeartRateBpm")))
    ext_el = find_element(tp, "Extensions")
    n3_el = find_element(ext_el, "TPX")
    speed_el = find_element(n3_el, "Speed")
    speed = parse(Float64, content(speed_el))
    pos_el = find_element(tp, "Position")
    lat = parse(Float64, content(find_element(pos_el, "LatitudeDegrees")))
    long = parse(Float64, content(find_element(pos_el, "LongitudeDegrees")))


    return Trackpoint(dt, distance, altitude, hr, speed, (lat, long))
end


function count_points(activity::XMLElement)
    @assert name(activity) == "Activity"

    n = 0

    laps = activity["Lap"]

    for lap in laps


        tracks = lap["Track"]

        for track in tracks
            n += length(track["Trackpoint"])
        end
    end

    return n
end


function get_activity(path::String)
    xdoc = parse_file(path)

    activities_el = root(xdoc)["Activities"][1]

    activity_els = activities_el["Activity"]

    @assert length(activity_els) == 1 #TODO: handle activities

    return activity_els[1]
end

function parse_laps(path::String)
    activity = get_activity(path)

    laps = activity["Lap"]
    n = length(laps)

    df = DataFrame()
    df.seconds = Vector{Float64}(undef, n)
    df.meters = Vector{Float64}(undef, n)
    for i = 1:length(laps)

        lap = laps[i]
        dm = find_element(lap, "DistanceMeters")
        df.meters[i] = parse(Float64, content(dm))

        tsec = find_element(lap, "TotalTimeSeconds")
        df.seconds[i] = parse(Float64, content(tsec))
    end

    return df
end

function parse_tcx(path::String)

    activity = get_activity(path)

    @assert attribute(activity, "Sport") == "Running" # TODO: handle other sports


    n = count_points(activity)

    df = DataFrame()
    df.time = Vector{ZonedDateTime}(undef, n)
    df.distance = zeros(n)
    df.hr = zeros(n)
    df.speed = zeros(n)
    df.altitude = zeros(n)
    df.pos = Vector{Tuple{Float64, Float64}}(undef, n)

    counter = 0
    for lap in activity["Lap"]
        for track in lap["Track"]
            for tp_el in track["Trackpoint"]
                counter += 1
                tp = parse_trackpoint(tp_el)

                df.time[counter] = tp.dt
                df.distance[counter] = tp.distance
                df.hr[counter] = tp.hr
                df.speed[counter] = tp.speed
                df.altitude[counter] = tp.altitude
                df.pos[counter] = tp.pos

            end
        end
    end

    # Activity ID is same as start time
    start_time = ZonedDateTime(content(find_element(activity, "Id")))


    rs = RunSummary(n, start_time)
    rs.time[1] = round(df.distance[1] / df.speed[1])
    rs.dist[1] = df.distance[1]
    rs.alt[1] = 0.0
    rs.hr[1] = df.hr[1]


    for i = 2:n

        rs.time[i] = (df.time[i] - df.time[i - 1]).value / 1e3 # time stored in milliseconds
        rs.alt[i] = df.altitude[i] - df.altitude[i - 1]
        rs.dist[i] = geo_dist(df.pos[i], df.pos[i - 1])
        rs.hr[i] = df.hr[i]
    end

    return rs
end


const E_RADIUS = 6.3781370e6
const P_RADIUS = 6.3567523e6
const DEG_TO_RAD = 2.0 * π / 360.0

function geo_dist(p1::Tuple{Float64, Float64}, p2::Tuple{Float64, Float64})
    dlat = (p1[1] - p2[1]) * DEG_TO_RAD
    dlong = (p1[2]- p2[2]) * DEG_TO_RAD
    mlat = 0.5 * (p1[1] + p2[1]) * DEG_TO_RAD

    cmlat = cos(mlat)

    x = 1.0 / sqrt(1.0 / E_RADIUS^2 + tan(mlat)^2 / P_RADIUS^2) #distance from center of ellipse
    radius = x / cmlat


    return radius * sqrt(dlat^2 + (cmlat * dlong)^2)
end
