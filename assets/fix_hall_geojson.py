import json

input_file = 'indoor_maps/geojson/CC/cc1.geojson.json'
output_file = 'indoor_maps/geojson/CC/cc1.geojson.json'

with open(input_file, 'r') as f:
    data = json.load(f)

# Step 1: Find the actual center of ALL coordinates in the file
all_lats = []
all_lngs = []

def collect_coords(coords):
    if isinstance(coords[0], list):
        for c in coords:
            collect_coords(c)
    elif len(coords) == 2:
        all_lngs.append(coords[0])
        all_lats.append(coords[1])

for feature in data['features']:
    geom = feature['geometry']
    if 'coordinates' in geom:
        collect_coords(geom['coordinates'])

CENTER_LAT = (min(all_lats) + max(all_lats)) / 2
CENTER_LNG = (min(all_lngs) + max(all_lngs)) / 2

print(f"Data center: LAT={CENTER_LAT}, LNG={CENTER_LNG}")

# Step 2: Scale and shift
SCALE = 1.2  # Make 25% bigger
LAT_SHIFT = 0.0  # Adjust after scaling if needed
LNG_SHIFT = 0.0  # Adjust after scaling if needed

def transform_point(lng, lat):
    new_lat = CENTER_LAT + (lat - CENTER_LAT) * SCALE + LAT_SHIFT
    new_lng = CENTER_LNG + (lng - CENTER_LNG) * SCALE + LNG_SHIFT
    return [round(new_lng, 11), round(new_lat, 11)]

def transform_coords(coords):
    if isinstance(coords[0], list):
        return [transform_coords(c) for c in coords]
    if len(coords) == 2:
        return transform_point(coords[0], coords[1])
    return coords

for feature in data['features']:
    geom = feature['geometry']
    if 'coordinates' in geom:
        geom['coordinates'] = transform_coords(geom['coordinates'])

with open(output_file, 'w') as f:
    json.dump(data, f, indent=4)

print("Done! Indoor map coordinates adjusted.")