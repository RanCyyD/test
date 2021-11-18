# This programm says hello and asks for my name

print('Hello world!')
print ('What is your name?') # asks for name
myName = input()
print('It is good to meet you, ' +myName) 
print('The length of your name is:')
print(len(myName))
print('What is your age?')
myAge = input()
print('You will be ' + str(int(myAge) + 1)+ ' in a year!')

print('What is your age?')
myAge2 = input()
print('Together your are ' + str(int(myAge) + int(myAge2))+ ' !')

print(myAge + myAge2)