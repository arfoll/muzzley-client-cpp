# Muzzley C++ Client

This repo contains the code for the [muzzley][muzzley_homepage] C++ client library.

# DEPENDENCIES

This library depends on:

- GCC 4.5+
- pthread

# INSTALL

## Linux
To install this library reproduce the following steps on a terminal:

> $ wget -O muzzley-client-cpp.zip https://github.com/muzzley/muzzley-client-cpp/archive/master.zip

> $ unzip muzzley-client-cpp.zip

> $ cd muzzley-client-cpp-master/

> $ make

> $ sudo make install

The library will be located in */usr/lib* and the header files (\*.h) will be located in */usr/include/muzzley*. 

# LINKING AND INCLUDING

You should include the *muzzley.h* header file in your program, so that you can access the Muzzley classes. Since the header file is installed in */usr/include/muzzley/*, you should use the *-I* flag when compiling.

Assuming that your main.cpp C++ file looks something like this:
```
#!c++

#include <signal.h>
#include <unistd.h>
#include <iostream>
#include <fstream>
#include <string>
#include <muzzley.h>

using namespace std;
using namespace __gnu_cxx;

int main(int argc, char* argv[]) {

	muzzley::Client _client;

	_client.on(muzzley::SignalingMessage, [] (muzzley::Message& _data, muzzley::Client& _client) -> bool {
		...
		return true;
	});
	...

	_client.connectApp("YOUR-APP-TOKEN-HERE");

	return 0;
}
```

A compilation command could look something like this:

> $ g++ -std=c++0x -I/usr/include/muzzley main.cpp -o mymuzzley -lpthread -lmuzzley

# LAMBDA FUNCTIONS

This library uses one of the most exciting features in C++11 standard, the ***Lambda-function***s. 

The ***Lambda-function*** declaration allows the definition of inline functions anywhere in the code,  a lot like every other coding-ninja-favourite languages such as Javascript, Python, etc. This makes the event handling programming more coeherent with nowadays coding habits and makes C++ a less rigid OO language and lot friendlier for programming paradigms that fall outside OO.

Let's look at an example:

```
#!c++
muzzley::Client _client;

_client.on(muzzley::SignalingMessage, [] (muzzley::Message& _data, muzzley::Client& _client) -> bool {
	...
	return true;
});
```
[Here][lambda_functions] is an excellent article on the subject.

# MAIN PROGRAM LOOP

Your program's interaction with this library is centered in 3 simple and well defined areas:

- *muzzley::Client* class instance declaration (initializes the library)
- event register (call your actions when the library receives a message) or callback register (pass a callback to be invoked when receiving a response to a given request)
- connecting the application or the user to the Muzzley server (pass an application or user token to the library and start the messaging loop)  

You can register handlers for the following events:

```
#!c++
enum EventType {
	Connect,  // when the application finishes connecting the server
	Handshake,  // when the application finishes handshaking the server
	ActivityCreated, // when an activity is created with success
	ActivityJoined,  // when a response to joinActivity is finished successfully
	ActivityTerminated,  // when an Activity Master quits
	ParticipantJoined,  // when a Participant (another app or user) joins an activity
	ParticipantQuit,  // when a Participant quits
	SignalingMessage,  // when a Signaling message is received
	ChangeWidget, // when a change widget request is received
	SetupComponent, // when a setup component request is received
	AppLoggedIn,  // when this app is successfully logged in
	UserLoggedIn, // when this user is successfully logged in
	WidgetAction // when a widget action is received
};
```

An event register could look something like this:
```
#!c++
muzzley::Client _client;

_client.on(muzzley::SignalingMessage, [] (muzzley::Message& _data, muzzley::Client& _client) -> bool {
	...
	return true;
});
```
Callback register also uses ***Lambda-function***s, It could look something like this:
```
#!c++
muzzley::Client _client;

_client.particpantReady([] (muzzley::Message& _data, muzzley::Client& _client) -> bool {
	...
	return true;
});
```

When you connect the application or the user to the Muzzley server (by invoking either ***connectApp*** or ***connectUser*** methods), the messaging loop starts. You can either run this loop synchronously or assynchronously, depending wether you want to keep control of the program loop or not.

You control this by invoking the *muzzley::Client::setLoopAssynchronous(bool _assync)*. Passing *true* value will give you back the control of the program by lanuching a thread and returning from the ***connectApp*** or ***connectUser*** methods. Not invoking the method or passing *false* value, will keep the program execution inside the library, never returning from the ***connectApp*** or ***connectUser*** methods.

Hence, a basic program could look something like this:
```
#!c++

#include <signal.h>
#include <unistd.h>
#include <iostream>
#include <fstream>
#include <string>
#include <muzzley.h>

using namespace std;
using namespace __gnu_cxx;

int main(int argc, char* argv[]) {

	// Create the Muzzley client
	muzzley::Client _client;

	// Register listener to be invoked when activity is sucessfully created.
	//
	// Don't bother to store the returned activityId, the Client class already does that,
	// access it through the 'getActivityId' method.
	//
	// Return 'false' if you want to stop other listeners from being invoked.
	_client.on(muzzley::ActivityCreated, [] (muzzley::Message& _data, muzzley::Client& _client) -> bool {
		if (!!_data["s"] && ((string) _data["d"]["activityId"]) != "121345") {

			muzzley::JSONObj _s_data;
			_s_data <<
				"w"<< "gamepad" <<
				"c"<< "ba" <<
				"v"<< "a" <<
				"e"<< "press";

			_client.sendSignal("changeWidget", _s_data, [] (muzzley::Message& _data, muzzley::Client& _client) -> bool {
				cout << "signal accepted by server" << endl << flush;
			});
		}
		return true;
	});

	// Register listener to be invoked when app receives a signal message.
	//
	// Return 'false' if you want to stop other listeners from being invoked.
	_client.on(muzzley::SignalingMessage, [] (muzzley::Message& _data, muzzley::Client& _client) -> bool {
		cout << (bool) _data["s"] << endl << flush;
		cout << (string) _data["d"]["a"] << endl << flush;
		return true;
	});

	// Connects the application to the Muzzley server.
	//
	// It will start the application loop synchronously,
	// i.e. the program will not execute anything below this line.
	_client.connectApp("YOUR-APP-TOKEN-HERE");

	return 0;
}
```

# REPLYING TO A MESSAGE

Sometimes you'll need to reply to a received message, especially when the received message is either of type *1* or *3*. The differents message types are:

**1**: Request Initiated by an endpoint (Application or Controller)

**2**: Reply to the endpoint

**3**: Request Initiated by the Muzzley Core server

**4**: Reply to the Muzzley Core server

**5**: Signaling (Fire and forget) between endpoints


In order to reply to a received message, you may use the *reply* method:
	
```
#!c++

	virtual bool reply(muzzley::JSONObj& _data_received, muzzley::JSONObj& _reply) final;
```

This method receives the original received message (to check for the original message type) and the data you want to reply with. The reply message fields are:

- **s**: A boolean representing whether the authentication request was successful *(mandatory)*
- **m**: A textual message explaining the result of the operation *(optional)*
- **d**: The aditional data *(optional)*

The *reply* method returns *true* if a message were sent and *false* if not (if the received message was of type *5*, for instance). 

Hence, replying, for instance, to a Signaling Message could look like this:

```
#!c++

_client.on(muzzley::SignalingMessage, [] (muzzley::Message& _data, muzzley::Client& _client) -> bool {
	if (_client.isReplyNeeded(_data)) {
		_client.reply(_data, JSON(
			"s" << "true" <<
			"m" << "this is a testing signal so is always successful!" <<
			"d" << JSON(
				"w" << "gamepad"
			)
		));
		cout << "great, replied to a Signal Message" << endl << flush;
	}
	return true;
});
```

#MAIN CLASSES

There are two classes that you have to learn how to use in order to adequatly use this library:

- **muzzley::Client**: will allow you to interact with the Muzzley server, as well as with other applications and users.
- **muzzley::JSONObj**; will allow you to easly manage data, either when sending it or receiving it.
- **muzzley::Message**; extends from *muzzley::JSONObj* and abstract the communication protocol.


## muzzley::Client

This class aggregates a set of methods that will allow the interaction between your application and the Muzzley server. Basically, implements the performatives described in the Muzzley Message Protocol document. 

This class methods are organized in the following way:

### Event registering and triggering
```
#!c++	
virtual void on(muzzley::EventType _type, muzzley::Handler _handler) final;
virtual void trigger(muzzley::EventType _type, muzzley::JSONObj& _data) final;
```

### Message Handling
```
#!c++	
virtual bool reply(muzzley::Message& _data_received, muzzley::Message& _reply) final;
```

### Protocol performatives

#### Connection & Authentication
```
#!c++	
virtual void connectApp(string _app_token, string _activity_id = "");
virtual void connectUser(string _user_token, string _activity_id);
```

#### Activity
```
#!c++	
virtual void createActivity();
virtual void joinActivity(string _activity_id = "");
virtual void quit();
virtual void participantQuit();
```

#### Signaling
```
#!c++	
virtual void participantReady(muzzley::Callback _callback = NULL);
virtual void changeWidget(long _participant_id, string _widget, muzzley::Callback _callback = NULL);
virtual void changeWidget(long _participant_id, string _widget, muzzley::JSONObj& _options, muzzley::Callback _callback = NULL);
virtual void changeWidget(long _participant_id, muzzley::JSONObj& _options, muzzley::Callback _callback);
virtual void setupComponent(long _participant_id, string _component, string _component_id, string _action, muzzley::Callback _callback = NULL);
virtual void setupComponent(long _participant_id, string _component, string _component_id, string _action, muzzley::JSONObj& _options, muzzley::Callback _callback = NULL);
virtual void sendSignal(long _participant_id, string _type, muzzley::Callback _callback = NULL);
virtual void sendSignal(long _participant_id, string _type, muzzley::JSONObj& _data, muzzley::Callback _callback = NULL);
virtual void sendSignal(string _type, muzzley::Callback _callback = NULL);
virtual void sendSignal(string _type, muzzley::JSONObj& _data, muzzley::Callback _callback = NULL);
virtual void sendWidgetData(string _widget, string _component, string _event_type, string _event_value);
```

### Getters and Setters
```
#!c++	
void setLoopAssynchronous(bool _assync);
const string& getActivityId() const;
const string& getDeviceId() const;
const string& getSessionId() const;
const long getParticipantId() const;
const ParticipantList& getParticipants() const;
```

### Flag testing
```
#!c++	
bool isReplyNeeded(muzzley::Message& _data_received) const;
bool isAppLoggedin() const;
bool isInitiatingMaster() const;
bool isConnected() const;
bool isLoopAssynchronous() const;
bool isStaticActivity() const;
bool isUserLoggedin() const;
```

## muzzley::JSONObj

This class stores JSON based message and aggregates a set of methods that allow you to access, in a fashionable manner, all the attributes and values of the object. It also allows you to construct a JSON based message from scratch.

### Smart pointers

The *muzzley::JSONObj* class is a smart pointer and that means that ou don't have to bother yourself with memory issues, once your done with your *muzzley::JSONObj* object just let it go out of it's context and thats it.

### '<<'' operator

This operator allows you to add attributes to your object:
```
#!c++
muzzley::JSONObj _o;
_o << "name" << "Mr Muzzley";
_o << "serial" << 123;
_o << "sorting_field" << "name";
```
or
```
#!c++
muzzley::JSONObj _o;
_o << 
	"name" << "Mr Muzzley" <<
	"serial" << 123 <<
	"sorting_field" << "name";
// this one is more JSON like
```

To add a JSON array, use the *muzzley::JSONArr* class:
```
#!c++
muzzley::JSONArr _a;
_a << 123 << 345 << 67 << 78;

muzzley::JSONArr _b;
_b << "lions" << 345 << "horses" << 78;

muzzley::JSONObj _o;
_o << 
	"name" << "Mr Muzzley" <<
	"serial" << 123 <<
	"sorting_field" << "name" <<
	"numbers" << _a <<
	"animal_numbers" << _b;
```
You can use the ***JSON*** and ***JSON_ARRAY*** macros to build an object in one line:
```
#!c++
muzzley::JSONObj _o = JSON(
	"name" << "Mr Muzzley" <<
	"serial" << 123 <<
	"sorting_field" << "name" <<
	"numbers" << JSON_ARRAY( 123 << 345 << 67 << 78 ) <<
	"animal_numbers" << JSON_ARRAY( "lions" << 345 << "horses" << 78 ) <<
	"location" << JSON(
		"city" << "Lisbon" <<
		"country" << "Portugal"
	)
);
```
### '[]' operator and casting operators

To access the *muzzley::JSONObj* values you use the *[]* operator (or a chain of *[]* operators). This operator accept either a string or a non-negative integer and returns the value associated with the given key or *false* (it's like an Hash map).

Casting operators are also provided, in order for you to convert the attribute value into the data type that best suits you:
```
#!c++
operator string();
operator bool();
operator int();
operator long();
operator long long();
operator unsigned int();
operator size_t();
operator double();
```

So, given the above example, you could use the following code: 
```
#!c++
int _serial = (int) _o["serial"];
int _first_number = (int) _o[ "numbers" ]\[0];
string _country = (string) _o["location"]\["country"];
```


[muzzley_homepage]: https://www.muzzley.com
[lambda_functions]: http://www.cprogramming.com/c++11/c++11-lambda-closures.html
