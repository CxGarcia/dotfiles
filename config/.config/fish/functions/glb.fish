function glb --description "Pretty git branch list sorted by date"
    git for-each-ref --sort=committerdate refs/heads/ \
        --format='%(HEAD) %(align:25)%(color:cyan)%(refname:short)%(color:reset)%(end) %(align:25)%(authorname) (%(color:green)%(committerdate:relative)%(color:reset)): %(contents:subject)%(end)'
end
