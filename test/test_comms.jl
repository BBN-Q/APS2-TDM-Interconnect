using ProgressMeter
using Base.Test

"""
	test_comms(a::IPv4, b::IPv4, num_packets)

Test SATA comms from device a to device b by sending and checking num_packets.
"""
function test_comms(a::IPv4, b::IPv4, num_packets)

	sock_a = connect(a, 0xbb4e)
	sock_b = connect(b, 0xbb4e)

	packet_data = collect(map(UInt8, 1:255))
	@showprogress for ct = 1:num_packets
		write(sock_a, packet_data)
		sleep(0.001)
		@test readavailable(sock_b) == packet_data
	end

	close(sock_a)
	close(sock_b)
end
