var api = {
    m_wsurl: false,
    m_accessToken: false,
    m_username: false,

    m_chatHooks: [],

    m_chatSocket: false,
    m_reconnectTimer: false,
    m_chatModel: false,

    hookChat: function(callback) {
        if( this.m_chatHooks.indexOf(callback) !== -1 )
            return;
        this.m_chatHooks.push(callback);
    },

    setHostAndToken: function( owncastHost, accessToken )
    {
        let wsurl;
        if( owncastHost.substr(0,8) === 'https://' )
            wsurl = 'wss://' + owncastHost.substr(8) + '/ws';
        else
            wsurl = 'ws://' + owncastHost.substr(7) + '/ws';

        this.m_wsurl = wsurl;
        this.m_accessToken = accessToken;

        console.log("WS: Remote URL set to: "+wsurl);
        this.m_chatSocket.url = this.m_wsurl + '?accessToken=' + this.m_accessToken;
    },

    create: function(chatModel)
    {
        let self = this;
        this.m_chatModel = chatModel;

        this.m_chatSocket = Qt.createQmlObject('import QtWebSockets 1.1; WebSocket { id: socket }', chatModel, 'm_chatSocket');
        this.m_chatSocket.statusChanged.connect( function(status) {
            console.log("WebSocket status: "+status+" => "+self.m_chatSocket.errorString);
            if( status === 1 )
                self.socketConnected();
            else if( status === 3 )
                self.socketDisconnected();
        });
        this.m_chatSocket.textMessageReceived.connect( function(msg) {
            self.socketRead(msg);
        });

        this.m_reconnectTimer = Qt.createQmlObject('import QtQuick 2.0; Timer { id: timer }', chatModel, 'm_reconnectTimer');
        this.m_reconnectTimer.interval = 10000;
        this.m_reconnectTimer.repeat = false;
        this.m_reconnectTimer.triggered.connect( function() { self.open() } );
    },

    open: function()
    {
        this.m_chatSocket.active = false;

        console.log("WS: Connecting...");
        this.m_chatSocket.active = true;
    },

    close: function()
    {
        console.log("WS: Disconnecting.");
        this.m_chatSocket.active = false;
    },

    socketConnected: function()
    {
        console.log("WS: Connected.");
        this.m_reconnectTimer.stop();
    },

    socketRead: function(message)
    {
        let self = this;
        let json;
        try {
            json = JSON.parse(message);
        } catch(err) {
            console.log("Parse error: "+message);
            return;
        }

        if( json['type'] === 'PING' )
        {
            const reply = JSON.stringify( { 'type':'PONG', 'body':json['body'] } );
            this.m_chatSocket.sendTextMessage(reply);
        }
        else if( json['type'] === 'NAME_CHANGE'
              || json['type'] === 'USER_JOINED'
              || json['type'] === 'CHAT_ACTION' )
            this.chatAction(json);
        else if( json['type'] === 'CHAT' )
            this.chatSingleMessage( json );
        else if( json['type'] === 'CONNECTED_USER_INFO' )
            this.m_username = json['user']['displayName'];
        else if( json['type'] !== 'VISIBILITY-UPDATE' )
        {
            this.chatAction( { 'type':'unknown', 'body':JSON.stringify(json,null,2) } );
        }
    },

    socketDisconnected: function()
    {
        console.log("WS: Disconnected.");
        try {
            this.m_reconnectTimer.start();
        } catch(e) {
            console.log("WS: Reconnect timer stopped: "+e);
        }
    },

    serverStats: function( cb )
    {
        return this.httpRequester( 'https://oneill.stream/api/status', cb, [] );
    },

    chatAction: function(packet)
    {
        let colour = '#cabada';
        let msg = `Action: ${packet['type']} -> ${packet['body']}`;
        if( packet['type'] === 'NAME_CHANGE' )
        {
            colour = '#aa7788';
            const oldName = packet['oldName'];
            const username = packet['user']['displayName'];
            msg = `User '${oldName}' is now known as '${username}'.`;
        }
        else if( packet['type'] === 'USER_JOINED' )
        {
            colour = '#ff7799';
            const username = packet['user']['displayName'];
            msg = `User '${username}' has joined.`;
        }
        else if( packet['type'] === 'CHAT_ACTION' )
        {
            colour = '#ddaa88';
            msg = packet['body'];
        }
	
        let ts = new Date(packet['timestamp']);
        let shortTime = `${ts.getHours()}:${(''+ts.getMinutes()).padStart(2, '0')}`;
	
        let message = `<span style="font-weight: 700; color: ${colour}">${msg}</span>`;
        let ent = {
            'type': 'action',
            'message': message,
            'timestamp': shortTime
        }

        console.log("Message: "+JSON.stringify(ent,null,2));
        for( var x=0; x < this.m_chatHooks.length; x++ )
        {
            this.m_chatHooks[x]( ent );
        }
    },

    chatSingleMessage: function(packet)
    {
        let message = packet['body'];
        let username = packet['user']['displayName'];
        if( message.length === 0 ) return;

        message = message.replace('\r', '');

        const colour = packet['user']['displayColor'];
        let ts = new Date(packet['timestamp']);
        let shortTime = `${ts.getHours()}:${(''+ts.getMinutes()).padStart(2, '0')}`;
        let msg = {
            'type': 'chat',
            'username': username,
            'styledusername': `<span style="font-weight: 700; color: #${colour}">${username}</span>`, 
            'timestamp': shortTime,
            'message': message
        }

        console.log("Message: "+JSON.stringify(msg,null,2));
        for( var x=0; x < this.m_chatHooks.length; x++ )
        {
            this.m_chatHooks[x]( msg );
        }
    },

    sendMessage: function(message) {
        const obj = { 'type':'CHAT', 'body':message };
        const txt = JSON.stringify(obj);
        console.log("Sending message: "+txt);
        this.m_chatSocket.sendTextMessage(txt);
    },

    httpRequester: function(url, callback, headers) {
        var doc = new XMLHttpRequest();
        doc.onreadystatechange = function() {
            if (doc.readyState === XMLHttpRequest.DONE) {
                var a = doc.responseText;
                callback(a);
            }
        }

        doc.open("GET", url);
        if( headers )
        {
            for( var x=0; x < headers.length; x++ )
            {
                var h = headers[x];
                doc.setRequestHeader(h[0], h[1]);
            }
        }
        doc.send();
    },

    httpPostRequester: function(url, callback, headers, params) {
        var doc = new XMLHttpRequest();
        doc.onreadystatechange = function() {
            if( doc.readyState === XMLHttpRequest.DONE )
            {
                console.log("Response status: "+doc.status);
                var a = doc.responseText;
                callback(a);
            }
        }

        doc.open("POST", url, true);
        doc.setRequestHeader('Content-Type', 'application/x-www-form-urlencoded');
        if( headers )
        {
            for( var x=0; x < headers.length; x++ )
            {
                var h = headers[x];
                doc.setRequestHeader(h[0], h[1]);
            }
        }
        doc.send(params);
    }
};
