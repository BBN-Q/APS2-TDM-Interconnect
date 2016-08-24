using ProgressMeter
using Base.Test

sock_aps2 = connect(ip"192.168.2.200", 0xbb4e)
sock_tdm = connect(ip"192.168.2.201", 0xbb4e)

packet_data = collect(map(UInt8, 1:255))
@showprogress for ct = 1:100000
	write(sock_tdm, cat(1, [0x55, 0x55, 0xD5], packet_data))
	while read(sock_aps2, UInt8, 1) != [0xD5] end
	@test readavailable(sock_aps2) == packet_data

	write(sock_aps2, cat(1, [0x55, 0x55, 0xD5], packet_data))
	while read(sock_tdm, UInt8, 1) != [0xD5] end
	@test readavailable(sock_tdm) == packet_data
end

close(sock_aps2)
close(sock_tdm)
