# using ZipFile
using GZip

const ACTIVITIES = "activities"

function import_strava(path::String, dest_dir::String)
    mkpath(dest_dir)
    if endswith(path, ".zip")
        import_strava_zip(path, dest_dir)
    else
        error("not yet implemented")
    end
end

function import_strava_zip(path::String, dest_dir::String)
    tmp_dir = mktempdir()

    r = ZipFile.Reader(path)
    try
        for file in r.files
            sp = splitpath(file.name)
            if length(sp) == 2 && sp[1] == ACTIVITIES
                tmp_path = joinpath(tmp_dir, sp[2])
                write(tmp_path, read(file))
                process_file(tmp_path, dest_dir)
                println(file.name)
            end
        end
    catch e
        close(r)
        @error "Could not import zip file" exception=(e, catch_backtrace())
    end
    close(r)
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
    tmp_dir_zip = mktempdir()
    tmp_dir_fit = mktempdir()
    r = ZipFile.Reader(path)
    try
        for file in r.files
            bn = basename(file.name)
            if startswith(bn, "UploadedFiles") && endswith(bn, ".zip")
                tmp_path = joinpath(tmp_dir_zip, bn)
                write(tmp_path, file)
            end
        end

        failed = String[]


        for zipfile in readdir(tmp_dir_zip, join = true)
            r = ZipFile.Reader(zipfile)
            for file in r.files
                if endswith(file.name, ".fit")
                    tmp_path = joinpath(tmp_dir_fit, basename(file.name))
                    try
                        write(tmp_path, read(file))
                    catch
                        push!(failed, file.name) # not sure why this works, but it prevents EOF error (and not just because of the catch)
                    end
                end
            end
        end

        return failed

        cmd = Cmd(["java", "-jar", ""])


    catch e
        @error "Something went wrong" exception=(e, catch_backtrace())
    end
end

function process_file(path::String, dir::String)
    bn = basename(path)
    if endswith(path, ".gz")
        GZip.open(path) do f
            contents = read(f)
            write(joinpath(dir, bn[1:(end - 3)]), contents)
        end
        # new_path = path[1:(end - 3)]
    end
    # cp(path, joinpath(dir, basename(path)))
end

function unzip(path::String)
    @assert endswith(path, ".zip")
    new_dir = path[1:(end - 4)]
    if Sys.iswindows()
        cmd = Cmd(["PowerShell", "-Command", "Expand-Archive", "-LiteralPath", "'$path'", "'$new_dir'"])
        @show cmd
        run(cmd)
    else
        error("Not currently implemented for non-Windows machines.")
    end
end
