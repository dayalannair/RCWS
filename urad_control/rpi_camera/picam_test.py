from picamera import PiCamera
from time import sleep
import threading
# camera = PiCamera()

# STILL IMAGE
# camera.resolution = (1024, 768)
# # Camera warm-up time
# sleep(2)
# camera.capture('pythcamtest.jpg')

# VIDEO
# camera.resolution = (640, 480)
# camera.start_recording('my_video.h264')
# camera.wait_recording(10)
# camera.stop_recording()


# SEPARATE FILE VIDEO
# ensure that transition is smooth
# set file names
# camera = PiCamera(resolution=(640, 480))
# for filename in camera.record_sequence(
#         '%d.h264' % i for i in range(1, 11)):
#     camera.wait_recording(5)

camera = PiCamera()
# THREADED VIDEO 
def record_video():
    camera.resolution = (640, 480)
    camera.start_recording('threadvid.h264')
    camera.wait_recording(10)
    camera.stop_recording()

try:
    threading.Thread(target=record_video)

except: 
    print("Thread failed") 
