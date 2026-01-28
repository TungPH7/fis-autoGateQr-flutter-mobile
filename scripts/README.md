# Scripts

Scripts to manage Firebase data for AutoGateQR.

## Setup

### 1. Install dependencies

```bash
cd scripts
pip install -r requirements.txt
```

### 2. Download Firebase Service Account Key

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Go to **Project Settings** (gear icon) > **Service Accounts**
4. Click **"Generate new private key"**
5. Save the JSON file as `serviceAccountKey.json` in the `scripts` folder

```
scripts/
├── add_gates.py
├── requirements.txt
├── README.md
└── serviceAccountKey.json  <-- Put your key here
```

> ⚠️ **Important:** Never commit `serviceAccountKey.json` to version control!

## Scripts

### add_gates.py

Add gates to the Firebase Firestore database.

```bash
python add_gates.py
```

**Options:**
1. **Add gates** - Add predefined gates to database
2. **List all gates** - Show all gates in database
3. **Delete all gates** - Remove all gates (use with caution!)
4. **Exit**

**Customize gates:**

Edit the `GATES_DATA` list in the script:

```python
GATES_DATA = [
    {
        "gateCode": "GATE-01",
        "gateName": "Cổng chính",
        "gateType": "both",  # 'in', 'out', or 'both'
        "isActive": True,
        "assignedGuards": [],
        "location": None,
    },
    # Add more gates...
]
```

**Gate Types:**
- `"in"` - Entry only gate
- `"out"` - Exit only gate
- `"both"` - Entry and exit gate

## Firebase Collection Structure

### `gates` collection

| Field | Type | Description |
|-------|------|-------------|
| `gateCode` | string | Unique gate code (e.g., "GATE-01") |
| `gateName` | string | Display name (e.g., "Cổng chính") |
| `gateType` | string | "in", "out", or "both" |
| `isActive` | boolean | Whether gate is active |
| `assignedGuards` | array | List of guard user IDs |
| `location` | GeoPoint | GPS coordinates (optional) |
| `createdAt` | timestamp | Creation timestamp |
| `updatedAt` | timestamp | Last update timestamp |
