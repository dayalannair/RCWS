import uRAD_USB_SDK11		# import uRAD libray
import uRAD_processing
import sys
import os
import serial
import serial.tools.list_ports
from datetime import datetime
from PyQt5.QtWidgets import QApplication, QMainWindow, QVBoxLayout, QWidget, QSizePolicy
from PyQt5.QtCore import QTimer
from PyQt5 import uic
from pyqtgraph.Qt import QtCore, QtGui
from time import sleep, time
import numpy as np
from numpy.fft import fft, fftshift
import pyqtgraph as pg

# Clase creada exclusivamente para girar -90 grados textos
class MyLabel(QtGui.QWidget):
    def __init__(self, text=None):
        super(self.__class__, self).__init__()
        self.text = text

    def paintEvent(self, event):
        painter = QtGui.QPainter(self)
        painter.setPen(QtCore.Qt.black)
        painter.translate(10, 120)
        painter.rotate(-90)
        if self.text:
            painter.drawText(0, 0, self.text)
        painter.end()

# Clase heredada de QMainWindow (Constructor de ventanas)
class Ventana(QMainWindow):

    # Método constructor de la clase
    def __init__(self):
        # Iniciar el objeto QMainWindow
        QMainWindow.__init__(self)
        # Get path to 'GUI' folder
        global common_path
        root_directory = ['GUI_windows', 'GUI_linux', 'GUI_mac']
        path = os.getcwd()
        success = False

        subfolders = 0
        while (not success and subfolders < 8):
            head, tail = os.path.split(path)
            for folder in root_directory:
                if (tail == folder):
                    success = True
                    common_path = path
                    break
            path = head
            subfolders += 1

        if (not success):
            print('root directory not found')
            sys.exit()

        # Cargar la configuración del archivo .ui en el objeto
        uic.loadUi(common_path + "/resources/ui/uRAD.ui", self)
        #self.controlwidget.setStyleSheet("background-color: rgb(227, 243, 248);")
        self.runButton.setStyleSheet("background-color: rgb(73, 166, 191); color: rgb(255, 255, 255); border: none;")
        self.updatePLLconfig.setStyleSheet("background-color: rgb(70, 70, 70); color: rgb(255, 255, 255); border: none;")

        self.footerWidget.setStyleSheet("background-color: rgb(70, 70, 70);")
        self.tabWidget.setStyleSheet("background-color: rgb(255, 255, 255);")
        self.centralwidget.setStyleSheet("background-color: rgb(227, 243, 248);")
        self.label_Copyright.setStyleSheet("color: rgb(227, 243, 248);")
        self.label_email.setStyleSheet("color: rgb(227, 243, 248);")

        self.f0_Desired.setStyleSheet("background-color: rgb(255, 255, 255);")
        self.f0_GHz.setStyleSheet("background-color: rgb(255, 255, 255);")
        self.BW_Desired.setStyleSheet("background-color: rgb(255, 255, 255);")
        self.Samples_Desired.setStyleSheet("background-color: rgb(255, 255, 255);")
        self.Ntar_Desired.setStyleSheet("background-color: rgb(255, 255, 255);")
        
        self.refreshPortButton.setStyleSheet("background-color: rgb(255, 255, 255);")
        self.PortsList.setStyleSheet("background-color: rgb(255, 255, 255);")
        self.Mth_Desired.setStyleSheet("background-color: rgb(255, 255, 255);")
        self.Alpha_Desired.setStyleSheet("background-color: rgb(255, 255, 255);")
        self.MovingTargetIndicator.setStyleSheet("background-color: rgb(255, 255, 255);")
        #self.updatePLLconfig.setStyleSheet("background-color: rgb(255, 255, 255);")
        self.DistanceUnits_FMCW_sawtooth.setEditable(True)
        self.DistanceUnits_FMCW_sawtooth.lineEdit().setReadOnly(True)
        self.DistanceUnits_FMCW_sawtooth.lineEdit().setAlignment(QtCore.Qt.AlignCenter)
        self.SpeedUnits_CW.setEditable(True)
        self.SpeedUnits_CW.lineEdit().setReadOnly(True)
        self.SpeedUnits_CW.lineEdit().setAlignment(QtCore.Qt.AlignCenter)

        # Añadimos un título al programa
        self.setWindowTitle('uRAD 24 GHz Module')
        # Icono pequeño con el logo de Anteral
        self.setWindowIcon(QtGui.QIcon(common_path + "/resources/images/simbolo_urad_original.ico"))
        # Conectamos el botón de Run/Stop con el método "run_stop_code"
        self.runButton.toggled.connect(self.run_stop_code)
        # Conectamos el botón de refrescar los puertos serie con su SLOT correspondiente
        self.refreshPortButton.clicked.connect(self.update_serial_ports_list)
        # Hints Display
        self.f0_Desired.setToolTip("Initial frequency: 5 to 245")
        self.BW_Desired.setToolTip("Sweep Bandwidth: 50 to 240 MHz")
        self.Samples_Desired.setToolTip("Number of Samples: 50 to 200")
        self.Ntar_Desired.setToolTip("Maximum number of targets: 0 to 5")
        self.Ntar_Desired.setToolTip("Maximum number of targets: 0 to 5")
        self.Alpha_Desired.setToolTip("Alpha (CFAR Algorithm): 3 to 25 dB")
        #
        self.updatePLLconfig.clicked.connect(self.changeRegisters)

        label_1000 = MyLabel('Autoscale Y')
        hBoxLayout = QtGui.QHBoxLayout(self.widget_AutoScaleY_FMCW_triangle_DualRate_1)
        hBoxLayout.addWidget(label_1000)

        global movie_distance, movie_velocity, movie_movement

        movie_distance = QtGui.QMovie(common_path + "/resources/images/distancia2_small.gif")
        movie_velocity = QtGui.QMovie(common_path + "/resources/images/velocidad2_small.gif")
        movie_movement = QtGui.QMovie(common_path + "/resources/images/presencia2_small.gif")
        self.label_mode_1_velocity.setMovie(movie_velocity)
        self.label_mode_1_movement.setMovie(movie_movement)
        self.label_mode_2_distance.setMovie(movie_distance)
        self.label_mode_2_movement.setMovie(movie_movement)
        self.label_mode_3_distance.setMovie(movie_distance)
        self.label_mode_3_velocity.setMovie(movie_velocity)
        self.label_mode_3_movement.setMovie(movie_movement)
        self.label_mode_4_distance.setMovie(movie_distance)
        self.label_mode_4_velocity.setMovie(movie_velocity)
        self.label_mode_4_movement.setMovie(movie_movement)

        # Declaramos algunas variables como globales para que puedan ser utilizadas por los distintos métodos de la clase
        global IQ_FMCW_sawtooth_Plot, Distance_FMCW_sawtooth_Plot, IQ_CW_Plot, Velocity_CW_Plot, IQ_FMCW_triangle_Plot, Frequency_FMCW_triangle_Plot, IQ_FMCW_triangle_DualRate_Plot, RangeVelocityDisplay_FMCW_triangle_DualRate_Plot, Frequency_FMCW_triangle_DualRate_Plot 

        pg.setConfigOption('background', 'w')
        #pg.setConfigOption('foreground', 'k')
        #pg.setConfigOptions(antialias=True)

        CW_Figure = QVBoxLayout(self.CW_widget)
        #win_CW = pg.GraphicsWindow()
        #IQ_CW_Plot = win_CW.addPlot(title="IQ Data")
        win_CW = pg.QtGui.QMainWindow()
        MyView = pg.GraphicsLayoutWidget()
        win_CW.setCentralWidget(MyView)
        IQ_CW_Plot = MyView.addPlot(title="IQ Data")
        IQ_CW_Plot.setMouseEnabled(x=False, y=False)
        IQ_CW_Plot.setMenuEnabled(False)
        IQ_CW_Plot.hideButtons()
        #win_CW.nextRow()
        #Velocity_CW_Plot = win_CW.addPlot(title="Level received vs Velocity")
        MyView.nextRow()
        Velocity_CW_Plot = MyView.addPlot(title="Level received vs Velocity")
        Velocity_CW_Plot.setMouseEnabled(x=False, y=False)
        Velocity_CW_Plot.setMenuEnabled(False)
        Velocity_CW_Plot.hideButtons()
        CW_Figure.addWidget(win_CW)

        FMCW_sawtooth_Figure = QVBoxLayout(self.FMCW_sawtooth_widget)
        #win_FMCW_sawtooth = pg.GraphicsWindow()
        #IQ_FMCW_sawtooth_Plot = win_FMCW_sawtooth.addPlot(title="IQ Data")
        win_FMCW_sawtooth = pg.QtGui.QMainWindow()
        MyView = pg.GraphicsLayoutWidget()
        win_FMCW_sawtooth.setCentralWidget(MyView)
        IQ_FMCW_sawtooth_Plot = MyView.addPlot(title="IQ Data")
        IQ_FMCW_sawtooth_Plot.setMouseEnabled(x=False, y=False)
        IQ_FMCW_sawtooth_Plot.setMenuEnabled(False)
        IQ_FMCW_sawtooth_Plot.hideButtons()
        #win_FMCW_sawtooth.nextRow()
        #Distance_FMCW_sawtooth_Plot = win_FMCW_sawtooth.addPlot(title="Level received vs Distance")
        MyView.nextRow()
        Distance_FMCW_sawtooth_Plot = MyView.addPlot(title="Level received vs Distance")
        Distance_FMCW_sawtooth_Plot.setMouseEnabled(x=False, y=False)
        Distance_FMCW_sawtooth_Plot.setMenuEnabled(False)
        Distance_FMCW_sawtooth_Plot.hideButtons()
        FMCW_sawtooth_Figure.addWidget(win_FMCW_sawtooth)

        FMCW_triangle_Figure = QVBoxLayout(self.FMCW_triangle_widget)
        #win_FMCW_triangle = pg.GraphicsWindow()
        #IQ_FMCW_triangle_Plot = win_FMCW_triangle.addPlot(title="IQ Data")
        win_FMCW_triangle = pg.QtGui.QMainWindow()
        MyView = pg.GraphicsLayoutWidget()
        win_FMCW_triangle.setCentralWidget(MyView)
        IQ_FMCW_triangle_Plot = MyView.addPlot(title="IQ Data")
        IQ_FMCW_triangle_Plot.setMouseEnabled(x=False, y=False)
        IQ_FMCW_triangle_Plot.setMenuEnabled(False)
        IQ_FMCW_triangle_Plot.hideButtons()
        #win_FMCW_triangle.nextRow()
        #Frequency_FMCW_triangle_Plot = win_FMCW_triangle.addPlot(title="Ramps Spectrums")
        MyView.nextRow()
        Frequency_FMCW_triangle_Plot = MyView.addPlot(title="Ramps Spectrums")
        Frequency_FMCW_triangle_Plot.setMouseEnabled(x=False, y=False)
        Frequency_FMCW_triangle_Plot.setMenuEnabled(False)
        Frequency_FMCW_triangle_Plot.hideButtons()
        FMCW_triangle_Figure.addWidget(win_FMCW_triangle)

        IQ_Frequency_FMCW_triangle_DualRate_Figure = QVBoxLayout(self.IQ_Frequency_widget_FMCW_triangle_DualRate)
        #win_FMCW_triangle_DualRate_1 = pg.GraphicsWindow()
        #IQ_FMCW_triangle_DualRate_Plot = win_FMCW_triangle_DualRate_1.addPlot(title="IQ Data")
        win_FMCW_triangle_DualRate_1 = pg.QtGui.QMainWindow()
        MyView = pg.GraphicsLayoutWidget()
        win_FMCW_triangle_DualRate_1.setCentralWidget(MyView)
        IQ_FMCW_triangle_DualRate_Plot = MyView.addPlot(title="IQ Data")
        IQ_FMCW_triangle_DualRate_Plot.setMouseEnabled(x=False, y=False)
        IQ_FMCW_triangle_DualRate_Plot.setMenuEnabled(False)
        IQ_FMCW_triangle_DualRate_Plot.hideButtons()
        #win_FMCW_triangle_DualRate_1.nextRow()
        #Frequency_FMCW_triangle_DualRate_Plot = win_FMCW_triangle_DualRate_1.addPlot(title="Ramps Spectrums")
        MyView.nextRow()
        Frequency_FMCW_triangle_DualRate_Plot = MyView.addPlot(title="Ramps Spectrums")
        Frequency_FMCW_triangle_DualRate_Plot.setMouseEnabled(x=False, y=False)
        Frequency_FMCW_triangle_DualRate_Plot.setMenuEnabled(False)
        Frequency_FMCW_triangle_DualRate_Plot.hideButtons()
        IQ_Frequency_FMCW_triangle_DualRate_Figure.addWidget(win_FMCW_triangle_DualRate_1)

        RangeVelocityDisplay_FMCW_triangle_DualRate_Figure = QVBoxLayout(self.RangeVelocityDisplay_FMCW_triangle_DualRate)
        #win_FMCW_triangle_DualRate_2 = pg.GraphicsWindow()
        #RangeVelocityDisplay_FMCW_triangle_DualRate_Plot = win_FMCW_triangle_DualRate_2.addPlot(title="")
        win_FMCW_triangle_DualRate_2 = pg.QtGui.QMainWindow()
        MyView = pg.GraphicsLayoutWidget()
        win_FMCW_triangle_DualRate_2.setCentralWidget(MyView)
        RangeVelocityDisplay_FMCW_triangle_DualRate_Plot = MyView.addPlot(title="")
        RangeVelocityDisplay_FMCW_triangle_DualRate_Plot.setMouseEnabled(x=False, y=False)
        RangeVelocityDisplay_FMCW_triangle_DualRate_Plot.setMenuEnabled(False)
        RangeVelocityDisplay_FMCW_triangle_DualRate_Plot.hideButtons()
        RangeVelocityDisplay_FMCW_triangle_DualRate_Figure.addWidget(win_FMCW_triangle_DualRate_2)

        # Insertamos en el comboBox 'Port' la lista de puertos serie disponibles
        self.update_serial_ports_list()

        # Declaramos y configuramos el puerto serie, en el futuro la propiedad 'port' será seleccionable desde el programa, por lo que ser.open() deberá realizarse al presionar el botón de Run/Stop
        global ser
        ser = serial.Serial()
        ser.baudrate = 5e5
        ser.timeout = 5
        ser.bytesize = serial.EIGHTBITS
        ser.parity = serial.PARITY_NONE
        ser.stopbits = serial.STOPBITS_ONE
        ser.xonxoff = False
        ser.rtscts = False
        ser.dsrdtr = False
        ser.write_timeout = 5

        # Booleans declarations
        global lastPresenceMode, FirstExecution_FMCW_sawtooth, FirstExecution_CW, FirstExecution_FMCW_triangle, FirstExecution_FMCW_triangle_DualRate, update, error
        FirstExecution_FMCW_sawtooth = True
        FirstExecution_CW = True
        FirstExecution_FMCW_triangle = True
        FirstExecution_FMCW_triangle_DualRate = True
        update = False
        error = False
        lastPresenceMode = 0

        # Numerics declaration
        global max_iterations_while_loop, Fs, Fs_CW, max_voltage, ADC_intervals
        max_iterations_while_loop = 1000000
        Fs = 200000 # Infineon microcontroller
        Fs_CW = 25000
        max_voltage = 3.3
        ADC_bits = 12
        ADC_intervals = 2**ADC_bits

        # Variables de procesado
        global max_fd
        max_fd = 12500

        global MaxIterations_Hold, Iterations_Hold, I_old, Q_old
        MaxIterations_Hold = 25
        Iterations_Hold = 0
        I_old = []
        Q_old = []

        # Arrays declaration
        global modes
        modes = []
        modes.append(1)
        modes.append(2)
        modes.append(3)
        modes.append(4)

    # Método que actualiza la lista desplegable que contiene los puertos disponibles
    def update_serial_ports_list(self):
        self.PortsList.clear()
        ports = list(serial.tools.list_ports.comports())
        index = 0
        for i in range(len(ports)):
            if ("Atmel" in ports[i].description or "Arduino" in ports[i].description or "Genuino" in ports[i].description):
                index = i
                self.PortsList.insertItem(i, ports[i].device + ' Arduino/Genuino')
            else:
                self.PortsList.insertItem(i, ports[i].device)
        self.PortsList.setCurrentIndex(index)

    # Método que es llamada por el botón de actualizar la configuración del PLL
    def changeRegisters(self):
        global update
        update = True

    # Método que controla la captura de tramas IQ, es llamado por la señal emitida por el botón de Run/Stop
    def run_stop_code(self, booleanState):
        global run, error
        run = booleanState
        if (run):
            self.runButton.setText("Stop")
            self.run_code()
            error = False
            movie_distance.start()
            movie_velocity.start()
            movie_movement.start()
        else:
            self.runButton.setText("Run")
            movie_distance.stop()
            movie_velocity.stop()
            movie_movement.stop()

    # Método que actualiza los registros
    def update_configuration(self, mode):
        global f_0, BW_actual, RampTimeReal, RampTimeReal_2, Samples_UI, MTI, Mth, factorPresencia_CW, factorPresencia_FMCW, Ntar, error

        if (mode == 1):
            self.f0_Desired.setToolTip("Initial frequency: 5 to 245")
            self.BW_Desired.setToolTip("Does not apply to mode 1")
        else:
            self.f0_Desired.setToolTip("Initial frequency: 5 to 195")
            self.BW_Desired.setToolTip("Sweep Bandwidth: 50 to 240 MHz")

        # Cogemos el número de muestras, le sumamos 1 porque en Arduino quitaremos la última (porque la Q suele salir mal, la rampa ya bajando)
        Samples_UI = self.Samples_Desired.value()
        f0 = self.f0_Desired.value()
        BW = self.BW_Desired.value()
        MTI = self.MovingTargetIndicator.currentIndex()
        Mth = self.Mth_Desired.currentIndex()
        Ntar = self.Ntar_Desired.value()
        Alpha = self.Alpha_Desired.value()

        if (Samples_UI > 200):
            Samples_UI = 200
            self.Samples_Desired.setValue(200)

        Ns = Samples_UI

        if (mode == 1):
            RampTimeReal, RampTimeReal_2, factorPresencia_CW, factorPresencia_FMCW = uRAD_processing.configuration(mode, Ns, Mth, Fs_CW, Alpha)
        else:
            RampTimeReal, RampTimeReal_2, factorPresencia_CW, factorPresencia_FMCW = uRAD_processing.configuration(mode, Ns, Mth, Fs, Alpha)

        # Display Ramp Time (ms)
        if (mode == 2):
            self.RampTime_FMCW_sawtooth.setValue(RampTimeReal*1e3)
        elif (mode == 3):
            self.RampTime_FMCW_triangle.setValue(RampTimeReal*1e3)
        elif (mode == 4):
            self.RampTime_FMCW_triangle_DualRate_1.setValue(RampTimeReal*1e3)
            self.RampTime_FMCW_triangle_DualRate_2.setValue(RampTimeReal_2*1e3)

        f_0 = 24 + f0/1e3
        if (f_0 < 24.005):
            f_0 = 24.005
            self.f0_Desired.setValue(5)
        elif (f_0 > 24.195 and mode != 1):
            f_0 = 24.195
            self.f0_Desired.setValue(195)
        elif (f_0 > 24.245 and mode == 1):
            f_0 = 24.245
            self.f0_Desired.setValue(245)
        self.f0_GHz.setValue(f_0)

        BW_UI = BW
        if (BW_UI < 50):
            BW_actual = 50
        elif (BW_UI > 240-round((f_0-24.005)*1e3)):
            BW_actual = 240-round((f_0-24.005)*1e3)
        else:
            BW_actual = BW_UI
        self.BW_Desired.setValue(BW_actual)

        if (Mth == 0):
            self.movement_CW.setPixmap(QtGui.QPixmap(common_path + "/resources/images/boton_movimiento_azul.png"))
            self.movement_FMCW_sawtooth.setPixmap(QtGui.QPixmap(common_path + "/resources/images/boton_movimiento_azul.png"))
            self.movement_FMCW_triangle.setPixmap(QtGui.QPixmap(common_path + "/resources/images/boton_movimiento_azul.png"))
            self.movement_FMCW_triangle_DualRate.setPixmap(QtGui.QPixmap(common_path + "/resources/images/boton_movimiento_azul.png"))

        if (mode == 1):
            if (Ntar < 5):
                self.PeakPosition_CW_5.setVisible(False)
                self.PeakMagnitude_CW_5.setVisible(False)
            else:
                self.PeakPosition_CW_5.setVisible(True)
                self.PeakMagnitude_CW_5.setVisible(True)
            if (Ntar < 4):
                self.PeakPosition_CW_4.setVisible(False)
                self.PeakMagnitude_CW_4.setVisible(False)
            else:
                self.PeakPosition_CW_4.setVisible(True)
                self.PeakMagnitude_CW_4.setVisible(True)
            if (Ntar < 3):
                self.PeakPosition_CW_3.setVisible(False)
                self.PeakMagnitude_CW_3.setVisible(False)
            else:
                self.PeakPosition_CW_3.setVisible(True)
                self.PeakMagnitude_CW_3.setVisible(True)
            if (Ntar < 2):
                self.PeakPosition_CW_2.setVisible(False)
                self.PeakMagnitude_CW_2.setVisible(False)
            else:
                self.PeakPosition_CW_2.setVisible(True)
                self.PeakMagnitude_CW_2.setVisible(True)
            if (Ntar < 1):
                self.PeakPosition_CW_1.setVisible(False)
                self.PeakMagnitude_CW_1.setVisible(False)
            else:
                self.PeakPosition_CW_1.setVisible(True)
                self.PeakMagnitude_CW_1.setVisible(True)
        elif (mode == 2):
            if (Ntar < 5):
                self.PeakPosition_FMCW_sawtooth_5.setVisible(False)
                self.PeakMagnitude_FMCW_sawtooth_5.setVisible(False)
            else:
                self.PeakPosition_FMCW_sawtooth_5.setVisible(True)
                self.PeakMagnitude_FMCW_sawtooth_5.setVisible(True)
            if (Ntar < 4):
                self.PeakPosition_FMCW_sawtooth_4.setVisible(False)
                self.PeakMagnitude_FMCW_sawtooth_4.setVisible(False)
            else:
                self.PeakPosition_FMCW_sawtooth_4.setVisible(True)
                self.PeakMagnitude_FMCW_sawtooth_4.setVisible(True)
            if (Ntar < 3):
                self.PeakPosition_FMCW_sawtooth_3.setVisible(False)
                self.PeakMagnitude_FMCW_sawtooth_3.setVisible(False)
            else:
                self.PeakPosition_FMCW_sawtooth_3.setVisible(True)
                self.PeakMagnitude_FMCW_sawtooth_3.setVisible(True)
            if (Ntar < 2):
                self.PeakPosition_FMCW_sawtooth_2.setVisible(False)
                self.PeakMagnitude_FMCW_sawtooth_2.setVisible(False)
            else:
                self.PeakPosition_FMCW_sawtooth_2.setVisible(True)
                self.PeakMagnitude_FMCW_sawtooth_2.setVisible(True)
            if (Ntar < 1):
                self.PeakPosition_FMCW_sawtooth_1.setVisible(False)
                self.PeakMagnitude_FMCW_sawtooth_1.setVisible(False)
            else:
                self.PeakPosition_FMCW_sawtooth_1.setVisible(True)
                self.PeakMagnitude_FMCW_sawtooth_1.setVisible(True)
        elif (mode == 3):
            if (Ntar < 5):
                self.PeakPosition_FMCW_triangle_5.setVisible(False)
                self.PeakSpeed_FMCW_triangle_5.setVisible(False)
                self.PeakMagnitude_FMCW_triangle_5.setVisible(False)
            else:
                self.PeakPosition_FMCW_triangle_5.setVisible(True)
                self.PeakSpeed_FMCW_triangle_5.setVisible(True)
                self.PeakMagnitude_FMCW_triangle_5.setVisible(True)
            if (Ntar < 4):
                self.PeakPosition_FMCW_triangle_4.setVisible(False)
                self.PeakSpeed_FMCW_triangle_4.setVisible(False)
                self.PeakMagnitude_FMCW_triangle_4.setVisible(False)
            else:
                self.PeakPosition_FMCW_triangle_4.setVisible(True)
                self.PeakSpeed_FMCW_triangle_4.setVisible(True)
                self.PeakMagnitude_FMCW_triangle_4.setVisible(True)
            if (Ntar < 3):
                self.PeakPosition_FMCW_triangle_3.setVisible(False)
                self.PeakSpeed_FMCW_triangle_3.setVisible(False)
                self.PeakMagnitude_FMCW_triangle_3.setVisible(False)
            else:
                self.PeakPosition_FMCW_triangle_3.setVisible(True)
                self.PeakSpeed_FMCW_triangle_3.setVisible(True)
                self.PeakMagnitude_FMCW_triangle_3.setVisible(True)
            if (Ntar < 2):
                self.PeakPosition_FMCW_triangle_2.setVisible(False)
                self.PeakSpeed_FMCW_triangle_2.setVisible(False)
                self.PeakMagnitude_FMCW_triangle_2.setVisible(False)
            else:
                self.PeakPosition_FMCW_triangle_2.setVisible(True)
                self.PeakSpeed_FMCW_triangle_2.setVisible(True)
                self.PeakMagnitude_FMCW_triangle_2.setVisible(True)
            if (Ntar < 1):
                self.PeakPosition_FMCW_triangle_1.setVisible(False)
                self.PeakSpeed_FMCW_triangle_1.setVisible(False)
                self.PeakMagnitude_FMCW_triangle_1.setVisible(False)
            else:
                self.PeakPosition_FMCW_triangle_1.setVisible(True)
                self.PeakSpeed_FMCW_triangle_1.setVisible(True)
                self.PeakMagnitude_FMCW_triangle_1.setVisible(True)
        elif (mode == 4):
            if (Ntar < 5):
                self.PeakPosition_FMCW_triangle_DualRate_5.setVisible(False)
                self.PeakSpeed_FMCW_triangle_DualRate_5.setVisible(False)
                self.PeakMagnitude_FMCW_triangle_DualRate_5.setVisible(False)
            else:
                self.PeakPosition_FMCW_triangle_DualRate_5.setVisible(True)
                self.PeakSpeed_FMCW_triangle_DualRate_5.setVisible(True)
                self.PeakMagnitude_FMCW_triangle_DualRate_5.setVisible(True)
            if (Ntar < 4):
                self.PeakPosition_FMCW_triangle_DualRate_4.setVisible(False)
                self.PeakSpeed_FMCW_triangle_DualRate_4.setVisible(False)
                self.PeakMagnitude_FMCW_triangle_DualRate_4.setVisible(False)
            else:
                self.PeakPosition_FMCW_triangle_DualRate_4.setVisible(True)
                self.PeakSpeed_FMCW_triangle_DualRate_4.setVisible(True)
                self.PeakMagnitude_FMCW_triangle_DualRate_4.setVisible(True)
            if (Ntar < 3):
                self.PeakPosition_FMCW_triangle_DualRate_3.setVisible(False)
                self.PeakSpeed_FMCW_triangle_DualRate_3.setVisible(False)
                self.PeakMagnitude_FMCW_triangle_DualRate_3.setVisible(False)
            else:
                self.PeakPosition_FMCW_triangle_DualRate_3.setVisible(True)
                self.PeakSpeed_FMCW_triangle_DualRate_3.setVisible(True)
                self.PeakMagnitude_FMCW_triangle_DualRate_3.setVisible(True)
            if (Ntar < 2):
                self.PeakPosition_FMCW_triangle_DualRate_2.setVisible(False)
                self.PeakSpeed_FMCW_triangle_DualRate_2.setVisible(False)
                self.PeakMagnitude_FMCW_triangle_DualRate_2.setVisible(False)
            else:
                self.PeakPosition_FMCW_triangle_DualRate_2.setVisible(True)
                self.PeakSpeed_FMCW_triangle_DualRate_2.setVisible(True)
                self.PeakMagnitude_FMCW_triangle_DualRate_2.setVisible(True)
            if (Ntar < 1):
                self.PeakPosition_FMCW_triangle_DualRate_1.setVisible(False)
                self.PeakSpeed_FMCW_triangle_DualRate_1.setVisible(False)
                self.PeakMagnitude_FMCW_triangle_DualRate_1.setVisible(False)
            else:
                self.PeakPosition_FMCW_triangle_DualRate_1.setVisible(True)
                self.PeakSpeed_FMCW_triangle_DualRate_1.setVisible(True)
                self.PeakMagnitude_FMCW_triangle_DualRate_1.setVisible(True)

        # loadConfiguration uRAD
        return_code = uRAD_USB_SDK11.loadConfiguration(ser, mode, round(1000*(f_0-24)), round(BW_actual), Samples_UI, 1, 0, MTI, 0, Alpha, False, False, False, True, True, False)
        if (return_code != 0):
            self.errorDisplay.setText('uRAD does not respond, reset GUI')
            error = True

        BW_actual = BW_actual*1000000

    # Método con el código principal cuya ejecución se controlada por la variable 'run'

    # Method with the main code whose execution is controlled by the variable 'run'
    def run_code(self):
        global ser, MTI, Samples_UI, lastPresenceMode, FirstExecution_FMCW_sawtooth, FirstExecution_CW, FirstExecution_FMCW_triangle, FirstExecution_FMCW_triangle_DualRate, update, Nm_CW, Fs, run, error, I_old, Q_old, Iterations_Hold, Range_Matrix, Velocity_Matrix, SNR_Matrix

        appSelected = modes[self.tabWidget.currentIndex()]

        if (not ser.is_open):
            PortName = self.PortsList.currentText()
            SplittedPortName = PortName.split()
            ser.port = SplittedPortName[0]
            try:
                ser.open()
                sleep(2)
                # switch ON uRAD
                return_code = uRAD_USB_SDK11.turnON(ser)
                if (return_code != 0):
                    self.errorDisplay.setText('uRAD does not respond, reset GUI')
                    error = True

                error = False
            except:
                print('Error al abrir el puerto ' + SplittedPortName[0])
                error = True
                run = False
                self.runButton.setText("Run")
                self.runButton.setChecked(False)
                self.errorDisplay.setText("Can't communicate with " + SplittedPortName[0] + " port")
                pass

        if (not error):
            self.errorDisplay.setText('')

            if (appSelected == 1):

                if (FirstExecution_CW or update):
                    FirstExecution_FMCW_sawtooth = True
                    FirstExecution_FMCW_triangle = True
                    FirstExecution_FMCW_triangle_DualRate = True
                    self.BW_Desired.setEnabled(False)
                    FirstExecution_CW = False
                    update = False
                    self.update_configuration(1)
                    Nm_CW = Samples_UI

                if (not error):
                    # target detection request
                    return_code, results, raw_results = uRAD_USB_SDK11.detection(ser)
                    
                    if (return_code != 0):
                        self.errorDisplay.setText('uRAD does not respond, reset GUI')
                        error = True
                    #else:
                        #print("ok")
                        #closeProgram()
                    
                    #print(len(raw_results[0]))
                    #print(len(raw_results[1]))
                    I = raw_results[0]
                    Q = raw_results[1]

                    actualTime = str(datetime.now())
                    # Save RAW Data in the project folder
                    if (self.SaveRAW_Data.isChecked()):
                        try:
                            fileRAW_I_Data = open(common_path + '/OutputFiles/I_CW.txt', 'a')
                            fileRAW_Q_Data = open(common_path + '/OutputFiles/Q_CW.txt', 'a')
                            I_string = ''
                            Q_string = ''
                            for i in range(len(I)):
                                I_string += '%d ' % (I[i])
                                Q_string += '%d ' % (Q[i])
                            fileRAW_I_Data.write(I_string + actualTime[0:-3] + '\n')
                            fileRAW_Q_Data.write(Q_string + actualTime[0:-3] + '\n')
                        except:
                            self.errorDisplay.setText("Can't find 'OutputFiles' folder")

                    # Substract the mean as DC cancelation
                    I = np.subtract(np.multiply(I, max_voltage/ADC_intervals), np.mean(np.multiply(I, max_voltage/ADC_intervals)))
                    Q = np.subtract(np.multiply(Q, max_voltage/ADC_intervals), np.mean(np.multiply(Q, max_voltage/ADC_intervals)))

                    # Clear the graph and plot I and Q signals
                    x_axis = np.linspace(1, len(I), num = len(I))
                    IQ_CW_Plot.clear()
                    IQ_CW_Plot.plot(x_axis, I, pen=pg.mkPen((0,0,255), width=2), name="I")
                    IQ_CW_Plot.plot(x_axis, Q, pen=pg.mkPen((255,0,0), width=2), name="Q")
                    labelStyle = {'color': '#000', 'font-size': '16px'}
                    IQ_CW_Plot.setLabel('bottom', "Samples", **labelStyle)
                    IQ_CW_Plot.setLabel('left', "Amplitude", units='V', **labelStyle)

                    # IQ plot X and Y axes limits
                    IQ_CW_Plot.setXRange(x_axis[0], x_axis[len(x_axis)-1], padding=0)
                    YMin = -1.5
                    YMax = 1.5
                    if (YMax > YMin):
                        IQ_CW_Plot.setYRange(YMin, YMax, padding=0)

                    ComplexVector = I + 1j*Q

                    # Apply the selected window to the complex vector previous to the FFT calculation
                    ComplexVector = ComplexVector * np.hanning(Nm_CW) * 2 / 3.3

                    # 
                    N_FFT = 4096
                    c = 299792458
                    max_velocity = c/(2*f_0*1000000000) * (Fs_CW/2)
                    SpeedUnits_Selected = self.SpeedUnits_CW.currentIndex()
                    if (SpeedUnits_Selected == 1):
                        SpeedFactor = 3.6
                        max_velocity *= SpeedFactor
                        x_axis_label = 'Velocity (km/h)'
                        self.label_MaximumSpeed.setText('Maximum Velocity (km/h)')
                    elif (SpeedUnits_Selected == 2):
                        SpeedFactor = 2.23694
                        max_velocity *= SpeedFactor
                        x_axis_label = 'Velocity (mph)'
                        self.label_MaximumSpeed.setText('Maximum Velocity (mph)')
                    else:
                        SpeedFactor = 1
                        x_axis_label = 'Velocity (m/s)'
                        self.label_MaximumSpeed.setText('Maximum Velocity (m/s)')

                    FrequencyDomain = 2*np.absolute(fftshift(fft(ComplexVector/Nm_CW, N_FFT)))
                    self.MaximumSpeed.setValue(max_velocity)
                    #x_axis = np.linspace(-max_velocity, max_velocity, num = N_FFT)
                    f_axis = fftshift(np.fft.fftfreq(N_FFT, d=1/Fs_CW))
                    x_axis = c/(2*f_0*1e9)*f_axis

                    FrequencyDomain[int(N_FFT/2)] = FrequencyDomain[int(N_FFT/2) - 1]
                    FrequencyDomain = 20 * np.log10(FrequencyDomain)

                    # CFAR algorithm?
                    PeaksIndex, PeaksMagnitude, SNR, NumberOfPeaks, threshold, threshold_indexes = uRAD_processing.findPeaks(FrequencyDomain, 1, Nm_CW, N_FFT)

                    Plot_CA_CFAR_Algorithm = self.CA_CFAR_Algorithm_CW.isChecked()
                    
                    Velocity_CW_Plot.clear()
                    labelStyle = {'color': '#000', 'font-size': '16px'}
                    Velocity_CW_Plot.setLabel('left', "Amplitude (dB)", **labelStyle)

                    # Update Target List
                    self.PeakPosition_CW_1.setValue(0)
                    self.PeakMagnitude_CW_1.setValue(0)
                    self.PeakPosition_CW_2.setValue(0)
                    self.PeakMagnitude_CW_2.setValue(0)
                    self.PeakPosition_CW_3.setValue(0)
                    self.PeakMagnitude_CW_3.setValue(0)
                    self.PeakPosition_CW_4.setValue(0)
                    self.PeakMagnitude_CW_4.setValue(0)
                    self.PeakPosition_CW_5.setValue(0)
                    self.PeakMagnitude_CW_5.setValue(0)
                    if (Plot_CA_CFAR_Algorithm):
                        Velocity_CW_Plot.plot(x_axis[threshold_indexes], threshold, pen=pg.mkPen((255,0,0), width=2), name="Threshold")

                    velocity = np.zeros(NumberOfPeaks)
                    for index in range(NumberOfPeaks):
                        velocity[index] = x_axis[int(PeaksIndex[index])]/SpeedFactor
                        '''
                        if (PeaksIndex[index] >= N_FFT/2):
                            velocity[index] = x_axis[int(PeaksIndex[index])-1]/SpeedFactor
                        else:
                            velocity[index] = x_axis[int(PeaksIndex[index])]/SpeedFactor
                        '''

                        if (index == 0):
                            self.PeakPosition_CW_1.setValue(velocity[index]*SpeedFactor)
                            self.PeakMagnitude_CW_1.setValue(SNR[index])
                        elif (index == 1):
                            self.PeakPosition_CW_2.setValue(velocity[index]*SpeedFactor)
                            self.PeakMagnitude_CW_2.setValue(SNR[index])
                        elif (index == 2):
                            self.PeakPosition_CW_3.setValue(velocity[index]*SpeedFactor)
                            self.PeakMagnitude_CW_3.setValue(SNR[index])
                        elif (index == 3):
                            self.PeakPosition_CW_4.setValue(velocity[index]*SpeedFactor)
                            self.PeakMagnitude_CW_4.setValue(SNR[index])
                        elif (index == 4):
                            self.PeakPosition_CW_5.setValue(velocity[index]*SpeedFactor)
                            self.PeakMagnitude_CW_5.setValue(SNR[index])

                    Velocity_CW_Plot.plot(x_axis, FrequencyDomain, pen=pg.mkPen((0,0,255), width=2), name="FrequencyDomain")
                    Velocity_CW_Plot.setLabel('bottom', x_axis_label, **labelStyle)
                    # Distance plot X and Y axis limits
                    if (self.AutoScaleX_CW.isChecked()):
                        XMin = 5 * np.ceil(-max_velocity/5)
                        XMax = 5 * np.ceil(max_velocity/5)
                        if (XMax > XMin):
                            Velocity_CW_Plot.setXRange(XMin, XMax, padding=0)
                    else:
                        XMin = self.XMin_CW.value()
                        XMax = self.XMax_CW.value()
                        XMin = np.max([XMin, -max_velocity])
                        XMax = np.min([XMax, max_velocity])
                        if (XMax > XMin):
                            Velocity_CW_Plot.setXRange(XMin, XMax, padding=0)
                    YMin = -60
                    YMax = 0
                    if (YMax > YMin):
                        Velocity_CW_Plot.setYRange(YMin, YMax, padding=0)

                    if (Mth > 0):
                        if (NumberOfPeaks > 0):
                            if (SNR[0] > 20*np.log10(factorPresencia_CW)):
                                movement = 1
                                self.movement_CW.setPixmap(QtGui.QPixmap(common_path + "/resources/images/boton_movimiento_rojo.png"))
                            else:
                                movement = 0
                                self.movement_CW.setPixmap(QtGui.QPixmap(common_path + "/resources/images/boton_movimiento_azul.png"))
                        else:
                            movement = 0
                            self.movement_CW.setPixmap(QtGui.QPixmap(common_path + "/resources/images/boton_movimiento_azul.png"))
                    else:
                        movement = 0

                    if (self.SaveResults_Data.isChecked() and NumberOfPeaks > 0):
                        try:
                            fileRAW_results_Data = open(common_path + '/OutputFiles/results.txt', 'a')
                            results_string = '1 '
                            for i in range(NumberOfPeaks):
                                results_string += '0 %1.2f %1.2f ' % (velocity[i], SNR[i])
                            results_string += '%d %d %d ' % (Mth, movement, MTI)
                            fileRAW_results_Data.write(results_string + actualTime[0:-3] + '\n')
                        except:
                            self.errorDisplay.setText("Can't find 'OutputFiles' folder")

            elif (appSelected == 2):

                if (FirstExecution_FMCW_sawtooth or update):
                    FirstExecution_CW = True
                    FirstExecution_FMCW_triangle = True
                    FirstExecution_FMCW_triangle_DualRate = True
                    self.BW_Desired.setEnabled(True)
                    FirstExecution_FMCW_sawtooth = False
                    update = False
                    self.update_configuration(2)

                if (not error):

                    # target detection request
                    return_code, results, raw_results = uRAD_USB_SDK11.detection(ser)
                    if (return_code != 0):
                        self.errorDisplay.setText('uRAD does not respond, reset GUI')
                        error = True

                    Nm = Samples_UI
                    I = raw_results[0]
                    Q = raw_results[1]

                    actualTime = str(datetime.now())
                    # Save RAW Data in the project folder
                    if (self.SaveRAW_Data.isChecked()):
                        fileRAW_I_Data = open(common_path + '/OutputFiles/I_FMCW_sawtooth.txt', 'a')
                        fileRAW_Q_Data = open(common_path + '/OutputFiles/Q_FMCW_sawtooth.txt', 'a')
                        I_string = ''
                        Q_string = ''
                        for i in range(len(I)):
                            I_string += '%d ' % (I[i])
                            Q_string += '%d ' % (Q[i])
                        fileRAW_I_Data.write(I_string + actualTime[0:-3] + '\n')
                        fileRAW_Q_Data.write(Q_string + actualTime[0:-3] + '\n')


                    # What are bad samples?  - Wait for access to uRAD_processing library
                    I, Q = uRAD_processing.deleteBadSamples(I, Q)

                    # See earlier subtraction of the mean
                    I = np.subtract(np.multiply(I, max_voltage/ADC_intervals), np.mean(np.multiply(I, max_voltage/ADC_intervals)))
                    Q = np.subtract(np.multiply(Q, max_voltage/ADC_intervals), np.mean(np.multiply(Q, max_voltage/ADC_intervals)))
                    
                    # Clear the graph and plot I and Q signals
                    x_axis = np.linspace(1, len(I), num = len(I))
                    IQ_FMCW_sawtooth_Plot.clear()
                    c1 = IQ_FMCW_sawtooth_Plot.plot(x_axis, I, pen=pg.mkPen((0,0,255), width=2), name="I")
                    c2 = IQ_FMCW_sawtooth_Plot.plot(x_axis, Q, pen=pg.mkPen((255,0,0), width=2), name="Q")
                    labelStyle = {'color': '#8f8f8f', 'font-size': '16px'}
                    IQ_FMCW_sawtooth_Plot.setLabel('bottom', "Samples", **labelStyle)
                    IQ_FMCW_sawtooth_Plot.setLabel('left', "Amplitude", units='V', **labelStyle)

                    # IQ plot X and Y axes limits
                    IQ_FMCW_sawtooth_Plot.setXRange(x_axis[0], x_axis[len(x_axis)-1], padding=0)
                    YMin = -2
                    YMax = 2
                    if (YMax > YMin):
                        IQ_FMCW_sawtooth_Plot.setYRange(YMin, YMax, padding=0)

                    # NOTE: Why not use a square law detector? Maybe the window needs it to be complex 
                    # NOTE: Maybe window while complex and then square law detect afterwards?

                    # Compute the complex vector (I - jQ)
                    #ComplexVector = I + 1j*Q
                    ComplexVector = I + 1j*Q

                    # Apply the selected window to the complex vector previous to the FFT calculation
                    ComplexVector = ComplexVector * np.hanning(Nm) * 2 / 3.3

                    N_FFT = 4096
                    c = 299792458
                    max_distance = c/(2*BW_actual) * Fs/2 * RampTimeReal
                    #resolution = 2*max_distance/N_FFT

                    DistanceUnits_Selected = self.DistanceUnits_FMCW_sawtooth.currentIndex()
                    if (DistanceUnits_Selected == 0):
                        DistanceFactor = 1
                        self.label_MaximumDistance_FMCW_sawtooth.setText('Maximum Distance (m)')
                        units = 'm'
                    elif(DistanceUnits_Selected == 1):
                        DistanceFactor = 3.28084
                        max_distance *= DistanceFactor
                        self.label_MaximumDistance_FMCW_sawtooth.setText('Maximum Distance (ft)')
                        units = 'ft'
                    else:
                        DistanceFactor = 1.09361
                        max_distance *= DistanceFactor
                        self.label_MaximumDistance_FMCW_sawtooth.setText('Maximum Distance (yard)')
                        units = 'yard'
                    # Update maximum distance indicator
                    self.MaximumDistance_FMCW_sawtooth.setValue(max_distance)
                    
                    FrequencyDomain = 2*np.absolute(fftshift(fft(ComplexVector / Nm, N_FFT)))
                    #x_axis = np.linspace(-max_distance, max_distance, num = N_FFT)
                    f_axis = fftshift(np.fft.fftfreq(N_FFT, d=1/Fs))
                    x_axis = c/(2*BW_actual)*f_axis*RampTimeReal
                    start = int(N_FFT/2)

                    FrequencyDomain[start] = FrequencyDomain[start - 1]
                    FrequencyDomain = 20 * np.log10(FrequencyDomain)
                    
                    # Does not seem like they used a square law detector...
                    PeaksIndex, PeaksMagnitude, SNR, NumberOfPeaks, threshold, threshold_indexes = uRAD_processing.findPeaks(FrequencyDomain, 2, Nm, N_FFT)

                    Distance_FMCW_sawtooth_Plot.clear()
                    Distance_FMCW_sawtooth_Plot.setLabel('left', "Amplitude (dB)", **labelStyle)
                    # Update Target List
                    self.PeakPosition_FMCW_sawtooth_1.setValue(0)
                    self.PeakMagnitude_FMCW_sawtooth_1.setValue(0)
                    self.PeakPosition_FMCW_sawtooth_2.setValue(0)
                    self.PeakMagnitude_FMCW_sawtooth_2.setValue(0)
                    self.PeakPosition_FMCW_sawtooth_3.setValue(0)
                    self.PeakMagnitude_FMCW_sawtooth_3.setValue(0)
                    self.PeakPosition_FMCW_sawtooth_4.setValue(0)
                    self.PeakMagnitude_FMCW_sawtooth_4.setValue(0)
                    self.PeakPosition_FMCW_sawtooth_5.setValue(0)
                    self.PeakMagnitude_FMCW_sawtooth_5.setValue(0)
                    if (self.CA_CFAR_Algorithm_FMCW_sawtooth.isChecked()):
                        Distance_FMCW_sawtooth_Plot.plot(x_axis[threshold_indexes], threshold, pen=pg.mkPen((255,0,0), width=2))

                    distance = np.zeros(NumberOfPeaks)
                    for index in range(NumberOfPeaks):
                        #distance[index] = x_axis[start + int(PeaksIndex[index]) - 1]/DistanceFactor
                        distance[index] = x_axis[start + int(PeaksIndex[index])]/DistanceFactor
                        if (index == 0):
                            self.PeakPosition_FMCW_sawtooth_1.setValue(distance[index]*DistanceFactor)
                            self.PeakMagnitude_FMCW_sawtooth_1.setValue(SNR[index])
                        elif (index == 1):
                            self.PeakPosition_FMCW_sawtooth_2.setValue(distance[index]*DistanceFactor)
                            self.PeakMagnitude_FMCW_sawtooth_2.setValue(SNR[index])
                        elif (index == 2):
                            self.PeakPosition_FMCW_sawtooth_3.setValue(distance[index]*DistanceFactor)
                            self.PeakMagnitude_FMCW_sawtooth_3.setValue(SNR[index])
                        elif (index == 3):
                            self.PeakPosition_FMCW_sawtooth_4.setValue(distance[index]*DistanceFactor)
                            self.PeakMagnitude_FMCW_sawtooth_4.setValue(SNR[index])
                        elif (index == 4):
                            self.PeakPosition_FMCW_sawtooth_5.setValue(distance[index]*DistanceFactor)
                            self.PeakMagnitude_FMCW_sawtooth_5.setValue(SNR[index])

                    # Plot Power Vs Distance
                    Distance_FMCW_sawtooth_Plot.plot(x_axis, FrequencyDomain, pen=pg.mkPen((0,0,255), width=2))
                    Distance_FMCW_sawtooth_Plot.setLabel('bottom', "Distance", units=units, **labelStyle)
                    # Distance plot X and Y axis limits
                    if (self.AutoScaleX_FMCW_sawtooth.isChecked()):
                        XMin = 0
                        XMax = 5 * np.ceil(max_distance/5)
                        if (XMax > XMin):
                            Distance_FMCW_sawtooth_Plot.setXRange(XMin, XMax, padding=0)
                    else:
                        XMin = self.XMin_FMCW_sawtooth.value()
                        XMax = self.XMax_FMCW_sawtooth.value()
                        XMin = np.max([XMin, -max_distance])
                        XMax = np.min([XMax, max_distance])
                        if (XMax > XMin):
                            Distance_FMCW_sawtooth_Plot.setXRange(XMin, XMax, padding=0)
                    YMin = -60
                    YMax = 0
                    if (YMax > YMin):
                        Distance_FMCW_sawtooth_Plot.setYRange(YMin, YMax, padding=0)

                    if (Mth > 0):
                        if (MTI > 0 and NumberOfPeaks > 0):
                            if (SNR[0] > 20*np.log10(factorPresencia_FMCW)):
                                movement = 1
                                self.movement_FMCW_sawtooth.setPixmap(QtGui.QPixmap(common_path + "/resources/images/boton_movimiento_rojo.png"))
                            else:
                                movement = 0
                                self.movement_FMCW_sawtooth.setPixmap(QtGui.QPixmap(common_path + "/resources/images/boton_movimiento_azul.png"))
                        else:
                            if (lastPresenceMode == 2):
                                if (len(I_old) == len(I)):
                                    ComplexVector = (I-I_old) + 1j*(Q-Q_old)
                                    ComplexVector = ComplexVector * np.hanning(Nm) * 2
                                    FrequencyDomain = 2*np.absolute(fftshift(fft(ComplexVector / Nm, N_FFT)))
                                    FrequencyDomain[start] = FrequencyDomain[start - 1]
                                    FrequencyDomain = 20 * np.log10(FrequencyDomain)

                                    movement_detected = uRAD_processing.findMovement(FrequencyDomain, 2, Nm, N_FFT)

                                    if (movement_detected):
                                        movement = 1
                                        self.movement_FMCW_sawtooth.setPixmap(QtGui.QPixmap(common_path + "/resources/images/boton_movimiento_rojo.png"))
                                    else:
                                        movement = 0
                                        self.movement_FMCW_sawtooth.setPixmap(QtGui.QPixmap(common_path + "/resources/images/boton_movimiento_azul.png"))
                                else:
                                    movement = 0
                                    self.movement_FMCW_sawtooth.setPixmap(QtGui.QPixmap(common_path + "/resources/images/boton_movimiento_azul.png"))
                            else:
                                movement = 0
                                self.movement_FMCW_sawtooth.setPixmap(QtGui.QPixmap(common_path + "/resources/images/boton_movimiento_azul.png"))

                            lastPresenceMode = 2
                            I_old = I
                            Q_old = Q

                    else:
                        movement = 0
                        lastPresenceMode = 0

                    if (self.SaveResults_Data.isChecked() and NumberOfPeaks > 0):
                        try:
                            fileRAW_results_Data = open(common_path + '/OutputFiles/results.txt', 'a')
                            results_string = '2 '
                            for i in range(NumberOfPeaks):
                                results_string += '%1.3f 0 %1.2f ' % (distance[i], SNR[i])
                            results_string += '%d %d %d ' % (Mth, movement, MTI)
                            fileRAW_results_Data.write(results_string + actualTime[0:-3] + '\n')
                        except:
                            self.errorDisplay.setText("Can't find 'OutputFiles' folder")
            

            # NOTE: FMCW Triangle mode

            elif (appSelected == 3):

                if (FirstExecution_FMCW_triangle or update):
                    FirstExecution_FMCW_sawtooth = True
                    FirstExecution_CW = True
                    FirstExecution_FMCW_triangle_DualRate = True
                    self.BW_Desired.setEnabled(True)
                    FirstExecution_FMCW_triangle = False
                    update = False
                    self.update_configuration(3)

                if (not error):

                    # target detection request
                    return_code, results, raw_results = uRAD_USB_SDK11.detection(ser)
                    if (return_code != 0):
                        self.errorDisplay.setText('uRAD does not respond, reset GUI')
                        error = True

                    Nm = Samples_UI
                    I = raw_results[0]
                    Q = raw_results[1]
                    I_up = I[0:Nm]
                    I_down = I[Nm:2*Nm]
                    Q_up = Q[0:Nm]
                    Q_down = Q[Nm:2*Nm]

                    actualTime = str(datetime.now())
                    # Save RAW Data in the project folder
                    if (self.SaveRAW_Data.isChecked()):
                        try:
                            fileRAW_I_up_Data = open(common_path + '/OutputFiles/I_up_FMCW_triangle.txt', 'a')
                            fileRAW_Q_up_Data = open(common_path + '/OutputFiles/Q_up_FMCW_triangle.txt', 'a')
                            fileRAW_I_down_Data = open(common_path + '/OutputFiles/I_down_FMCW_triangle.txt', 'a')
                            fileRAW_Q_down_Data = open(common_path + '/OutputFiles/Q_down_FMCW_triangle.txt', 'a')
                            I_up_string = ''
                            Q_up_string = ''
                            I_down_string = ''
                            Q_down_string = ''
                            for i in range(len(I_up)):
                                I_up_string += '%d ' % (I_up[i])
                                Q_up_string += '%d ' % (Q_up[i])
                                I_down_string += '%d ' % (I_down[i])
                                Q_down_string += '%d ' % (Q_down[i])
                            
                            fileRAW_I_up_Data.write(I_up_string + actualTime[0:-3] + '\n')
                            fileRAW_Q_up_Data.write(Q_up_string + actualTime[0:-3] + '\n')
                            fileRAW_I_down_Data.write(I_down_string + actualTime[0:-3] + '\n')
                            fileRAW_Q_down_Data.write(Q_down_string + actualTime[0:-3] + '\n')
                        except:
                            self.errorDisplay.setText("Can't find 'OutputFiles' folder")

                    

                    # STEP 1: Delete bad samples
                    I_up, Q_up = uRAD_processing.deleteBadSamples(I_up, Q_up)
                    I_down, Q_down = uRAD_processing.deleteBadSamples(I_down, Q_down)


                    # STEP 2: Subtract the mean
                    I_up = np.subtract(np.multiply(I_up, max_voltage/ADC_intervals), np.mean(np.multiply(I_up, max_voltage/ADC_intervals)))
                    Q_up = np.subtract(np.multiply(Q_up, max_voltage/ADC_intervals), np.mean(np.multiply(Q_up, max_voltage/ADC_intervals)))
                    I_down = np.subtract(np.multiply(I_down, max_voltage/ADC_intervals), np.mean(np.multiply(I_down, max_voltage/ADC_intervals)))
                    Q_down = np.subtract(np.multiply(Q_down, max_voltage/ADC_intervals), np.mean(np.multiply(Q_down, max_voltage/ADC_intervals)))

                    # Clear the graph and plot I and Q signals
                    x_axis = np.linspace(1, 2*Nm, num = 2*Nm)
                    IQ_FMCW_triangle_Plot.clear()
                    IQ_FMCW_triangle_Plot.plot(x_axis[0:len(I_up)], I_up, pen=pg.mkPen((0,0,255), width=2), name="I_up")
                    IQ_FMCW_triangle_Plot.plot(x_axis[0:len(Q_up)], Q_up, pen=pg.mkPen((255,0,0), width=2), name="Q_up")
                    IQ_FMCW_triangle_Plot.plot(x_axis[len(I_up):len(I_up) + len(I_down)], I_down, pen=pg.mkPen((0,0,255), width=2, style=QtCore.Qt.DashLine), name="I_down")
                    IQ_FMCW_triangle_Plot.plot(x_axis[len(Q_up):len(Q_up) + len(Q_down)], Q_down, pen=pg.mkPen((255,0,0), width=2, style=QtCore.Qt.DashLine), name="Q_down")
                    labelStyle = {'color': '#000', 'font-size': '16px'}
                    IQ_FMCW_triangle_Plot.setLabel('bottom', "Samples", **labelStyle)
                    IQ_FMCW_triangle_Plot.setLabel('left', "Amplitude", units='V', **labelStyle)
                    # IQ plot X and Y axes limits
                    IQ_FMCW_triangle_Plot.setXRange(x_axis[0], x_axis[len(x_axis)-1], padding=0)
                    YMin = -2
                    YMax = 2
                    if (YMax > YMin):
                        IQ_FMCW_triangle_Plot.setYRange(YMin, YMax, padding=0)
                    

                    # STEP 3: Combine to get complex vector
                    # Compute the complex vector (I - jQ)
                    ComplexVector_up = I_up + 1j*Q_up
                    ComplexVector_down = I_down - 1j*Q_down


                    # STEP 4: Apply window function
                    # Apply the selected window to the complex vector previous to the FFT calculation
                    ComplexVector_up = ComplexVector_up * np.hanning(Nm) * 2 / 3.3
                    ComplexVector_down = ComplexVector_down * np.hanning(Nm) * 2 / 3.3

                    N_FFT = 4096
                    c = 299792458
                    Samples = Nm
                    max_distance = c/(2*BW_actual) * Fs/2 * RampTimeReal
                    #distance_resolution = 2*max_distance/(N_FFT-1)
                    #f_axis = np.linspace(-Fs/2, Fs/2, num = N_FFT)
                    f_axis = fftshift(np.fft.fftfreq(N_FFT, d=1/Fs)) # checkout this function

                    f0 = f_0*1000000000 + BW_actual/2
                    max_velocity = c/(2*f0) * max_fd
                    #velocity_resolution = (2*c/(2*f0) * Fs/2) / (N_FFT-1)

                    Frequency_FMCW_triangle_Plot.clear()
                    labelStyle = {'color': '#000', 'font-size': '16px'}

                    SpeedUnits_Selected = self.SpeedUnits_FMCW_triangle.currentIndex()
                    if (SpeedUnits_Selected == 1):
                        SpeedFactor = 3.6
                        max_velocity *= SpeedFactor
                        self.label_MaximumSpeed_FMCW_triangle.setText('Max Speed (km/h)')
                    elif (SpeedUnits_Selected == 2):
                        SpeedFactor = 2.23694
                        max_velocity *= SpeedFactor
                        self.label_MaximumSpeed_FMCW_triangle.setText('Max Speed (mph)')
                    else:
                        SpeedFactor = 1
                        self.label_MaximumSpeed_FMCW_triangle.setText('Max Speed (m/s)')
                    self.MaximumSpeed_FMCW_triangle.setValue(max_velocity)

                    DistanceUnits_Selected = self.DistanceUnits_FMCW_triangle.currentIndex()
                    if (DistanceUnits_Selected == 0):

                    # NOTE: Seems like they do not calibrate the distance axis, atleast not here
                        DistanceFactor = 1;
                        self.label_MaximumDistance_FMCW_triangle.setText('Maximum Distance (m)')
                        Frequency_FMCW_triangle_Plot.setLabel('bottom', "Distance (m)", **labelStyle)
                    elif(DistanceUnits_Selected == 1):
                        DistanceFactor = 3.28084;
                        max_distance *= DistanceFactor
                        self.label_MaximumDistance_FMCW_triangle.setText('Maximum Distance (ft)')
                        Frequency_FMCW_triangle_Plot.setLabel('bottom', "Distance (ft)", **labelStyle)
                    else:
                        DistanceFactor = 1.09361
                        max_distance *= DistanceFactor
                        self.label_MaximumDistance_FMCW_triangle.setText('Maximum Distance (yard)')
                        Frequency_FMCW_triangle_Plot.setLabel('bottom', "Distance (yard)", **labelStyle)

                    # Update maximum distance indicator
                    self.MaximumDistance_FMCW_triangle.setValue(max_distance)
                    R_axis = np.linspace(-max_distance, max_distance, num = N_FFT)

                    
                    start = int(N_FFT/2)

                    # STEP 5: Compute FFT
                    FrequencyDomain_up = 2*np.absolute(fftshift(fft(ComplexVector_up / Nm, N_FFT)))
                    FrequencyDomain_down = 2*np.absolute(fftshift(fft(ComplexVector_down / Nm, N_FFT)))
                    
                    # What is this?? shift by 1 sample and start at middle??
                    FrequencyDomain_up[start] = FrequencyDomain_up[start - 1]
                    FrequencyDomain_down[start] = FrequencyDomain_down[start - 1]

                    # Log scale
                    FrequencyDomain_up = 20 * np.log10(FrequencyDomain_up)
                    FrequencyDomain_down = 20 * np.log10(FrequencyDomain_down)

                    # Need access to this function
                    PeaksIndex_Up, PeaksMagnitude_Up, PeaksSNR_Up, NumberOfPeaks_Up, threshold_Up, threshold_indexes = uRAD_processing.findPeaks(FrequencyDomain_up, 3, Nm, N_FFT)
                    PeaksIndex_Down, PeaksMagnitude_Down, PeaksSNR_Down, NumberOfPeaks_Down, threshold_Down, threshold_indexes = uRAD_processing.findPeaks(FrequencyDomain_down, 3, Nm, N_FFT)

                    Frequency_FMCW_triangle_Plot.setLabel('left', "Amplitude (dB)", **labelStyle)
                    Frequency_FMCW_triangle_Plot.plot(R_axis, FrequencyDomain_up, pen=pg.mkPen((0,0,255), width=2), name="Up_Ramp_Spectrum")
                    Frequency_FMCW_triangle_Plot.plot(R_axis, FrequencyDomain_down, pen=pg.mkPen((0,0,255), width=2, style=QtCore.Qt.DashLine), name="Down_Ramp_Spectrum")

                    # Update Target List
                    self.PeakPosition_FMCW_triangle_1.setValue(0)
                    self.PeakPosition_FMCW_triangle_2.setValue(0)
                    self.PeakPosition_FMCW_triangle_3.setValue(0)
                    self.PeakPosition_FMCW_triangle_4.setValue(0)
                    self.PeakPosition_FMCW_triangle_5.setValue(0)
                    self.PeakSpeed_FMCW_triangle_1.setValue(0)
                    self.PeakSpeed_FMCW_triangle_2.setValue(0)
                    self.PeakSpeed_FMCW_triangle_3.setValue(0)
                    self.PeakSpeed_FMCW_triangle_4.setValue(0)
                    self.PeakSpeed_FMCW_triangle_5.setValue(0)
                    self.PeakMagnitude_FMCW_triangle_1.setValue(0)
                    self.PeakMagnitude_FMCW_triangle_2.setValue(0)
                    self.PeakMagnitude_FMCW_triangle_3.setValue(0)
                    self.PeakMagnitude_FMCW_triangle_4.setValue(0)
                    self.PeakMagnitude_FMCW_triangle_5.setValue(0)

                    if (self.AutoScaleX_FMCW_triangle.isChecked()):
                        XMin = 0
                        XMax = 5 * np.ceil(max_distance/5)
                        if (XMax > XMin):
                            Frequency_FMCW_triangle_Plot.setXRange(XMin, XMax, padding=0)
                    else:
                        XMin = self.XMin_FMCW_triangle.value()
                        XMax = self.XMax_FMCW_triangle.value()
                        XMin = np.max([XMin, -max_distance])
                        XMax = np.min([XMax, max_distance])
                        if (XMax > XMin):
                            Frequency_FMCW_triangle_Plot.setXRange(XMin, XMax, padding=0)
                    YMin = -60
                    YMax = 0
                    if (YMax > YMin):
                        Frequency_FMCW_triangle_Plot.setYRange(YMin, YMax, padding=0)

                    NumberOfPeaks = 0

                    if (NumberOfPeaks_Up > 0 and NumberOfPeaks_Down > 0):

                        Distance, Velocity, SNR, Error, NumberOfPeaks = uRAD_processing.processTriangleWaveformData(3, NumberOfPeaks_Up, NumberOfPeaks_Down, PeaksIndex_Up, PeaksIndex_Down, PeaksMagnitude_Up, PeaksMagnitude_Down, PeaksSNR_Up, PeaksSNR_Down, f_axis, max_fd, Ntar, f0, BW_actual, RampTimeReal)

                        for index in range(NumberOfPeaks):
                            if (index == 0):
                                self.PeakPosition_FMCW_triangle_1.setValue(Distance[index]*DistanceFactor)
                                self.PeakSpeed_FMCW_triangle_1.setValue(Velocity[index]*SpeedFactor)
                                self.PeakMagnitude_FMCW_triangle_1.setValue(SNR[index])
                            elif (index == 1):
                                self.PeakPosition_FMCW_triangle_2.setValue(Distance[index]*DistanceFactor)
                                self.PeakSpeed_FMCW_triangle_2.setValue(Velocity[index]*SpeedFactor)
                                self.PeakMagnitude_FMCW_triangle_2.setValue(SNR[index])
                            elif (index == 2):
                                self.PeakPosition_FMCW_triangle_3.setValue(Distance[index]*DistanceFactor)
                                self.PeakSpeed_FMCW_triangle_3.setValue(Velocity[index]*SpeedFactor)
                                self.PeakMagnitude_FMCW_triangle_3.setValue(SNR[index])
                            elif (index == 3):
                                self.PeakPosition_FMCW_triangle_4.setValue(Distance[index]*DistanceFactor)
                                self.PeakSpeed_FMCW_triangle_4.setValue(Velocity[index]*SpeedFactor)
                                self.PeakMagnitude_FMCW_triangle_4.setValue(SNR[index])
                            elif (index == 4):
                                self.PeakPosition_FMCW_triangle_5.setValue(Distance[index]*DistanceFactor)
                                self.PeakSpeed_FMCW_triangle_5.setValue(Velocity[index]*SpeedFactor)
                                self.PeakMagnitude_FMCW_triangle_5.setValue(SNR[index])

                    if (Mth > 0):
                        if (MTI > 0 and NumberOfPeaks > 0):
                            if (SNR[0] > 20*np.log10(factorPresencia_FMCW)):
                                movement = 1
                                self.movement_FMCW_triangle.setPixmap(QtGui.QPixmap(common_path + "/resources/images/boton_movimiento_rojo.png"))
                            else:
                                movement = 0
                                self.movement_FMCW_triangle.setPixmap(QtGui.QPixmap(common_path + "/resources/images/boton_movimiento_azul.png"))
                        else:
                            if (lastPresenceMode == 3):
                                if (len(I_old) == len(I_up)):
                                    ComplexVector = (I_up-I_old) + 1j*(Q_up-Q_old)
                                    ComplexVector = ComplexVector * np.hanning(Nm) * 2
                                    FrequencyDomain = 2*np.absolute(fftshift(fft(ComplexVector / Nm, N_FFT)))
                                    FrequencyDomain[start] = FrequencyDomain[start - 1]
                                    FrequencyDomain = 20 * np.log10(FrequencyDomain)

                                    movement_detected = uRAD_processing.findMovement(FrequencyDomain, 3, Nm, N_FFT)

                                    if (movement_detected):
                                        movement = 1
                                        self.movement_FMCW_triangle.setPixmap(QtGui.QPixmap(common_path + "/resources/images/boton_movimiento_rojo.png"))
                                    else:
                                        movement = 0
                                        self.movement_FMCW_triangle.setPixmap(QtGui.QPixmap(common_path + "/resources/images/boton_movimiento_azul.png"))
                                else:
                                    movement = 0
                                    self.movement_FMCW_triangle.setPixmap(QtGui.QPixmap(common_path + "/resources/images/boton_movimiento_azul.png"))
                            else:
                                movement = 0
                                self.movement_FMCW_triangle.setPixmap(QtGui.QPixmap(common_path + "/resources/images/boton_movimiento_azul.png"))

                            lastPresenceMode = 3
                            I_old = I_up
                            Q_old = Q_up

                    else:
                        movement = 0
                        lastPresenceMode = 0

                    if (self.SaveResults_Data.isChecked() and NumberOfPeaks > 0):
                        try:
                            fileRAW_results_Data = open(common_path + '/OutputFiles/results.txt', 'a')
                            results_string = '3 '
                            for i in range(NumberOfPeaks):
                                results_string += '%1.3f %1.2f %1.2f ' % (Distance[i], Velocity[i], SNR[i])
                            results_string += '%d %d %d ' % (Mth, movement, MTI)
                            fileRAW_results_Data.write(results_string + actualTime[0:-3] + '\n')
                        except:
                            self.errorDisplay.setText("Can't find 'OutputFiles' folder")

            elif (appSelected == 4):

                if (FirstExecution_FMCW_triangle_DualRate or update):
                    FirstExecution_FMCW_sawtooth = True
                    FirstExecution_FMCW_triangle = True
                    FirstExecution_CW = True
                    self.BW_Desired.setEnabled(True)
                    FirstExecution_FMCW_triangle_DualRate = False
                    update = False
                    self.update_configuration(4)

                if (not error):

                    # target detection request
                    return_code, results, raw_results = uRAD_USB_SDK11.detection(ser)
                    if (return_code != 0):
                        self.errorDisplay.setText('uRAD does not respond, reset GUI')
                        error = True

                    Nm_0 = Samples_UI
                    Nm_1 = Samples_UI
                    Nm_2 = int(np.ceil(0.75*Samples_UI))
                    Nm_3 = int(np.ceil(0.75*Samples_UI))

                    Nm = Nm_0 + Nm_1 + Nm_2 + Nm_3

                    I = raw_results[0]
                    Q = raw_results[1]
                    I_up_1 = I[0:Nm_0]
                    I_down_1 = I[Nm_0:Nm_0+Nm_1]
                    I_up_2 = I[Nm_0+Nm_1:Nm_0+Nm_1+Nm_2]
                    I_down_2 = I[Nm_0+Nm_1+Nm_2:Nm_0+Nm_1+Nm_2+Nm_3]
                    Q_up_1 = Q[0:Nm_0]
                    Q_down_1 = Q[Nm_0:Nm_0+Nm_1]
                    Q_up_2 = Q[Nm_0+Nm_1:Nm_0+Nm_1+Nm_2]
                    Q_down_2 = Q[Nm_0+Nm_1+Nm_2:Nm_0+Nm_1+Nm_2+Nm_3]

                    actualTime = str(datetime.now())
                    # Save RAW Data in the project folder
                    if (self.SaveRAW_Data.isChecked()):
                        try:
                            fileRAW_I_up_1_Data = open(common_path + '/OutputFiles/I_up_1_FMCW_triangle_DualRate.txt', 'a')
                            fileRAW_Q_up_1_Data = open(common_path + '/OutputFiles/Q_up_1_FMCW_triangle_DualRate.txt', 'a')
                            fileRAW_I_down_1_Data = open(common_path + '/OutputFiles/I_down_1_FMCW_triangle_DualRate.txt', 'a')
                            fileRAW_Q_down_1_Data = open(common_path + '/OutputFiles/Q_down_1_FMCW_triangle_DualRate.txt', 'a')
                            fileRAW_I_up_2_Data = open(common_path + '/OutputFiles/I_up_2_FMCW_triangle_DualRate.txt', 'a')
                            fileRAW_Q_up_2_Data = open(common_path + '/OutputFiles/Q_up_2_FMCW_triangle_DualRate.txt', 'a')
                            fileRAW_I_down_2_Data = open(common_path + '/OutputFiles/I_down_2_FMCW_triangle_DualRate.txt', 'a')
                            fileRAW_Q_down_2_Data = open(common_path + '/OutputFiles/Q_down_2_FMCW_triangle_DualRate.txt', 'a')
                            I_up_1_string = ''
                            Q_up_1_string = ''
                            I_down_1_string = ''
                            Q_down_1_string = ''
                            I_up_2_string = ''
                            Q_up_2_string = ''
                            I_down_2_string = ''
                            Q_down_2_string = ''
                            for i in range(len(I_up_1)):
                                I_up_1_string += '%d ' % (I_up_1[i])
                                Q_up_1_string += '%d ' % (Q_up_1[i])
                                I_down_1_string += '%d ' % (I_down_1[i])
                                Q_down_1_string += '%d ' % (Q_down_1[i])
                            for i in range(len(I_up_2)):
                                I_up_2_string += '%d ' % (I_up_2[i])
                                Q_up_2_string += '%d ' % (Q_up_2[i])
                                I_down_2_string += '%d ' % (I_down_2[i])
                                Q_down_2_string += '%d ' % (Q_down_2[i])

                            fileRAW_I_up_1_Data.write(I_up_1_string + actualTime[0:-3] + '\n')
                            fileRAW_Q_up_1_Data.write(Q_up_1_string + actualTime[0:-3] + '\n')
                            fileRAW_I_down_1_Data.write(I_down_1_string + actualTime[0:-3] + '\n')
                            fileRAW_Q_down_1_Data.write(Q_down_1_string + actualTime[0:-3] + '\n')
                            fileRAW_I_up_2_Data.write(I_up_2_string + actualTime[0:-3] + '\n')
                            fileRAW_Q_up_2_Data.write(Q_up_2_string + actualTime[0:-3] + '\n')
                            fileRAW_I_down_2_Data.write(I_down_2_string + actualTime[0:-3] + '\n')
                            fileRAW_Q_down_2_Data.write(Q_down_2_string + actualTime[0:-3] + '\n')

                        except:
                            self.errorDisplay.setText("Can't find 'OutputFiles' folder")

                    I_up_1, Q_up_1 = uRAD_processing.deleteBadSamples(I_up_1, Q_up_1)
                    I_down_1, Q_down_1 = uRAD_processing.deleteBadSamples(I_down_1, Q_down_1)
                    I_up_2, Q_up_2 = uRAD_processing.deleteBadSamples(I_up_2, Q_up_2)
                    I_down_2, Q_down_2 = uRAD_processing.deleteBadSamples(I_down_2, Q_down_2)

                    I_up_1 = np.subtract(np.multiply(I_up_1, max_voltage/ADC_intervals), np.mean(np.multiply(I_up_1, max_voltage/ADC_intervals)))
                    Q_up_1 = np.subtract(np.multiply(Q_up_1, max_voltage/ADC_intervals), np.mean(np.multiply(Q_up_1, max_voltage/ADC_intervals)))
                    I_up_2 = np.subtract(np.multiply(I_up_2, max_voltage/ADC_intervals), np.mean(np.multiply(I_up_2, max_voltage/ADC_intervals)))
                    Q_up_2 = np.subtract(np.multiply(Q_up_2, max_voltage/ADC_intervals), np.mean(np.multiply(Q_up_2, max_voltage/ADC_intervals)))
                    I_down_1 = np.subtract(np.multiply(I_down_1, max_voltage/ADC_intervals), np.mean(np.multiply(I_down_1, max_voltage/ADC_intervals)))
                    Q_down_1 = np.subtract(np.multiply(Q_down_1, max_voltage/ADC_intervals), np.mean(np.multiply(Q_down_1, max_voltage/ADC_intervals)))
                    I_down_2 = np.subtract(np.multiply(I_down_2, max_voltage/ADC_intervals), np.mean(np.multiply(I_down_2, max_voltage/ADC_intervals)))
                    Q_down_2 = np.subtract(np.multiply(Q_down_2, max_voltage/ADC_intervals), np.mean(np.multiply(Q_down_2, max_voltage/ADC_intervals)))

                    N_FFT = 4096
                    c = 299792458
                    #f_axis = np.linspace(-Fs/2, Fs/2, num = N_FFT)
                    f_axis = fftshift(np.fft.fftfreq(N_FFT, d=1/Fs))
                    max_distance = c/(2*BW_actual) * Fs/2 * RampTimeReal_2
                    #distance_resolution = 2*max_distance/(N_FFT-1)
                    f0 = f_0*1000000000 + BW_actual/2
                    max_velocity = c/(2*f0) * max_fd
                    #velocity_resolution = (2*c/(2*f0) * Fs/2) / (N_FFT-1)

                    RangeVelocityDisplay_FMCW_triangle_DualRate_Plot.clear()
                    RangeVelocityDisplay_FMCW_triangle_DualRate_Plot.showGrid(x=True, y=True)
                    Frequency_FMCW_triangle_DualRate_Plot.clear()
                    labelStyle = {'color': '#000', 'font-size': '16px'}
                    Frequency_FMCW_triangle_DualRate_Plot.setLabel('left', "Amplitude (dB)", **labelStyle)

                    SpeedUnits_Selected = self.SpeedUnits_FMCW_triangle_DualRate.currentIndex()
                    if (SpeedUnits_Selected == 1):
                        SpeedFactor = 3.6
                        max_velocity *= SpeedFactor
                        self.label_MaximumSpeed_FMCW_triangle_DualRate.setText('Max Speed (km/h)')
                        RangeVelocityDisplay_FMCW_triangle_DualRate_Plot.setLabel('left', "Velocity (km/h)", **labelStyle)
                    elif (SpeedUnits_Selected == 2):
                        SpeedFactor = 2.23694
                        max_velocity *= SpeedFactor
                        self.label_MaximumSpeed_FMCW_triangle_DualRate.setText('Max Speed (mph)')
                        RangeVelocityDisplay_FMCW_triangle_DualRate_Plot.setLabel('left', "Velocity (mph)", **labelStyle)
                    else:
                        SpeedFactor = 1
                        self.label_MaximumSpeed_FMCW_triangle_DualRate.setText('Max Speed (m/s)')
                        RangeVelocityDisplay_FMCW_triangle_DualRate_Plot.setLabel('left', "Velocity (m/s)", **labelStyle)
                    self.MaximumSpeed_FMCW_triangle_DualRate.setValue(max_velocity)

                    DistanceUnits_Selected = self.DistanceUnits_FMCW_triangle_DualRate.currentIndex()
                    if (DistanceUnits_Selected == 0):
                        DistanceFactor = 1
                        self.label_MaximumDistance_FMCW_triangle_DualRate.setText('Maximum Distance (m)')
                        RangeVelocityDisplay_FMCW_triangle_DualRate_Plot.setLabel('bottom', "Distance (m)", **labelStyle)
                        Frequency_FMCW_triangle_DualRate_Plot.setLabel('bottom', "Distance (m)", **labelStyle)
                    elif(DistanceUnits_Selected == 1):
                        DistanceFactor = 3.28084
                        max_distance *= DistanceFactor
                        self.label_MaximumDistance_FMCW_triangle_DualRate.setText('Maximum Distance (ft)')
                        RangeVelocityDisplay_FMCW_triangle_DualRate_Plot.setLabel('bottom', "Distance (ft)", **labelStyle)
                        Frequency_FMCW_triangle_DualRate_Plot.setLabel('bottom', "Distance (ft)", **labelStyle)
                    else:
                        DistanceFactor = 1.09361
                        max_distance *= DistanceFactor
                        self.label_MaximumDistance_FMCW_triangle_DualRate.setText('Maximum Distance (yard)')
                        RangeVelocityDisplay_FMCW_triangle_DualRate_Plot.setLabel('bottom', "Distance (yard)", **labelStyle)
                        Frequency_FMCW_triangle_DualRate_Plot.setLabel('bottom', "Distance (yard)", **labelStyle)

                    # Update maximum distance indicator
                    self.MaximumDistance_FMCW_triangle_DualRate.setValue(max_distance)
                    R_axis = np.linspace(-c/(2*BW_actual) * Fs/2 * RampTimeReal, c/(2*BW_actual) * Fs/2 * RampTimeReal, num = N_FFT)
                    R_axis_2 = np.linspace(-c/(2*BW_actual) * Fs/2 * RampTimeReal_2, c/(2*BW_actual) * Fs/2 * RampTimeReal_2, num = N_FFT)

                    # Compute the complex vector (I - jQ)
                    ComplexVector_up_1 = I_up_1 + 1j*Q_up_1
                    ComplexVector_up_2 = I_up_2 + 1j*Q_up_2
                    ComplexVector_down_1 = I_down_1 - 1j*Q_down_1
                    ComplexVector_down_2 = I_down_2 - 1j*Q_down_2

                    # Apply the selected window to the complex vector previous to the FFT calculation
                    ComplexVector_up_1 = ComplexVector_up_1 * np.hanning(Nm_0) * 2 / 3.3
                    ComplexVector_down_1 = ComplexVector_down_1 * np.hanning(Nm_1) * 2 / 3.3
                    ComplexVector_up_2 = ComplexVector_up_2 * np.hanning(Nm_2) * 2 / 3.3
                    ComplexVector_down_2 = ComplexVector_down_2 * np.hanning(Nm_3) * 2 / 3.3

                    FrequencyDomain_up_1 = 2*np.absolute(fftshift(fft(ComplexVector_up_1 / Nm_0, N_FFT)))
                    FrequencyDomain_up_2 = 2*np.absolute(fftshift(fft(ComplexVector_up_2 / Nm_2, N_FFT)))
                    FrequencyDomain_down_1 = 2*np.absolute(fftshift(fft(ComplexVector_down_1 / Nm_1, N_FFT)))
                    FrequencyDomain_down_2 = 2*np.absolute(fftshift(fft(ComplexVector_down_2 / Nm_3, N_FFT)))

                    start = int(N_FFT/2)
                    FrequencyDomain_up_1[start] = FrequencyDomain_up_1[start - 1]
                    FrequencyDomain_down_1[start] = FrequencyDomain_down_1[start - 1]
                    FrequencyDomain_up_2[start] = FrequencyDomain_up_2[start - 1]
                    FrequencyDomain_down_2[start] = FrequencyDomain_down_2[start - 1]
                    FrequencyDomain_up_1 = 20 * np.log10(FrequencyDomain_up_1)
                    FrequencyDomain_down_1 = 20 * np.log10(FrequencyDomain_down_1)
                    FrequencyDomain_up_2 = 20 * np.log10(FrequencyDomain_up_2)
                    FrequencyDomain_down_2 = 20 * np.log10(FrequencyDomain_down_2)

                    PeaksIndex_Up_1, PeaksMagnitude_Up_1, PeaksSNR_Up_1, NumberOfPeaks_Up_1, threshold_Up_1, threshold_indexes = uRAD_processing.findPeaks(FrequencyDomain_up_1, 4, Nm_0, N_FFT)
                    PeaksIndex_Down_1, PeaksMagnitude_Down_1, PeaksSNR_Down_1, NumberOfPeaks_Down_1, threshold_Down_1, threshold_indexes = uRAD_processing.findPeaks(FrequencyDomain_down_1, 4, Nm_1, N_FFT)
                    PeaksIndex_Up_2, PeaksMagnitude_Up_2, PeaksSNR_Up_2, NumberOfPeaks_Up_2, threshold_Up_2, threshold_indexes = uRAD_processing.findPeaks(FrequencyDomain_up_2, 4, Nm_2, N_FFT)
                    PeaksIndex_Down_2, PeaksMagnitude_Down_2, PeaksSNR_Down_2, NumberOfPeaks_Down_2, threshold_Down_2, threshold_indexes = uRAD_processing.findPeaks(FrequencyDomain_down_2, 4, Nm_3, N_FFT)

                    NumberOfPeaks = 0
                    NumberOfPeaks_1 = 0
                    NumberOfPeaks_2 = 0

                    if (NumberOfPeaks_Up_1 > 0 and NumberOfPeaks_Down_1 > 0 and NumberOfPeaks_Up_2 > 0 and NumberOfPeaks_Down_2 > 0):

                        Distance_1, Velocity_1, SNR_1, Error_1, NumberOfPeaks_1 = uRAD_processing.processTriangleWaveformData(4, NumberOfPeaks_Up_1, NumberOfPeaks_Down_1, PeaksIndex_Up_1, PeaksIndex_Down_1, PeaksMagnitude_Up_1, PeaksMagnitude_Down_1, PeaksSNR_Up_1, PeaksSNR_Down_1, f_axis, max_fd, Ntar, f0, BW_actual, RampTimeReal)
                        Distance_2, Velocity_2, SNR_2, Error_2, NumberOfPeaks_2 = uRAD_processing.processTriangleWaveformData(4, NumberOfPeaks_Up_2, NumberOfPeaks_Down_2, PeaksIndex_Up_2, PeaksIndex_Down_2, PeaksMagnitude_Up_2, PeaksMagnitude_Down_2, PeaksSNR_Up_2, PeaksSNR_Down_2, f_axis, max_fd, Ntar, f0, BW_actual, RampTimeReal_2)

                        if (NumberOfPeaks_1 > 0 and NumberOfPeaks_2 > 0):

                            Distance, Velocity, SNR, NumberOfPeaks = uRAD_processing.processDualRateData(NumberOfPeaks_1, NumberOfPeaks_2, Distance_1, Distance_2, Velocity_1, Velocity_2, SNR_1, SNR_2, Error_1, Error_2, Ntar)

                    # Update Target List
                    self.PeakPosition_FMCW_triangle_DualRate_1.setValue(0)
                    self.PeakPosition_FMCW_triangle_DualRate_2.setValue(0)
                    self.PeakPosition_FMCW_triangle_DualRate_3.setValue(0)
                    self.PeakPosition_FMCW_triangle_DualRate_4.setValue(0)
                    self.PeakPosition_FMCW_triangle_DualRate_5.setValue(0)
                    self.PeakSpeed_FMCW_triangle_DualRate_1.setValue(0)
                    self.PeakSpeed_FMCW_triangle_DualRate_2.setValue(0)
                    self.PeakSpeed_FMCW_triangle_DualRate_3.setValue(0)
                    self.PeakSpeed_FMCW_triangle_DualRate_4.setValue(0)
                    self.PeakSpeed_FMCW_triangle_DualRate_5.setValue(0)
                    self.PeakMagnitude_FMCW_triangle_DualRate_1.setValue(0)
                    self.PeakMagnitude_FMCW_triangle_DualRate_2.setValue(0)
                    self.PeakMagnitude_FMCW_triangle_DualRate_3.setValue(0)
                    self.PeakMagnitude_FMCW_triangle_DualRate_4.setValue(0)
                    self.PeakMagnitude_FMCW_triangle_DualRate_5.setValue(0)

                    for index in range(NumberOfPeaks):
                        if (index == 0):
                            self.PeakPosition_FMCW_triangle_DualRate_1.setValue(Distance[index]*DistanceFactor)
                            self.PeakSpeed_FMCW_triangle_DualRate_1.setValue(Velocity[index]*SpeedFactor)
                            self.PeakMagnitude_FMCW_triangle_DualRate_1.setValue(SNR[index])
                        elif (index == 1):
                            self.PeakPosition_FMCW_triangle_DualRate_2.setValue(Distance[index]*DistanceFactor)
                            self.PeakSpeed_FMCW_triangle_DualRate_2.setValue(Velocity[index]*SpeedFactor)
                            self.PeakMagnitude_FMCW_triangle_DualRate_2.setValue(SNR[index])
                        elif (index == 2):
                            self.PeakPosition_FMCW_triangle_DualRate_3.setValue(Distance[index]*DistanceFactor)
                            self.PeakSpeed_FMCW_triangle_DualRate_3.setValue(Velocity[index]*SpeedFactor)
                            self.PeakMagnitude_FMCW_triangle_DualRate_3.setValue(SNR[index])
                        elif (index == 3):
                            self.PeakPosition_FMCW_triangle_DualRate_4.setValue(Distance[index]*DistanceFactor)
                            self.PeakSpeed_FMCW_triangle_DualRate_4.setValue(Velocity[index]*SpeedFactor)
                            self.PeakMagnitude_FMCW_triangle_DualRate_4.setValue(SNR[index])
                        elif (index == 4):
                            self.PeakPosition_FMCW_triangle_DualRate_5.setValue(Distance[index]*DistanceFactor)
                            self.PeakSpeed_FMCW_triangle_DualRate_5.setValue(Velocity[index]*SpeedFactor)
                            self.PeakMagnitude_FMCW_triangle_DualRate_5.setValue(SNR[index])

                    if (self.tabWidget_FMCW_triangle_DualRate.currentIndex() == 1):
                        # Clear the graph and plot I and Q signals
                        IQ_FMCW_triangle_DualRate_Plot.clear()
                        x_axis = np.linspace(1, Nm, num = Nm)
                        IQ_FMCW_triangle_DualRate_Plot.plot(x_axis[0:Nm_0], I_up_1, pen=pg.mkPen((0,0,255), width=2), name="I_up_1")
                        IQ_FMCW_triangle_DualRate_Plot.plot(x_axis[0:Nm_0], Q_up_1, pen=pg.mkPen((255,0,0), width=2), name="Q_up_1")
                        IQ_FMCW_triangle_DualRate_Plot.plot(x_axis[Nm_0 : Nm_0+Nm_1], I_down_1, pen=pg.mkPen((0,0,255), width=2, style=QtCore.Qt.DashLine), name="I_down_1")
                        IQ_FMCW_triangle_DualRate_Plot.plot(x_axis[Nm_0 : Nm_0+Nm_1], Q_down_1, pen=pg.mkPen((255,0,0), width=2, style=QtCore.Qt.DashLine), name="Q_down_1")
                        IQ_FMCW_triangle_DualRate_Plot.plot(x_axis[Nm_0+Nm_1 : Nm_0+Nm_1+Nm_2], I_up_2, pen=pg.mkPen((0,0,255), width=2), name="I_up_2")
                        IQ_FMCW_triangle_DualRate_Plot.plot(x_axis[Nm_0+Nm_1 : Nm_0+Nm_1+Nm_2], Q_up_2, pen=pg.mkPen((255,0,0), width=2), name="Q_up_2")
                        IQ_FMCW_triangle_DualRate_Plot.plot(x_axis[Nm_0+Nm_1+Nm_2 : Nm_0+Nm_1+Nm_2+Nm_3], I_down_2, pen=pg.mkPen((0,0,255), width=2, style=QtCore.Qt.DashLine), name="I_down_2")
                        IQ_FMCW_triangle_DualRate_Plot.plot(x_axis[Nm_0+Nm_1+Nm_2 : Nm_0+Nm_1+Nm_2+Nm_3], Q_down_2, pen=pg.mkPen((255,0,0), width=2, style=QtCore.Qt.DashLine), name="Q_down_2")
                        labelStyle = {'color': '#000', 'font-size': '16px'}
                        IQ_FMCW_triangle_DualRate_Plot.setLabel('bottom', "Samples", **labelStyle)
                        IQ_FMCW_triangle_DualRate_Plot.setLabel('left', "Amplitude", units='V', **labelStyle)

                        # IQ plot X and Y axes limits
                        YMin = -2
                        YMax = 2
                        if (YMax > YMin):
                            IQ_FMCW_triangle_DualRate_Plot.setYRange(YMin, YMax, padding=0)

                        Frequency_FMCW_triangle_DualRate_Plot.plot(R_axis, FrequencyDomain_up_1, pen=pg.mkPen((0,0,255), width=2), name="")
                        Frequency_FMCW_triangle_DualRate_Plot.plot(R_axis, FrequencyDomain_down_1, pen=pg.mkPen((0,0,255), width=2, style=QtCore.Qt.DashLine), name="")
                        Frequency_FMCW_triangle_DualRate_Plot.plot(R_axis_2, FrequencyDomain_up_2, pen=pg.mkPen((255,0,0), width=2), name="")
                        Frequency_FMCW_triangle_DualRate_Plot.plot(R_axis_2, FrequencyDomain_down_2, pen=pg.mkPen((255,0,0), width=2, style=QtCore.Qt.DashLine), name="")

                        if (self.AutoScaleX_FMCW_triangle_DualRate_2.isChecked()):
                            XMin = 0
                            XMax = 5 * np.ceil(max_distance/5)
                            if (XMax > XMin):
                                Frequency_FMCW_triangle_DualRate_Plot.setXRange(XMin, XMax, padding=0)
                        else:
                            XMin = self.XMin_FMCW_triangle_DualRate_2.value()
                            XMax = self.XMax_FMCW_triangle_DualRate_2.value()
                            XMin = np.max([XMin, -max_distance])
                            XMax = np.min([XMax, max_distance])
                            if (XMax > XMin):
                                Frequency_FMCW_triangle_DualRate_Plot.setXRange(XMin, XMax, padding=0)
                        YMin = -60
                        YMax = 0
                        if (YMax > YMin):
                            Frequency_FMCW_triangle_DualRate_Plot.setYRange(YMin, YMax, padding=0)

                    else:
                        if (self.checkBox_Hold.isChecked()):
                            if (Iterations_Hold < MaxIterations_Hold):
                                if (Iterations_Hold == 0):
                                    Range_Matrix = np.zeros((2, MaxIterations_Hold))
                                    Velocity_Matrix = np.zeros((2, MaxIterations_Hold))
                                    SNR_Matrix = np.zeros((2, MaxIterations_Hold))
                                Iterations_Hold += 1
                                for index_Ntar in range(2):
                                    Range_Matrix[index_Ntar, Iterations_Hold-1] = Distance[index_Ntar]
                                    Velocity_Matrix[index_Ntar, Iterations_Hold-1] = Velocity[index_Ntar]
                                    SNR_Matrix[index_Ntar, Iterations_Hold-1] = SNR[index_Ntar]
                            else:
                                Range_Matrix[:, 0:Iterations_Hold-1] = Range_Matrix[:, 1:Iterations_Hold]
                                Velocity_Matrix[:, 0:Iterations_Hold-1] = Velocity_Matrix[:, 1:Iterations_Hold]
                                SNR_Matrix[:, 0:Iterations_Hold-1] = SNR_Matrix[:, 1:Iterations_Hold]
                                for index_Ntar in range(2):
                                    Range_Matrix[index_Ntar, Iterations_Hold-1] = Distance[index_Ntar]
                                    Velocity_Matrix[index_Ntar, Iterations_Hold-1] = Velocity[index_Ntar]
                                    SNR_Matrix[index_Ntar, Iterations_Hold-1] = SNR[index_Ntar]

                            for index_iteration in range(Iterations_Hold):
                                for index_Ntar in range(2):
                                    if (1*int(SNR_Matrix[index_Ntar, index_iteration]) > 0):
                                        opacity = 0.1 + 0.8 * index_iteration/Iterations_Hold
                                        #print('%d' % index_iteration + ' , opacity: ' + '%1.2f' % opacity + ' , distance: ' + '%1.2f' % Range_Matrix[index_Ntar, index_iteration] + ' , velocity: ' + '%1.2f' % Velocity_Matrix[index_Ntar, index_iteration])
                                        RangeVelocityDisplay_FMCW_triangle_DualRate_Plot.plot(np.array([Range_Matrix[index_Ntar, index_iteration]*DistanceFactor, Range_Matrix[index_Ntar, index_iteration]*DistanceFactor]), np.array([Velocity_Matrix[index_Ntar, index_iteration]*SpeedFactor, Velocity_Matrix[index_Ntar, index_iteration]*SpeedFactor]), pen=(255,255,255, 1), symbolBrush=(255,0,0, 255*opacity), symbolSize=int(1*SNR_Matrix[index_Ntar, index_iteration]), symbolPen='w', name="")
                        else:
                            Iterations_Hold = 0
                            Range_Matrix = np.zeros((2, MaxIterations_Hold))
                            Velocity_Matrix = np.zeros((2, MaxIterations_Hold))
                            SNR_Matrix = np.zeros((2, MaxIterations_Hold))
                            for index in range(NumberOfPeaks):
                                if (int(1.5*SNR[index]) > 0):
                                    opacity = 0.9
                                    RangeVelocityDisplay_FMCW_triangle_DualRate_Plot.plot(np.array([Distance[index]*DistanceFactor, Distance[index]*DistanceFactor]), np.array([Velocity[index]*SpeedFactor, Velocity[index]*SpeedFactor]), pen=(255,255,255, 1), symbolBrush=(255,0,0, 255*opacity), symbolSize=int(1.5*SNR[index]), symbolPen='w', name="")

                        # RangeVelocityDisplay plot X and Y axes limits
                        AutoScaleX = self.AutoScaleX_FMCW_triangle_DualRate_1.isChecked()
                        AutoScaleY = self.AutoScaleY_FMCW_triangle_DualRate_1.isChecked()
                        if (not AutoScaleX):
                            XMin = self.XMin_FMCW_triangle_DualRate_1.value()
                            XMax = self.XMax_FMCW_triangle_DualRate_1.value()
                            XMin = np.max([XMin, -max_distance])
                            XMax = np.min([XMax, max_distance])
                            if (XMax > XMin):
                                RangeVelocityDisplay_FMCW_triangle_DualRate_Plot.setXRange(XMin, XMax, padding=0)
                        else:
                            XMin = 0
                            XMax = 5 * np.ceil(max_distance/5)
                            if (XMax > XMin):
                                RangeVelocityDisplay_FMCW_triangle_DualRate_Plot.setXRange(XMin, XMax, padding=0)
                        if (not AutoScaleY):
                            YMin = self.YMin_FMCW_triangle_DualRate_1.value()
                            YMax = self.YMax_FMCW_triangle_DualRate_1.value()
                            YMin = np.max([YMin, -max_velocity])
                            YMax = np.min([YMax, max_velocity])
                            if (YMax > YMin):
                                RangeVelocityDisplay_FMCW_triangle_DualRate_Plot.setYRange(YMin, YMax, padding=0)
                        else:
                            YMin = -5 * np.ceil(max_velocity/5)
                            YMax = 5 * np.ceil(max_velocity/5)
                            if (YMax > YMin):
                                RangeVelocityDisplay_FMCW_triangle_DualRate_Plot.setYRange(YMin, YMax, padding=0)

                    if (Mth > 0):
                        if (MTI > 0 and NumberOfPeaks > 0):
                            if (SNR[0] > 20*np.log10(factorPresencia_FMCW)):
                                movement = 1
                                self.movement_FMCW_triangle_DualRate.setPixmap(QtGui.QPixmap(common_path + "/resources/images/boton_movimiento_rojo.png"))
                            else:
                                movement = 0
                                self.movement_FMCW_triangle_DualRate.setPixmap(QtGui.QPixmap(common_path + "/resources/images/boton_movimiento_azul.png"))
                        else:
                            if (lastPresenceMode == 4):
                                if (len(I_old) == len(I_up_1)):
                                    ComplexVector = (I_up_1-I_old) + 1j*(Q_up_1-Q_old)
                                    ComplexVector = ComplexVector * np.hanning(Nm_0) * 2
                                    FrequencyDomain = 2*np.absolute(fftshift(fft(ComplexVector / Nm_0, N_FFT)))
                                    FrequencyDomain[start] = FrequencyDomain[start - 1]
                                    FrequencyDomain = 20 * np.log10(FrequencyDomain)

                                    movement_detected = uRAD_processing.findMovement(FrequencyDomain, 4, Nm_0, N_FFT)

                                    if (movement_detected):
                                        movement = 1
                                        self.movement_FMCW_triangle_DualRate.setPixmap(QtGui.QPixmap(common_path + "/resources/images/boton_movimiento_rojo.png"))
                                    else:
                                        movement = 0
                                        self.movement_FMCW_triangle_DualRate.setPixmap(QtGui.QPixmap(common_path + "/resources/images/boton_movimiento_azul.png"))
                                else:
                                    movement = 0
                                    self.movement_FMCW_triangle_DualRate.setPixmap(QtGui.QPixmap(common_path + "/resources/images/boton_movimiento_azul.png"))
                            else:
                                movement = 0
                                self.movement_FMCW_triangle_DualRate.setPixmap(QtGui.QPixmap(common_path + "/resources/images/boton_movimiento_azul.png"))

                            lastPresenceMode = 4
                            I_old = I_up_1
                            Q_old = Q_up_1

                    else:
                        movement = 0
                        lastPresenceMode = 0

                    if (self.SaveResults_Data.isChecked() and NumberOfPeaks > 0):
                        try:
                            fileRAW_results_Data = open(common_path + '/OutputFiles/results.txt', 'a')
                            results_string = '4 '
                            for i in range(NumberOfPeaks):
                                results_string += '%1.3f %1.2f %1.2f ' % (Distance[i], Velocity[i], SNR[i])
                            results_string += '%d %d %d ' % (Mth, movement, MTI)
                            fileRAW_results_Data.write(results_string + actualTime[0:-3] + '\n')
                        except:
                            self.errorDisplay.setText("Can't find 'OutputFiles' folder")

        # If the Stop Button has not been pressed, we recall this method after a certain time (in this time the GUI is available for the user interaction)
        if (run):
            timer = QTimer()
            timer.singleShot(10, self.run_code)
        else:
            FirstExecution_FMCW_sawtooth = True
            FirstExecution_CW = True
            FirstExecution_FMCW_triangle = True
            FirstExecution_FMCW_triangle_DualRate = True
            self.runButton.setText("Run")
            self.runButton.setChecked(False)
            # switch OFF uRAD
            #print("vamos a turn off")
            return_code = uRAD_USB_SDK11.turnOFF(ser)
            if (return_code != 0):
                self.errorDisplay.setText('uRAD does not respond, reset GUI')
                error = True
            if (ser.is_open):
                ser.close()
            if (error):
                self.errorDisplay.setText("Can't communicate with " + ser.port + " port")
                self.update_serial_ports_list()
                error = False

# Instancia para iniciar una aplicación
app = QApplication(sys.argv)

# Crear un objeto de la clase
_ventana = Ventana()

# Mostrar la ventana
_ventana.show()

# Ejecutamos la aplicación
app.exec_()