# Library for loading various types of data in various ways as part of the
# MSc project for dual lane monitoring using radars
# Allows for chaning file and subset length in one place and viewing the results using different scripts

from pathlib import Path

def load_data():
    

    # file_path = Path(r"C:\Users\naird\OneDrive - University of Cape Town\RCWS_DATA\car_driveby\IQ_tri_20kmh.txt")
    # file_path = Path(r"C:\Users\naird\OneDrive - University of Cape Town\RCWS_DATA\car_driveby\IQ_tri_30kmh.txt")
    # file_path = Path(r"C:\Users\naird\OneDrive - University of Cape Town\RCWS_DATA\car_driveby\IQ_tri_40kmh.txt")
    # file_path = Path(r"C:\Users\naird\OneDrive - University of Cape Town\RCWS_DATA\car_driveby\IQ_tri_50kmh.txt")
    file_path = Path(r"C:\Users\naird\OneDrive - University of Cape Town\RCWS_DATA\car_driveby\IQ_tri_60kmh.txt")

    # file_path = Path(r"C:\Users\Dayalan Nair\OneDrive - University of Cape Town\RCWS_DATA\car_driveby\IQ_tri_60kmh.txt")

    # file_path = Path(r"C:\Users\naird\OneDrive - University of Cape Town\RCWS_DATA\road_data_03_11_2022\iq_data\lhs_iq_12_18_12.txt")
    # file_path = Path(r"C:\Users\naird\OneDrive - University of Cape Town\RCWS_DATA\road_data_03_11_2022\iq_data\rhs_iq_12_18_12.txt")



    # file_path = Path(r"C:\Users\naird\OneDrive - University of Cape Town\RCWS_DATA\road_data_10_02_2023\iq_data\lhs_iq_14_51_49.txt")
    # file_path = Path(r"C:\Users\naird\OneDrive - University of Cape Town\RCWS_DATA\road_data_10_02_2023\iq_data\rhs_iq_14_51_49.txt")

    # file_path = Path(r"C:\Users\naird\OneDrive - University of Cape Town\RCWS_DATA\road_data_10_02_2023\iq_data\lhs_iq_14_52_54.txt")


    # On laptop Yoga 910

    # file_path = Path(r"C:\Users\Dayalan Nair\OneDrive - University of Cape Town\RCWS_DATA\car_driveby\IQ_tri_60kmh.txt")
    # file_path = Path(r"C:\Users\Dayalan Nair\OneDrive - University of Cape Town\RCWS_DATA\")

    # on Dell XPS 13
    # file_path = Path(r"C:\Users\pregg\Desktop\road_data_31_01_2023\rhs_iq_13_45_20.txt")

    # =============================================================================================
    # 3 March 2023
    # =============================================================================================

    # file_path = Path(r"C:\Users\naird\OneDrive - University of Cape Town\RCWS_DATA\road_data_03_03_2023\iq_data\lhs_iq_12_57_07.txt")
    # file_path = Path(r"C:\Users\naird\OneDrive - University of Cape Town\RCWS_DATA\road_data_03_03_2023\iq_data\rhs_iq_12_57_07.txt")


    # file_path = Path(r"C:\Users\Dayalan Nair\OneDrive - University of Cape Town\RCWS_DATA\road_data_03_03_2023\iq_data\rhs_iq_12_57_07.txt")


    # file_path = Path(r"C:\Users\naird\OneDrive - University of Cape Town\RCWS_DATA\road_data_03_03_2023\iq_data\lhs_iq_12_57_50.txt")

    # file_path = Path(r"C:\Users\naird\OneDrive - University of Cape Town\RCWS_DATA\road_data_03_03_2023\iq_data\lhs_iq_12_52_43.txt")
    # file_path = Path(r"C:\Users\naird\OneDrive - University of Cape Town\RCWS_DATA\road_data_03_03_2023\iq_data\rhs_iq_12_52_43.txt")

    # Yoga - user name is Dayalan Nair not naird. MATLAB does not need the absolute path so it works on both devices
    # file_path = Path(r"C:\Users\Dayalan Nair\OneDrive - University of Cape Town\RCWS_DATA\road_data_03_03_2023\iq_data\lhs_iq_12_57_07.txt")
    # file_path = Path(r"C:\Users\Dayalan Nair\OneDrive - University of Cape Town\RCWS_DATA\road_data_03_03_2023\iq_data\rhs_iq_12_57_07.txt")


    # 60kmh subset
    subset = range(700,1100)
    # subset = range(0, 4000)

    # subset = range(0, 2700)

    
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
    # file_path_lhs = Path(r"C:\\Users\\naird\\OneDrive - University of Cape Town\\RCWS_DATA\\road_data_05_11_2022\\iq_data\\lhs_iq_11_01_36.txt")
    # file_path_rhs = Path(r"C:\\Users\\naird\\OneDrive - University of Cape Town\\RCWS_DATA\\road_data_05_11_2022\\iq_data\\rhs_iq_11_01_36.txt")

    # subset = range(0, 4000)
    subset = range(500, 2000)
    # 50 kmh subset - same
    # 40 kmh subset
    # subset = range(700,1100)
    # 20km/h subset
    # subset = range(1,1500)
    file_path_lhs = Path(r"C:\Users\pregg\Desktop\road_data_31_01_2023\lhs_iq_13_45_20.txt")
    file_path_rhs = Path(r"C:\Users\pregg\Desktop\road_data_31_01_2023\rhs_iq_13_45_20.txt")
    # sys.path.append('../../../../../OneDrive - University of Cape Town/RCWS_DATA/car_driveby')
    
    with open(file_path_lhs, "r") as raw_IQ_lhs:
        lhs = raw_IQ_lhs.read().split("\n")

    with open(file_path_rhs, "r") as raw_IQ_rhs:
        rhs = raw_IQ_rhs.read().split("\n")
    return lhs, rhs, subset


def load_proc_data():
    
    # file_path_lhs = Path(r"lhs_speed_results.txt")
    # file_path_rhs = Path(r"rhs_speed_results.txt")

    # subset = range(0, 4000)
    subset = range(0, 350)
    # 50 kmh subset - same
    # 40 kmh subset
    # subset = range(700,1100)
    # 20km/h subset
    # subset = range(1,1500)

    # sys.path.append('../../../../../OneDrive - University of Cape Town/RCWS_DATA/car_driveby')
     # =============================================================================================
    # 3 March 2023
    # =============================================================================================

    # file_path = Path(r"C:\Users\naird\OneDrive - University of Cape Town\RCWS_DATA\road_data_03_03_2023\iq_data\lhs_iq_12_57_07.txt")
    # file_path = Path(r"C:\Users\naird\OneDrive - University of Cape Town\RCWS_DATA\road_data_03_03_2023\iq_data\rhs_iq_12_57_07.txt")

    # file_path = Path(r"C:\Users\naird\OneDrive - University of Cape Town\RCWS_DATA\road_data_03_03_2023\iq_data\lhs_iq_12_57_50.txt")

    # file_path = Path(r"C:\Users\naird\OneDrive - University of Cape Town\RCWS_DATA\road_data_03_03_2023\iq_data\lhs_iq_12_52_43.txt")
    # file_path = Path(r"C:\Users\naird\OneDrive - University of Cape Town\RCWS_DATA\road_data_03_03_2023\iq_data\rhs_iq_12_52_43.txt")

    # Yoga - user name is Dayalan Nair not naird. MATLAB does not need the absolute path so it works on both devices
    file_path_lhs = Path(r"C:\Users\naird\OneDrive - University of Cape Town\RCWS_DATA\road_data_03_03_2023\rt_proc_data\2thd_lhs_speed_results_12_54_30.txt")
    file_path_rhs = Path(r"C:\Users\naird\OneDrive - University of Cape Town\RCWS_DATA\road_data_03_03_2023\rt_proc_data\2thd_rhs_speed_results_12_54_30.txt")
    # file_path = Path(r"C:\Users\Dayalan Nair\OneDrive - University of Cape Town\RCWS_DATA\road_data_03_03_2023\iq_data\rhs_iq_12_57_07.txt")

    file_path_lhs = Path(r"C:\Users\naird\OneDrive - University of Cape Town\RCWS_DATA\road_data_03_03_2023\rt_proc_data\2thd_lhs_speed_results_12_59_14.txt")
    file_path_rhs = Path(r"C:\Users\naird\OneDrive - University of Cape Town\RCWS_DATA\road_data_03_03_2023\rt_proc_data\2thd_rhs_speed_results_12_59_14.txt")
    
    file_path_lhs = Path(r"C:\Users\naird\OneDrive - University of Cape Town\RCWS_DATA\road_data_03_03_2023\rt_proc_data\2thd_lhs_speed_results_12_58_38.txt")
    file_path_rhs = Path(r"C:\Users\naird\OneDrive - University of Cape Town\RCWS_DATA\road_data_03_03_2023\rt_proc_data\2thd_rhs_speed_results_12_58_38.txt")

    file_path_lhs = Path(r"C:\Users\naird\OneDrive - University of Cape Town\RCWS_DATA\road_data_03_03_2023\rt_proc_data\2thd_lhs_speed_results_12_59_14.txt")
    file_path_rhs = Path(r"C:\Users\naird\OneDrive - University of Cape Town\RCWS_DATA\road_data_03_03_2023\rt_proc_data\2thd_rhs_speed_results_12_59_14.txt")
    
    
    


    with open(file_path_lhs, "r") as raw_IQ_lhs:
        lhs = raw_IQ_lhs.read().split("\n")

    with open(file_path_rhs, "r") as raw_IQ_rhs:
        rhs = raw_IQ_rhs.read().split("\n")

    # rhs = []
    return lhs, rhs, subset


def load_video():
    lhs_vid_name = Path(r"C:\Users\naird\OneDrive - University of Cape Town\RCWS_DATA\road_data_03_11_2022\iq_vid\lhs_vid_12_18_12.avi")
    rhs_vid_name = Path(r"C:\Users\naird\OneDrive - University of Cape Town\RCWS_DATA\road_data_03_11_2022\iq_vid\rhs_vid_12_18_12.avi")

    return lhs_vid_name, rhs_vid_name