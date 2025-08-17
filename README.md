# GPS Tracker DataField

A Garmin Connect IQ DataField application that tracks distance, bearing, and time from a reference LAP point.    
The application is designed to assist in navigating to points in the field for which we know the direction and distance.
<img width="631" height="870" alt="screen" src="https://github.com/user-attachments/assets/b736c9b2-9871-4358-881f-44cd6a46481f" />


## Features

- **Straight-line distance**: Shows direct distance from LAP point to current position
- **Total distance traveled**: Shows actual distance covered since LAP point
- **Bearing**: Shows direction to LAP point in degrees
- **Elapsed time**: Shows time since LAP point was set
- **LAP counter**: Shows number of LAP resets

## Usage

### Setting LAP Point
- Press **LAP button** on your Garmin device

### Display Information
The DataField shows 4 lines of information:
1. **Direct: XXX m** - Straight-line distance to LAP point
2. **Total: XXX m** - Total distance traveled since LAP point
3. **Bearing: XXX°** - Bearing to LAP point
4. **Time: MM:SS** - Time elapsed since LAP point

## Supported Devices

- Garmin Epix 2 Pro 47mm
- (Other devices can be added by modifying manifest.xml)

## Installation

1. Download the `.prg` file from releases
2. Copy to your Garmin device's `GARMIN/APPS` folder
3. Or install via Garmin Connect IQ Manager

## Development

### Building

```bash
monkeyc -d epix2pro47mm -f monkey.jungle -o bin/orienteringHelper.prg -y /path/to/developer_key
```

### Requirements

- Garmin Connect IQ SDK
- Developer key for signing

## Version History

- **v1.0.0** - Initial release
  - Basic distance and bearing tracking
  - LAP point reset functionality
  - Time tracking from LAP point

## Author

Dominik Pietrzak

## License

This project is licensed under the MIT License - see the <a target="_blank" href="https://mit-license.org/">LICENSE</a> for details.
