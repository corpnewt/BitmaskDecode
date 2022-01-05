#!/usr/bin/env python
import sys, os, re, json
if 2/3==0: input=raw_input

# Load our settings
os.chdir(os.path.dirname(os.path.realpath(__file__)))
data_file = "data.json"
if not os.path.exists(data_file):
    print("Could not locate {} - aborting!".format(data_file))
    print("")
    input("Press [enter] to exit...")
    exit()
try:
    data_list = json.load(open(data_file))
    assert isinstance(data_list,list)
except Exception as e:
    print("Could not load {}, or the data was not a list - aborting!".format(data_file))
    if len(str(e)): print(" - {}".format(str(e)))
    print("")
    input("Press [enter] to exit...")
    exit()

def cls():
  	os.system('cls' if os.name=='nt' else 'clear')

def get_binstr(number,block=8):
    dec = get_decimal(number)
    binstr = "{0:08b}".format(dec)
    if block == 0: return binstr # Not breaking into chunks
    # Format into chunks separated by space
    if len(binstr)%block: binstr = "0"*(block-(len(binstr)%block))+binstr
    return " ".join([binstr[i:i+block] for i in range(0, len(binstr), block)])

def get_str_rep(number,show_hex=True,show_dec=True,show_bin=False,bin_block=8):
    dec = get_decimal(number)
    str_rep = ""
    if show_hex: str_rep += "0x{} ".format(hex(dec)[2:].upper())
    if show_dec: str_rep += "({:,}) ".format(dec)
    if show_bin: str_rep += "[{}] ".format(get_binstr(dec,bin_block))
    return str_rep

def get_decimal(number):
    if isinstance(number,(float,int)): return number
    try: return int(number,16) if str(number).lower().startswith("0x") else int(number.replace(",",""))
    except: return 0

def num_to_vals(number,bit_dict):
    # Convert the hex to decimal string - then start with a reversed list
    # and find out which values we have enabled
    dec = get_decimal(number)
    if not dec: return []
    return [(bit_dict[x],get_str_rep(x)) for x in sorted(bit_dict) if x & dec]

def main(self_name,bit_dict):
    while True:
        cls()
        print("# {} Decode #".format(self_name))
        print("")
        print("1. Number To Values")
        print("2. Values to Number")
        print("")
        print("M. Return To Selection Menu")
        print("Q. Quit")
        print("")
        menu = input("Please select an option:  ").lower()
        if not len(menu):
            continue
        if menu == "q":
            exit()
        elif menu == "m":
            return
        elif menu == "1":
            n_to_v(self_name,bit_dict)
        elif menu == "2":
            v_to_n(self_name,bit_dict)
    
def n_to_v(self_name,bit_dict):
    cls()
    print("# {} Number To Values #".format(self_name))
    print("")
    print("M. Main Menu")
    print("Q. Quit")
    print("")
    while True:
        h = input("Please type a {} value (use 0x prefix for hex):  ".format(self_name))
        if not h: continue
        if h.lower() == "m": return
        elif h.lower() == "q": exit()
        has = num_to_vals(h,bit_dict)
        if not len(has): print("\nNo values found.\n")
        else:
            pad_to = max((len(x[0]) for x in has))
            print("\nActive values for {}:\n\n{}\n".format(get_str_rep(h),"\n".join(["{} - {}".format(x[0].ljust(pad_to),x[1]) for x in has])))

def v_to_n(self_name,bit_dict):
    # Create a dict with all values unchecked
    toggle_list = [{"value":x,"enabled":False,"name":bit_dict[x]} for x in sorted(bit_dict)]
    while True:
        cls()
        print("# {} Values To Number #".format(self_name))
        print("")
        # Print them out
        if not len(toggle_list): print(" - None found :(")
        else:
            pad_to = max((len(x["name"]) for x in toggle_list))
            for x,y in enumerate(toggle_list,1):
                print("[{}] {}. {} - {}".format("#" if y["enabled"] else " ", str(x).rjust(2), y["name"].ljust(pad_to),get_str_rep(y["value"])))
        print("")
        # Add the values of the enabled together
        curr = sum([x["value"] for x in toggle_list if x["enabled"]])
        print("Current:  {}".format(get_str_rep(curr)))
        print("")
        print("A. Select All")
        print("N. Select None")
        print("M. Main Menu")
        print("Q. Quit")
        print("")
        print("Select options to toggle with comma-delimited lists (eg. 1,2,3,4,5)")
        print("")
        menu = input("Please make your selection:  ").lower()
        if not len(menu): continue
        if menu == "m": return
        elif menu == "q": exit()
        elif menu == "a":
            for x in toggle_list: x["enabled"] = True
            continue
        elif menu == "n":
            for x in toggle_list: x["enabled"] = False
            continue
        # Should be numbers
        try:
            nums = [int(x) for x in menu.replace(" ","").split(",")]
            for x in nums:
                if not 0 < x <= len(toggle_list): continue
                toggle_list[x-1]["enabled"] ^= True
        except: continue

def top_menu():
    # Let's load the data file and serve up the options
    while True:
        cls()
        print("# Select The Value To Decode #")
        print("")
        # Print them out
        if not len(data_list): print(" - None found :(")
        else:
            for x,y in enumerate(data_list,1):
                print("{}. {}".format(str(x).rjust(2), y.get("name","Unknown")))
        print("")
        print("Q. Quit")
        print("")
        menu = input("Please select an option:  ").lower()
        if not len(menu): continue
        if menu == "q": exit()
        try: menu = int(menu)
        except: continue
        if not 0 < menu <= len(data_list): continue
        # Should have a valid entry here
        selected = data_list[menu-1]
        bit_dict = {}
        self_name = selected.get("name","Unknown")
        # Build a dict with the keys being the addresses, and the values being the names
        for x in selected.get("values",[]):
            if not all((y in x for y in ("value","name"))): continue # Malformed
            try: key = int(x["value"],16 if selected.get("is_hex",False) else 10)
            except: continue
            bit_dict[key] = x["name"]
        main(self_name,bit_dict)

if __name__ == '__main__':
    top_menu()
