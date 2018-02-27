#!/usr/bin/python2.7

# Copyright https://github.com/kovaxalive

from __future__ import print_function
import subprocess, time, sys, os
import argparse, numpy
import curses

parser = argparse.ArgumentParser(
 formatter_class=argparse.ArgumentDefaultsHelpFormatter)
parser.add_argument('-u', '--update-time',
		help="Time between fan adjustments/checks in seconds",type=int, default=1)
parser.add_argument('-T', '--target-temp',
		help="Target temperature in degrees Celsius", type=int, default=60)
parser.add_argument('-m', '--min-speed',
		help="Minimum fan speed of GPU in %%. Warning: imprecise",
		type=int, default=40)
parser.add_argument('--dynamic-printing',
		help="Use curses to print in current terminal (experimental, try enlarging terminal)",
		type=bool, default=False)
args = parser.parse_args()

time_between_fan_check = args.update_time
assert 25 < args.target_temp < 100, "Irrational target temperature"
assert 0 <= args.min_speed <= 100,\
	"Minimum fan speed must be between 0 and 100"

try:
	open('/root/mrminer/lib/speeds.txt', 'r')
except IOError:
	print("""Could not import speeds.txt,
	 ensure you are in the same folder as the python script file
	is located""")
	exit()

tempgoal = args.target_temp
min_speed = args.min_speed

def execute(cmd, print_output=False):
	original_stdout = sys.stdout

	if not print_output:
		nullfile = open(os.devnull, 'w')
		sys.stdout = nullfile

	subprocess.Popen(cmd, shell=True)

	sys.stdout = original_stdout


def get_stdout(cmd, first_line=False, split_cmd=False, parse_int=True):
	stdout = []

	if split_cmd:
		cmd = cmd.split()

	popen=subprocess.Popen(cmd, stdout=subprocess.PIPE, universal_newlines=True,
		shell=True) 	# shell = true allow wildcards

	for stdout_line in iter(popen.stdout.readline, ""):
		if first_line:
			if parse_int:
				# Return int if possible
				try:
				     return int(stdout_line.strip())
				except ValueError:
					pass
			return stdout_line.strip()

		stdout.append(stdout_line.strip())

	popen.stdout.close()
	return_code = popen.wait()
	if return_code:
		raise subprocess.CalledProcessError(return_code, cmd)

	return stdout

class setFanSpeed:
	get_path_cmd = "ls -d "
	cards_dir = "/sys/class/drm/card?/"
	mon_dir = "hwmon?/"
	carddir = "ls -d /sys/class/drm/card?/device/hwmon/"

	def get_possible_fan_speeds(self):
		self.real_speeds = {}
		with open('/root/mrminer/lib/speeds.txt', 'r') as f:
			for line in f.readlines():
				line=line.strip().split()
				self.real_speeds[int(line[1])] = int(line[0]) # RealSpeed => SetSpeed

	def __init__(self, min_speed):
		# cmd = self.get_path_cmd + self.cards_dir
		cmd = self.carddir
		self.cards = get_stdout(cmd, split_cmd=False)
		self.first_speedset = []
		self.minimum_fan_speed = min_speed
		self.get_possible_fan_speeds()

	def pwm_enable(self, working_dir):
		pwm_status_file = working_dir + "pwm1_enable"

		pwm_status = lambda: get_stdout(
				"head -1 " + pwm_status_file,
				first_line=True)

		if pwm_status() == 0:
			print("PWM disabled", end='')

		elif pwm_status() != 1:
			print("Unknown PWM", end='')

		else:
			print("PWM already enabled for " + self.currentGPU)
			return True

		print( "for %s. Attempting to enable..." % (self.currentGPU))
		print(pwm_status(), working_dir)

		execute("sudo chown $USER " + pwm_status_file)
		execute('echo -n "1" >> ' + pwm_status_file)

		if pwm_status() != 1:
			print("PWM enabling failed for " + self.currentGPU)
			return False
		else:
			print("PWM succesfully enabled for " + self.currentGPU)
			return True


	def set_fan_speed(self, working_dir, tempgoal):
		pwm_file = working_dir + "pwm1"

		execute("sudo chown $USER " + pwm_file)

		maxspeed = get_stdout("head -1 " + working_dir + "pwm1_max",
				first_line=True)
		minspeed = get_stdout("head -1 " + working_dir + "pwm1_min",
				first_line=True)

		# Set minspeed in %, prevent division by 0
		minspeed_pct = 0 # Absolute minimum fan speed, == 0
		if minspeed != 0:
			minspeed_pct = float(minspeed) / maxspeed * 100


		current_fan_speed = lambda: get_stdout("head -1 " + pwm_file,
				first_line=True)

		speed_RPM = current_fan_speed()
		speed = float(speed_RPM) / maxspeed * 100 # In percentage


		temp = self.get_temp(working_dir)

		print("\n\n\t\tTemp =  %i `C, Fanspeed =  %i %% [ %i RPM ]\n\n\n" % (temp,
					 speed, current_fan_speed()) )

		new_speed = None

		temp_diff = temp - tempgoal
		temp_diff_proportion = temp_diff / float(temp)

		# 1/0.015 == made-up adjusted fan+1% ratio based on temp_diff_proportion,
		#  ideal values may vary based on average temps and purpose
		fanspeed_step = round(temp_diff_proportion / 0.015)

		if speed < 50 and self.cardcount not in self.first_speedset:
			# Prevent slow adjustment during first run
			new_speed = 70
			self.first_speedset.append(self.cardcount)
		elif temp_diff == 0:
			print("Temperature is exactly on point: %i `C" % tempgoal)
			update_curses(self.cardcount, temp, temp_diff,speed_RPM, speed)
			return True
		else:
			new_speed = speed + fanspeed_step # Declare new speed based on fanspeed_step

		if new_speed > 100:
			new_speed = 100
		elif new_speed < self.minimum_fan_speed:
			new_speed = self.minimum_fan_speed

		if new_speed == 100 and speed == 100:
			print(self.currentGPU, "is already on max speed and is above target temp.",
			"\t" + self.currentGPU, "T = %i `C\n" % ( temp) +\
			"Might want to improve cooling...\n")
			update_curses(self.cardcount, temp, temp_diff,speed_RPM, speed)
			return True



		if new_speed != None and\
		new_speed > minspeed_pct and new_speed <= 100 :
			print("\nAdjusting fan speed:")
			print("Intended speed:", new_speed)

			new_speed = int(round(new_speed * maxspeed / 100.0)) # Convert to RPM
			intended_speed = new_speed

			print("Intended speed:", intended_speed, "RPM")

			if new_speed > min(self.real_speeds.keys()):

				if 0 < temp_diff < 1.49: # Add one extra notch of speed to get to or under tempgoal
					closest_possible_true_speed =\
					self.real_speeds.keys()[self.real_speeds.keys().index(\
					min(self.real_speeds.keys(), key=lambda x: abs(x-new_speed)) ) + 1]
				else:
					closest_possible_true_speed =\
					min(self.real_speeds.keys(), key=lambda x: abs(x-new_speed))
				new_speed = self.real_speeds[closest_possible_true_speed] # Get set speed for true speed

				print("Closest possible speed to intended",\
				closest_possible_true_speed, "RPM")

			adjustment_status = get_stdout('echo -n "%i" >> ' % (new_speed) + pwm_file)

			margin_of_error = 2 # %

			time.sleep(0.75)

			true_new_speed = current_fan_speed()

			adjustment_error = (intended_speed - true_new_speed)  / float(maxspeed) * 100

			print("True new speed:", true_new_speed, "RPM")

			if margin_of_error >= abs(adjustment_error):
				print ("Fan adjusted correctly")

			print("Fan speed adjustment error:", adjustment_error, "%",
				end='\n\n')

			update_curses(self.cardcount, temp, temp_diff, \
                 true_new_speed, true_new_speed / float(maxspeed) * 100)



	def get_temp(self, working_dir):
		temp_file = working_dir + "temp1_input"

		temp = get_stdout("head -1 " + temp_file, first_line=True)

		if type(temp) == int and temp > 0:
			# temp is degrees Celsius * 1000 in file
			return temp / 1000.0 # for easier processing


	def set_all_fan_speeds(self, tempgoal=62):
		self.cardcount = 0
		for card in self.cards:
			self.currentGPU = "GPU" + str(self.cardcount)
			working_dir = get_stdout(self.get_path_cmd + card + self.mon_dir,
				first_line=True)

			if self.pwm_enable(working_dir):
				self.set_fan_speed(working_dir, tempgoal=tempgoal)

			self.cardcount += 1


## Execution
# Prevent current fan speeds below minimum from staying there
a = setFanSpeed(min_speed)

if not args.dynamic_printing:
	print("Control+C to quit\n")
	print("Detected %i GPUs" % (len(a.cards)), '\n')
	def update_curses(gpu_idx, temp, temp_diff, fan_rpm, fan_pct):
		pass
	while True:
		a.set_all_fan_speeds(tempgoal=tempgoal)
		time.sleep(time_between_fan_check)
	exit()

window = curses.initscr()
curses.noecho()
curses.cbreak()
curses.curs_set(0) # Hide cursor

max_screen = tuple(numpy.subtract(window.getmaxyx(), (1, 1) ) )

def make_curses_coords():
	global window

	curses_positions = {}
	init_x = 0
	init_y = 5
	width = 45
	height = 6

	x = init_x
	y = init_y
	for i in range(len(a.cards)):
		y = y + i*height

		pos = (y, x)
          # Do not allow positioning outside (or on border) of screen
		if pos >= max_screen:
			y = init_y
			x = init_x + width

		if pos >= max_screen:
			break # If it is broken, dont fix it
		curses_positions[i] = pos
	return curses_positions

curses_positions = make_curses_coords()
def update_curses(gpu_idx, temp, temp_diff, fan_rpm, fan_pct):

	string = "\tGPU%i" % (gpu_idx) + '\n' + \
	"Current temp:\t\t{temp} `C\n".format(temp=temp) +\
	"Temp above goal:\t{temp_diff} `C\n".format(temp_diff=temp_diff) +\
	"Fan speed:\t\t%.1f %%\t[ %i RPM ]" % (fan_pct, fan_rpm)

	try:
		y, x = curses_positions[gpu_idx]
		window.insstr(y, x, string)
	except KeyError:
		pass

window.nodelay(1) # Make window.getch() non-blocking
key=''
while key != ord('q'):
	key = window.getch()
	window.clear()
	window.addstr("\t\tPress Q at any time to quit...\n")
	window.addstr("GPUs detected: %i\n" % (len(a.cards)) )
	window.addstr("Global GPU temperature goal: %i `C"% (tempgoal))

	# Prevent conventional printing by pointing stdout to /dev/null
     #  temporarily

	stdout = sys.stdout
	sys.stdout = open(os.devnull, 'w')

	a.set_all_fan_speeds(tempgoal=tempgoal)

	sys.stdout.close()
	sys.stdout = stdout

	window.refresh()
	time.sleep(time_between_fan_check)

curses.nocbreak()
curses.curs_set(1)
curses.echo()
curses.endwin() # Restore original terminal
