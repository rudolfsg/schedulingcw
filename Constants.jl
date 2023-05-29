module Constants

# Precedence relation matrix
const G = zeros(Int16, 31, 31)
G[1, 31] = 1
G[2, 1] = 1
G[3, 8] = 1
G[4, 3] = 1
G[5, 2] = 1
G[6, 16] = 1
G[7, 6] = 1
G[8, 7] = 1
G[9, 8] = 1
G[10, 9] = 1
G[11, 5] = 1
G[12, 5] = 1
G[13, 12] = 1
G[14, 13] = 1
G[15, 11] = 1
G[16, 15] = 1
G[17, 16] = 1
G[18, 17] = 1
G[19, 18] = 1
G[20, 19] = 1
G[21, 18] = 1
G[22, 21] = 1
G[23, 22] = 1
G[24, 5] = 1
G[25, 24] = 1
G[26, 25] = 1
G[27, 26] = 1
G[28, 26] = 1
G[29, 28] = 1
G[30, 4] = 1
G[30, 10] = 1
G[30, 14] = 1
G[30, 20] = 1
G[30, 23] = 1
G[30, 27] = 1
G[30, 29] = 1

const due_dates = Vector{Int16}(
    [172, 82, 18, 61, 93, 71, 217, 295, 290, 287, 253, 307, 279, 73, 355, 34, 233, 77, 88, 122, 71, 181, 340, 141, 209, 217, 256, 144, 307, 329, 269]
)

const name_dict = Dict{Int16,String}(1 => "onnx_1", 2 => "muse_1", 3 => "emboss_1", 4 => "emboss_2", 5 => "blur_1", 6 => "emboss_3", 7 => "vii_1", 8 => "blur_2", 9 => "wave_1",
    10 => "blur_3", 11 => "blur_4", 12 => "emboss_4", 13 => "onnx_2", 14 => "onnx_3", 15 => "blur_5", 16 => "wave_2", 17 => "wave_3", 18 => "wave_4", 19 => "emboss_5", 20 => "onnx_4", 21 => "emboss_6",
    22 => "onnx_5", 23 => "vii_2", 24 => "blur_6", 25 => "night_1", 26 => "muse_2", 27 => "emboss_7", 28 => "onnx_6", 29 => "wave_5", 30 => "emboss_8", 31 => "muse_3",
)

# SUBMISSION PROCESSING TIMES
# Processing Time of vii :	18.8609 ± 0.7362 s
# Processing Time of blur :	5.5183 ± 0.1368 s
# Processing Time of night :	22.4894 ± 0.7375 s
# Processing Time of onnx :	2.8342 ± 0.1242 s
# Processing Time of emboss :	1.7477 ± 0.6833 s
# Processing Time of muse :	14.4640 ± 0.5424 s
# Processing Time of wave :	10.0377 ± 0.7100 s
const processing_times_q2_dict = Dict{String,Float64}("vii" => 18.8609, "blur" => 5.5183, "night" => 22.4894, "onnx" => 2.8342,
    "emboss" => 1.7477, "muse" => 14.4640, "wave" => 10.0377)

def_processing_times = []

for i in 1:length(due_dates)
    name = name_dict[i]
    name = name[1:end-2]
    append!(def_processing_times, processing_times_q2_dict[name])
end

const processing_times_q2 = Vector{Float64}(def_processing_times)


##### Question 3 processing times

const processing_times_q3_dict = Dict{String,Float64}("vii" => 21, "blur" => 6, "night" => 25, "onnx" => 4,
    "emboss" => 2, "muse" => 17, "wave" => 13)

def_processing_times = []

for i in 1:length(due_dates)
    name = name_dict[i]
    name = name[1:end-2]
    append!(def_processing_times, processing_times_q3_dict[name])
end

const processing_times_q3 = Vector{Float64}(def_processing_times)


const all_nodes = Vector{Int16}(1:length(processing_times_q2))


end