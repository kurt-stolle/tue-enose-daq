# Electronic Nose DAQ
Data acquisition script for an Arduino Nano based e-nose with vairable resistors and up to 8 gas sensors (analog ports 1-8).

Includes Matlab classes, applications and scripts that use this DAQ to collect data from an e-nose setup.

# Commands
Commands are issued via a Serial connection at a symbol rate of 115200 Baud. To issue a command, send the corresponding character over the connection followd by possible parameters. All unknown characters are ignored.

Avaiable commands are summarized in the following table.

| Command | Parameters | Description                                        |
| :---:   |    :---:   |   :---                                             |
| m       |            | Starts measurement stream over Serial              |
| i       |            | Print current sampling rate in Hz                  |
| r       |            | Reset state - stops measurement stream             |
| s       |    float   | Set the sampling rate in Hz                        |
| c       |  int  int  | Set the i-th potmeter to a value between 0 and 255 |

A successfully issued command will always return `ok` over the Serial connection.

# Measurement stream
The measurement stream, which starts once the `m` command is issued, consists of a continuous sequence of the 20 bytes. The first four bytes are a float that corresponds to the time index. Next, for each sensor two bytes are sent that represent an int for the measured value.