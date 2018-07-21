import QtQuick 2.7

Page1Form {
	button1.onClicked: {
		console.log ("Button Pressed. Entered text: " + textField1.text);
		console.warn("warn: " + textField1.text);
	}

  Component.onCompleted: {
            console.warn("warn completed")
            console.log("log completed")
            console.error("error completed")
            console.debug("debug completed")
            console.exception("exception completed")
            console.info("info completed")
  }
}
