using LightXML, TimeZones, DataFrames

export parse_tcx
export running_sum
# export geo_dist
export parse_laps
export make_diff_df

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

    @assert attribute(activity, "Sport") == "Running"


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


    return df
end



function running_sum(df::DataFrame; delay = 20)
    speed = df.speed

    n = length(speed)
    avg_speed = zeros(n)

    sum = 0.0
    for i = 1:delay
        sum += speed[i]
        avg_speed[i] = sum / delay
    end

    for i = (delay + 1):n
        sum -= speed[i - delay]
        sum += speed[i]
        avg_speed[i] = sum / delay
    end

    return avg_speed
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

function make_diff_df(df::DataFrame)
    n = size(df, 1)
    m = n - 1

    rownames = [:secs_time,
                :secs_speed,
                :v_meters,
                :h_meters_dist,
                :h_meters_pos,
                :hr]

    p = length(rownames)

    diff_df = DataFrame(zeros(m, p), rownames)

    for i = 1:m
        diff_df.secs_time[i] = (df.time[i + 1] - df.time[i]).value / 1e3 # time stored in milliseconds
        diff_df.v_meters[i] = df.altitude[i + 1] - df.altitude[i]
        diff_df.h_meters_dist[i] = df.distance[i + 1] - df.distance[i]
        diff_df.h_meters_pos[i] = geo_dist(df.pos[i + 1], df.pos[i])
        diff_df.secs_speed[i] = diff_df.h_meters_dist[i] / df.speed[i + 1]
        diff_df.hr[i] = df.hr[i + 1]
    end

    return diff_df

end