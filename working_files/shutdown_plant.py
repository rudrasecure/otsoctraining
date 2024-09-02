from pymodbus.client.sync import ModbusTcpClient

# Create a Modbus client
client = ModbusTcpClient('192.168.95.2',port=502)

# Connect to the client
client.connect()

# Read holding registers starting at address 100, reading 2 registers
response = client.write_coil(40, 1)

# Close the client connection
client.close()
