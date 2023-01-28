# Library for loading various types of data in various ways as part of the
# MSc project for dual lane monitoring using radars
# Allows for chaning file and subset length in one place and viewing the results using different scripts

from pathlib import Path

def load_data():
    

    # file_path = Path(r"C:\Users\naird\OneDrive - University of Cape Town\RCWS_DATA\car_driveby\IQ_tri_20kmh.txt")
    # file_path = Path(r"C:\Users\naird\OneDrive - University of Cape Town\RCWS_DATA\car_driveby\IQ_tri_30kmh.txt")
    # file_path = Path(r"C:\Users\naird\OneDrive - University of Cape Town\RCWS_DATA\car_driveby\IQ_tri_40kmh.txt")
    # file_path = Path(r"C:\Users\naird\OneDrive - University of Cape Town\RCWS_DATA\car_driveby\IQ_tri_50kmh.txt")
    # file_path = Path(r"C:\Users\naird\OneDrive - University of Cape Town\RCWS_DATA\car_driveby\IQ_tri_60kmh.txt")


    # file_path = Path(r"C:\Users\naird\OneDrive - University of Cape Town\RCWS_DATA\road_data_03_11_2022\iq_data\lhs_iq_12_18_12.txt")
    file_path = Path(r"C:\Users\naird\OneDrive - University of Cape Town\RCWS_DATA\road_data_03_11_2022\iq_data\rhs_iq_12_18_12.txt")

    # On laptop Yoga 910

    # file_path = Path(r"C:\Users\Dayalan Nair\OneDrive - University of Cape Town\RCWS_DATA\car_driveby\IQ_tri_60kmh.txt")
    # file_path = Path(r"C:\Users\Dayalan Nair\OneDrive - University of Cape Town\RCWS_DATA\")

    # 60kmh subset
    # subset = range(800,1100)
    # subset = range(0, 4000)

    subset = range(0, 5000)

    
    # 50 kmh subset - same
    # 40 kmh subset
    # subset = range(700,1100)
    # 20km/h subset
    # subset = range(1,1500)

    # sys.path.append('../../../../../OneDrive - University of Cape Town/RCWS_DATA/car_driveby')
    with open(file_path, "r") as raw_IQ:
            # split into sweeps
            sweeps = raw_IQ.read().split("\n")
    return sweeps, subset


def load_dual_data():
    # folder = "road_data_03_11_2022"
    folder = "road_data_05_11_2022"
    # time = "12_18_12"
    time = "11_01_36"
    file_path_lhs = Path(r"C:\\Users\\naird\\OneDrive - University of Cape Town\\RCWS_DATA\\road_data_05_11_2022\\iq_data\\lhs_iq_11_01_36.txt")
    file_path_rhs = Path(r"C:\\Users\\naird\\OneDrive - University of Cape Town\\RCWS_DATA\\road_data_05_11_2022\\iq_data\\rhs_iq_11_01_36.txt")

    # subset = range(0, 4000)
    subset = range(0, 5000)
    # 50 kmh subset - same
    # 40 kmh subset
    # subset = range(700,1100)
    # 20km/h subset
    # subset = range(1,1500)

    # sys.path.append('../../../../../OneDrive - University of Cape Town/RCWS_DATA/car_driveby')
    
    with open(file_path_lhs, "r") as raw_IQ_lhs:
        lhs = raw_IQ_lhs.read().split("\n")

    with open(file_path_rhs, "r") as raw_IQ_rhs:
        rhs = raw_IQ_rhs.read().split("\n")
    return lhs, rhs, subset


def load_proc_data():
    
    file_path_lhs = Path(r"lhs_speed_results.txt")
    file_path_rhs = Path(r"rhs_speed_results.txt")

    # subset = range(0, 4000)
    subset = range(0, 5000)
    # 50 kmh subset - same
    # 40 kmh subset
    # subset = range(700,1100)
    # 20km/h subset
    # subset = range(1,1500)

    # sys.path.append('../../../../../OneDrive - University of Cape Town/RCWS_DATA/car_driveby')
    
    with open(file_path_lhs, "r") as raw_IQ_lhs:
        lhs = raw_IQ_lhs.read().split("\n")

    with open(file_path_rhs, "r") as raw_IQ_rhs:
        rhs = raw_IQ_rhs.read().split("\n")
    return lhs, rhs, subset


def load_video():
    lhs_vid_name = Path(r"C:\Users\naird\OneDrive - University of Cape Town\RCWS_DATA\road_data_03_11_2022\iq_vid\lhs_vid_12_18_12.avi")
    rhs_vid_name = Path(r"C:\Users\naird\OneDrive - University of Cape Town\RCWS_DATA\road_data_03_11_2022\iq_vid\rhs_vid_12_18_12.avi")

    return lhs_vid_name, rhs_vid_name