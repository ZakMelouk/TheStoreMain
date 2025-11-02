-- Tables
CREATE TABLE IF NOT EXISTS products (
  id CHAR(36) PRIMARY KEY,
  name VARCHAR(255),
  description TEXT,
  price DECIMAL(10,2),
  tags VARCHAR(255)
);

CREATE TABLE IF NOT EXISTS tags (
  name VARCHAR(50) PRIMARY KEY,
  displayName VARCHAR(100)
);

-- Données
INSERT INTO tags (name, displayName) VALUES
('accessories','Accessories'),
('clothing','Clothing'),
('food','Food'),
('vehicles','Vehicles')
ON DUPLICATE KEY UPDATE displayName=VALUES(displayName);

INSERT INTO products (id, name, description, price, tags) VALUES
('cc789f85-1476-452a-8100-9e74502198e0','Temporal Tickstopper','Stop time for 30 seconds with this vintage-styled pocket watch. Features mechanical wind-up power reserve and temporal disruption failsafe. Includes leather carrying pouch and temporal paradox insurance.',250,'accessories'),
('87e89b11-d319-446d-b9be-50adcca5224a','Up & Away Parasol','This innocent-looking umbrella conceals a powerful grappling hook system with 50-meter range. Features weather-resistant fabric, built-in compass, and automatic hook retraction. Includes spare hooks and basic parkour instructions.',125,'clothing'),
('4f18544b-70a5-4352-8e19-0d070f46745d','Levitator Oxfords','Classic Oxford-style shoes concealing cutting-edge anti-gravity technology. Features wall-walking capability, ceiling-escape mode, and auto-stabilization. Available in black or brown. Not recommended for formal dances.',210,'clothing'),
('79bce3f3-935f-4912-8c62-0d2f3e059405','Facechanger Formal Wear','Transform your appearance instantly with this high-tech bowtie. Features 100 pre-loaded faces, custom face scanning capability, and voice modulation. Battery lasts up to 8 hours on a single charge.',70,'clothing'),
('d27cf49f-b689-4a75-a249-d373e0330bb5','The Quiet Quill','Control sound waves with this sophisticated pen. Create silence bubbles or emit targeted sonic blasts with simple clicks. Includes premium ink cartridge and electromagnetic interference shield. Actually writes quite smoothly.',150,'accessories'),
('1ca35e86-4b4c-4124-b6b5-076ba4134d0d','The Forgetter MK-II','These stylish shades pack a powerful amnesia-inducing flash that erases the last 60 seconds of memory from anyone in view. Includes UV protection and auto-darkening lenses. Not recommended for use during important meetings.',225,'accessories'),
('631a3db5-ac07-492c-a994-8cd56923c112','The Morning Teleporter','Create instant portals to pre-programmed locations with this ceramic marvel. Perfect for quick escapes or coffee runs. Features thermal insulation and spill-proof portal containment. Dishwasher safe on low heat.',40,'accessories'),
('8757729a-c518-4356-8694-9e795a9b3237','Forget-Me-Pop','This innovative bubblegum creates localized amnesia in your target for 5 minutes per piece. Features three brain-tingling flavors: Forgotten Fruit, Mindwipe Mint, and Blank-Berry. Includes warning label: Do not accidentally pop bubble on yourself.',20,'food'),
('d4edfedb-dbe9-4dd9-aae8-009489394955','Audio-Illusion Spinner','Professional-grade sonic illusion generator disguised as a simple yo-yo. Creates realistic sound effects from footsteps to full orchestras. Includes comprehensive training manual and anti-tangle technology.',190,'accessories'),
('a1258cd2-176c-4507-ade6-746dab5ad625','Aqua Ace GT','Transform your luxury sports car into a high-speed submarine with the push of a button. Features hydro-jet propulsion, underwater navigation, and oxygen recycling system for up to 8 hours. Includes coral-proof paint coating.',10000,'vehicles'),
('d3104128-1d14-4465-99d3-8ab9267c687b','SkyCycle X-1000','Switch from road to air travel instantly with this cutting-edge motorcycle. Features vertical takeoff capability, stealth mode, and auto-stabilization system. Includes emergency parachute and cloud-navigation GPS.',9000,'vehicles'),
('d77f9ae6-e9a8-4a3e-86bd-b72af75cbc49','Phantom Pursuit','Create perfect duplicates of your vehicle to confuse pursuers. Features multi-angle projection, realistic physics simulation, and remote control capability. Includes tactical evasion manual.',15000,'vehicles')
ON DUPLICATE KEY UPDATE
name=VALUES(name), description=VALUES(description), price=VALUES(price), tags=VALUES(tags);
