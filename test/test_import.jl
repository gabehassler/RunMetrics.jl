using RunMetrics

data_dir = joinpath(@__DIR__, "..", "sample_data")

strava_zip = joinpath(data_dir, "stravaSmall.zip")
strava_dest = joinpath(data_dir, "stravaFiles")

garmin_zip = joinpath(data_dir, "garminSmall.zip")
garmin_dest = joinpath(data_dir, "garminFiles")

import_strava(strava_zip, strava_dest)
import_garmin(garmin_zip, garmin_dest)
