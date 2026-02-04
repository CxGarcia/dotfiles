function portfind --description "Find process using a port"
    if test (count $argv) -eq 0
        echo "Usage: portfind <port>"
        return 1
    end
    lsof -i :$argv[1]
end
