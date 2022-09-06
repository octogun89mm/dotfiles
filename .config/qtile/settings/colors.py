from libqtile.lazy import lazy

colors = []
cache='/home/julien/.cache/wal/colors'

def load_colors(cache):
    with open(cache, 'r') as file:
        for i in range(15):
            colors.append(file.readline().strip())
    colors.append('#ffffff')
    colors.append('#ffffff00')
    lazy.reload()
load_colors(cache)

