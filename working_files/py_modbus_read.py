from pymodbus.client.sync import ModbusTcpClient

# Create a Modbus client
client = ModbusTcpClient('192.168.95.2',port=502)

# Connect to the client
client.connect()

# Read holding registers starting at address 100, reading 2 registers
response = client.read_holding_registers(address=1026, count=1, unit=1)

# Check if the response is valid
if response.isError():
    print("Error reading holding registers")
else:
    print("Register values:", response.registers)

# Close the client connection
client.close()
