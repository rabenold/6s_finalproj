from cocotb.handle import SimHandleBase
import logging
from axis_monitor import AXISMonitor
from axis_driver import AXISDriver
from cocotb_bus.scoreboard import Scoreboard

import numpy as np
from scipy.fft import fft, fftfreq

exact_output = np.array([[-4.15375000e+02, -3.01857173e+01, -6.11970620e+01,
         2.72393225e+01,  5.61250000e+01, -2.00951738e+01,
        -2.38764710e+00,  4.61815442e-01],
       [ 4.46552370e+00, -2.18574393e+01, -6.07580381e+01,
         1.02536368e+01,  1.31451101e+01, -7.08741801e+00,
        -8.53543671e+00,  4.87688850e+00],
       [-4.68344847e+01,  7.37059735e+00,  7.71293876e+01,
        -2.45619822e+01, -2.89116884e+01,  9.93352095e+00,
         5.41681547e+00, -5.64895086e+00],
       [-4.85349667e+01,  1.20683609e+01,  3.40997672e+01,
        -1.47594111e+01, -1.02406068e+01,  6.29596744e+00,
         1.83116505e+00,  1.94593651e+00],
       [ 1.21250000e+01, -6.55344993e+00, -1.31961210e+01,
        -3.95142773e+00, -1.87500000e+00,  1.74528445e+00,
        -2.78722825e+00,  3.13528230e+00],
       [-7.73474368e+00,  2.90546138e+00,  2.37979576e+00,
        -5.93931394e+00, -2.37779671e+00,  9.41391596e-01,
         4.30371334e+00,  1.84869103e+00],
       [-1.03067401e+00,  1.83067444e-01,  4.16815472e-01,
        -2.41556137e+00, -8.77793920e-01, -3.01930655e+00,
         4.12061242e+00, -6.61948454e-01],
       [-1.65375602e-01,  1.41607122e-01, -1.07153639e+00,
        -4.19291208e+00, -1.17031409e+00, -9.77610793e-02,
         5.01269392e-01,  1.67545882e+00]])
class Tester:
    """
    Checker of a split square sum instance
    Args
      dut_entity: handle to an instance of split-square-sum
    """
    def __init__(self, dut_entity: SimHandleBase, debug=False):
        self.dut = dut_entity
        self.log = logging.getLogger("cocotb.tb")
        self.log.setLevel(logging.ERROR)
        self.input_mon = AXISMonitor(self.dut,'s00',self.dut.s00_axis_aclk, callback=self.model)
        self.output_mon = AXISMonitor(self.dut,'m00',self.dut.s00_axis_aclk)
        self.input_driver = AXISDriver(self.dut,'s00',self.dut.s00_axis_aclk)
        self._checker = None
        self.calcs_sent = 0
        # Create a scoreboard on the stream_out bus
        self.expected_output = [] #contains list of expected outputs (Growing)
        self.scoreboard = Scoreboard(self.dut)#, fail_immediately=False)
#        self.scoreboard.add_interface(self.output_mon, self.expected_output, compare_fn=self.compare)
        self.counter = 0
 
    def start(self) -> None:
        """Starts everything"""
        if self._checker is not None:
            raise RuntimeError("Monitor already started")
        self.input_mon.start()
        self.output_mon.start()
        self.input_driver.start()
 
    def stop(self) -> None:
        """Stops everything"""
        if self._checker is None:
            raise RuntimeError("Monitor never started")
        self.input_mon.stop()
        self.output_mon.stop()
        self.input_driver.stop()
 
    def model(self, transaction):
      #define a model here
      result = transaction.copy()
      #data = transaction['data'].signed_integer#.to_bytes(4,byteorder='big', signed=True)
      
#      print('data', transaction['data'])
      #bottom = transaction['data'][16:31]
      #top = transaction['data'][0:15]
#      print(f"bottom {bottom} is {bottom.signed_integer}")
#      print(f"top {top} is {top.signed_integer}")
      #result['data'] = bottom.signed_integer**2 + top.signed_integer**2
      #(transaction['data']>>16)**2+((transaction['data']<<16)>>16)**2
      
      self.expected_output.append(exact_output[self.counter//8][self.counter%8])
      self.counter += 1


#    def compare(self,got):
#        print(got)
#        print(exp)
#        for i, output in enumerate(self.expected_output):
#            if output['count'] == got['count']:
#                break
#        exp = self.expected_output.pop(i)
#        #exp = self.expected_output[-1]
#        print(f"got {int(got['data'])} and expected {exp['data']}")
#        assert abs(int(got['data']) -  exp['data']) <= 1, f"got {int(got['data'])} and expected {exp['data']}"
