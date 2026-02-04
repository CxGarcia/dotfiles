function portkill --description "Kill process using a port"
    if test (count $argv) -eq 0
        echo "Usage: portkill <port>"
        return 1
    end
    set -l pid (lsof -ti :$argv[1])
    if test -z "$pid"
        echo "No process found on port $argv[1]"
        return 1
    end
    echo "Killing PID $pid on port $argv[1]"
    kill -9 $pid
end
