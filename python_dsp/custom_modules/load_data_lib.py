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


    file_path = Path(r"C:\Users\naird\OneDrive - University of Cape Town\RCWS_DATA\road_data_03_11_2022\iq_data\lhs_iq_12_18_12.txt")

    # On laptop Yoga 910

    # file_path = Path(r"C:\Users\Dayalan Nair\OneDrive - University of Cape Town\RCWS_DATA\car_driveby\IQ_tri_60kmh.txt")
    # file_path = Path(r"C:\Users\Dayalan Nair\OneDrive - University of Cape Town\RCWS_DATA\")

    # 60kmh subset
    # subset = range(800,1100)

    subset = range(0, 5000)

    len_subset = len(subset)
    print("Subset length: ", str(len_subset))
    # 50 kmh subset - same
    # 40 kmh subset
    # subset = range(700,1100)
    # 20km/h subset
    # subset = range(1,1500)

    # sys.path.append('../../../../../OneDrive - University of Cape Town/RCWS_DATA/car_driveby')
    with open(file_path, "r") as raw_IQ:
            # split into sweeps
            sweeps = raw_IQ.read().split("\n")

    return sweeps, len_subset