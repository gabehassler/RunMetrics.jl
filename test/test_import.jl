using RunMetrics

data_dir = joinpath(@__DIR__, "..", "sample_data")

strava_zip = joinpath(data_dir, "strava.zip")
strava_dest = joinpath(data_dir, "stravaFiles")

import_strava(strava_zip, strava_dest)
