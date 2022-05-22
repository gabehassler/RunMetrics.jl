using GZip

const ACTIVITIES = "activities"
const FINDER_JAR = joinpath(@__DIR__, "..", "artifacts", "ActivityFinder.jar") #TODO: make proper artifact

function import_strava(path::String, dest_dir::String)
    mkpath(dest_dir)
    if endswith(path, ".zip")
        import_strava_zip(path, dest_dir)
    else
        error("not yet implemented")
    end
end

function import_strava_zip(path::String, dest_dir::String)

    bn = basename(path)
    bn, _ = splitext(bn)


    tmp_dir = mktempdir()
    unzip_dir = joinpath(tmp_dir, bn)
    unzip(path, unzip_dir)
    activities_dir = joinpath(unzip_dir, ACTIVITIES)
    for file in readdir(activities_dir, join=true)
        process_file(file, dest_dir)
    end
end

function import_garmin(path::String, dest_dir::String)
    mkpath(dest_dir)
    if endswith(path, ".zip")
        import_garmin_zip(path, dest_dir)
    else
        error("not yet implemented")
    end
end

function import_garmin_zip(path::String, dest_dir::String)
    bn, _ = splitext(basename(path))
    tmp_dir_fit = mktempdir()
    tmp_dir_zip = joinpath(mktempdir(), bn)

    unzip(path, tmp_dir_zip)
    uploaded_dir = joinpath(tmp_dir_zip, "DI_CONNECT",
            "DI-Connect-Fitness-Uploaded-Files")

    for file in readdir(uploaded_dir, join = true)
        _, ext = splitext(file)
        if ext == ".zip"
            unzip(file, tmp_dir_fit)
        end
    end

    activity_files = find_activity_files(tmp_dir_fit)
    for file in activity_files
        process_file(file, dest_dir)
    end
end

function process_file(path::String, dir::String)
    bn = basename(path)
    this_dir = dirname(path)
    nm, ext = splitext(bn)
    tcx_path = joinpath(dir, "$nm.tcx")
    if isfile(tcx_path)
        println("$tcx_path already exists, skipping.")
        return nothing
    end
    try
        if ext == ".tcx"
            mv(path, joinpath(dir, bn))
        elseif ext == ".fit"
            tcx_output = joinpath(this_dir, "$nm.tcx")
            fit_to_tcx(path, tcx_output)
            mv(tcx_output, tcx_path)
        elseif ext == ".gz"
            new_path = joinpath(this_dir, nm)

            GZip.open(path) do f
                contents = read(f)
                write(new_path, contents)
            end

            process_file(new_path, dir)
        else
            @warn "cannot process file $(basename(path)). Unknown file extension"
        end
    catch
        failed_dir = joinpath(dir, "failed")
        mkpath(failed_dir)
        failed_path = joinpath(failed_dir, bn)
        @warn "could not process file $bn. moving to $failed_path"
        mv(path, failed_path, force = true)
    end

    return nothing
end

function find_activity_files(dir::String)

    activity_files = joinpath(dir, "files.txt")

    cmd = Cmd(["java", "-jar", FINDER_JAR, dir])
    open(activity_files, "w") do file
        redirect_stdout(file) do
            run(cmd)
        end
    end

    return(readlines(activity_files))
end



function unzip(src::String, dest::String)
    if Sys.iswindows()
        cmd = Cmd(["PowerShell", "-Command", "Expand-Archive", "-LiteralPath", "'$src'", "-DestinationPath", "'$dest'"])
        run(cmd)
    else
        error("Not currently implemented for non-Windows machines.")
    end
end


function unzip(path::String)
    unzip(path, splitext(path)[1])
end

function fit_to_tcx(fit::String, tcx::String)
    cmd_strings = ["fittotcx", fit, tcx]
    if Sys.iswindows()
        cmd_strings = [["cmd", "/C"]; cmd_strings]
    end
    run(Cmd(cmd_strings))
end