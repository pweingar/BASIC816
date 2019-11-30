
###
### Generate a version label
###

from datetime import date

major = 0
minor = 0

today = date.today()
print(".text \"v{:02}.{:02}\", $D1, \" ({})\"".format(major, minor, today.strftime("%Y-%m-%d")))
