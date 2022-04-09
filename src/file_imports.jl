using ZipFile
using GZip

const ACTIVITIES = "activities"

function import_strava(path::String, dest_dir::String)
    mkpath(dest_dir)
    if endswith(path, ".zip")
        import_zip(path, dest_dir)
    end
end

function import_zip(path::String, dest_dir::String)
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

cd(@__DIR__)
zip_path = joinpath("..", "sample_data", "export_7225196.zip")
dest_dir = "test_activities"
import_strava(zip_path, dest_dir)
