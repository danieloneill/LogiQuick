var api = {
    m_authurl: 'https://twitchoverlay.invalid/',

    m_chatHooks: [],
    m_avatarHooks: [],
    m_users: [],

    // FIXME: This is to prevent duplicate messages.
//    m_hack_lastLine: '',
    m_tryingToLogin: false,

    m_chatSocket: false,
    m_reconnectTimer: false,
    m_refreshTimer: false,
    m_chatModel: false,

    m_authkey: false,
    m_username: false,
    m_clientid: false,
    m_clientsecret: false,
    m_channel: false,
    m_expires: 0,
    m_refreshtoken: false,

    joinChat: function(chatModel)
    {
        this.m_chatModel = this.create(chatModel);
        this.open();
    },

    hookChat: function(callback) {
        if( this.m_chatHooks.indexOf(callback) != -1 )
            return;
        this.m_chatHooks.push(callback);
    },

    hookAvatar: function(callback) {
        if( this.m_avatarHooks.indexOf(callback) != -1 )
            return;
        this.m_avatarHooks.push(callback);
    },

    getUsername: function()
    {
        console.log("Updating username...");
        var url = 'https://id.twitch.tv/oauth2/validate';
        var headers = [ ['Authorization', 'OAuth '+this.m_authkey ] ];

        this.httpRequester(url, function(pkt) {
            var json = JSON.parse(pkt);

            this.m_username = json['login'];
            this.m_channel = json['login'];
        }, headers);
    },

    updateRefresh: function()
    {
        if( this.m_refreshTimer )
            delete this.m_refreshTimer;

        var expdobj = new Date(this.m_expires);
        var nowdobj = new Date();

        var diff = expdobj - nowdobj;

        if( diff < 0 )
        {
            // We're going to have to reauthorise....
        }
        else
        {
            var timebuffer = 5 * 60 * 1000; // Refresh 5 mins (300000ms) before the token expires.
            var delay = diff - timebuffer;
            console.log("Updating refresh timer to launch in "+delay+"ms");

            var self = this;
            // Parent depends on where this is instantiated. It will be either chatter or syncWindow
            this.m_refreshTimer = Qt.createQmlObject('import QtQuick 2.0; Timer { id: timer }', chatter, 'm_refreshTimer');
            this.m_refreshTimer.interval = delay;
            this.m_refreshTimer.repeat = false;
            this.m_refreshTimer.triggered.connect( function() { self.refresh(); } );
        }
    },

    handleRefresh: function(pkt)
    {
        // TODO: Handle errors:
        console.log("Refresh result: "+pkt);
        try {
            var json = JSON.parse(pkt);

            this.m_authkey = json['access_token'];
            this.m_refreshtoken = json['refresh_token'];

            var expSecs = parseInt(''+json['expires_in']) - 120; // This will make us refresh 2 mins before it expires.
            var expiry = new Date(Date.now() + (1000 * expSecs));
            this.m_expires = expiry;
        } catch(e) {
            console.log("Updating 'refresh' token failed: "+e);
        }

        // Reset the 'refresh' timer:
        this.updateRefresh();
    },

    refresh: function()
    {
        // We really shouldn't NEED to do this while we're connected, but it will ensure that we can reconnect next time before
        // it expires.

        if( 'https://twitchoverlay.invalid/' == this.m_authurl )
        {
            // Self-hosted:
            const url = 'https://id.twitch.tv/oauth2/token';
            const params = 'client_id='+this.m_clientid+'&client_secret='+this.m_clientsecret+'&refresh_token='+this.m_refreshtoken+'&grant_type=refresh_token';

            let self = this;
            console.log("Requesting: "+url+" => "+params);
            this.httpPostRequester(url, function(pkt) {
                self.handleRefresh();
            }, [], params);
        }
        else
        {
            // Remote hosted:
            const url = this.m_authurl + '?a=refresh&refresh=' + encodeURIComponent(this.m_refreshtoken);

            let self = this;
            console.log("Requesting: "+url);
            this.httpRequester(url, function(pkt) {
                self.handleRefresh();
            });
        }
    },

    create: function(chatModel)
    {
        var self = this;
        this.m_chatModel = chatModel;

        this.m_chatSocket = Qt.createQmlObject('import QtWebSockets 1.1; WebSocket { id: socket }', chatModel, 'm_chatSocket');
        this.m_chatSocket.statusChanged.connect( function(status) {
            console.log("WebSocket status: "+status);
            if( status === 1 )
                self.socketConnected();
            else if( status === 3 )
                self.socketDisconnected();
        });
        this.m_chatSocket.textMessageReceived.connect( function(msg) {
            self.socketRead(msg);
        });
        this.m_chatSocket.url = 'ws://irc-ws.chat.twitch.tv:80';

        this.m_reconnectTimer = Qt.createQmlObject('import QtQuick 2.0; Timer { id: timer }', chatModel, 'm_reconnectTimer');
        this.m_reconnectTimer.interval = 10000;
        this.m_reconnectTimer.repeat = false;
        this.m_reconnectTimer.triggered.connect( function() { self.open() } );
    },

    write: function(msg)
    {
        this.m_chatSocket.sendTextMessage(msg);
    },

    open: function()
    {
        this.m_chatSocket.active = false;
        this.m_chatSocket.active = true;
        console.log("IRC: Connecting...");
    },

    close: function()
    {
        console.log("IRC: Disconnecting.");
        this.m_chatSocket.active = false;
    },

    socketConnected: function()
    {
        console.log("IRC: Connected.");
        this.m_reconnectTimer.stop();
        this.m_tryingToLogin = true;
        this.write("USER "+this.m_username+" "+this.m_username+" "+this.m_username+" "+this.m_username+"\n");
        this.write("PASS oauth:"+this.m_authkey+"\n");
        this.write("NICK "+this.m_username+"\n");
    },

    authFailed: function()
    {
        console.log(qsTr("Couldn't authenticate! Try re-linking your Twitch account in Configuration."));
        this.m_tryingToLogin = false;
        this.close();
        if( this.m_reconnectTimer )
            this.m_reconnectTimer.stop();
    },

    socketRead: function(message)
    {
        let self = this;
        let lines = message.split("\n");
        for( let x=0; x < lines.length; x++ )
        {
            let line = lines[x];
            line = line.replace('\r', '');
            if( line.length == 0 )
                continue;

            console.log("IRC: "+line);

            let parts = line.split(' ');
            if( parts[0] === 'PING' )
            {
                console.log("PING received ("+line+"), sending PONG...");
                this.write("PONG "+parts[1]+"\n");
            }
            else if( parts[1] === 'NOTICE' && parts[3] === ':Login' && parts[4] === 'authentication' && parts[5] === 'failed')
            {
                console.log("Failed to authenticate. Token expired?");
                this.authFailed();
            }
            else if( parts[1] === '376' )
            {
                this.m_tryingToLogin = false;

                console.log("Enabling Twitch tags....");
                this.write("CAP REQ :twitch.tv/tags\n");

                console.log("Joining channel: #"+this.m_channel);
                this.write("JOIN #"+this.m_channel+"\n");
            }
            else if( parts[1] === '353' )
            {
                console.log("NAMES line...");
            }
            else if( parts[1] === 'PRIVMSG' )
            {
                let nickparts = parts[0].split('!');
                let text = line.substr( parts[0].length + parts[1].length + parts[2].length + 4 );
                let username = nickparts[0].substr(1);
                this.fetchAvatar( 0, username );
                this.chatSingleMessage( username, text );
            }
            else if( parts[0].substr(0,1) === '@' && parts[2] === 'PRIVMSG' )
            {
                // Twitch-tagged message.
                const tagpairs = parts[0].substr(1).split(';');

                // Create a hash:
                let tags = {};
                for( let y=0; y < tagpairs.length; y++ )
                {
                    const tagset = tagpairs[y].split('=');
                    const k = tagset[0];
                    const v = tagset[1];
                    if( k === 'emotes' && v.length > 0 )
                    {
                        var emotereps = [];

                        // Further parse these out:
                        var emotes = v.split('/');
                        for( var z=0; z < emotes.length; z++ )
                        {
                            var eline = emotes[z];
                            var idtoreps = eline.split(':');
                            var reps = idtoreps[1].split(',');
                            for( var a=0; a < reps.length; a++ )
                            {
                                var reppair = reps[a];
                                var sf = reppair.split('-');
                                emotereps.push( [ idtoreps[0], sf[0], sf[1] ] );
                            }
                        }
                        emotereps.sort( function(a,b) { return parseInt(a[1]) - parseInt(b[1]); } );
                        tags[k] = emotereps;
                    }
                    else
                        tags[k] = v;
                }

                console.log("TAGS: "+JSON.stringify(tags,null,2));

                let nickparts = parts[1].split('!');
                let text = line.substr( parts[0].length + parts[1].length + parts[2].length + parts[3].length + 5 );
                if( tags['emotes'] )
                {
                    // Parse emotes in:
                    let newtext = '';
                    let offset = 0;
                    for( var z=0; z < tags['emotes'].length; z++ )
                    {
                        let emote = tags['emotes'][z];
                        let id = emote[0];
                        let s = parseInt(emote[1]);
                        let e = parseInt(emote[2]);
                        let piece = text.substr(offset,s-offset).replace(/</g, '&lt;');
                        piece = piece.replace(/>/g, '&gt;');
                        newtext += piece;
                        newtext += '<img height=16 width=16 src="http://static-cdn.jtvnw.net/emoticons/v1/'+id+'/1.0" />';
                        offset = e+1;
                    }
                    if( offset < text.length )
                    {
                        let piece = text.substr(offset).replace('<', '&lt;');
                        piece = piece.replace('>', '&gt;');
                        newtext += piece;
                    }

                    text = newtext;
                }
                else
                {
                    text = text.replace(/</g, '&lt;');
                    text = text.replace(/>/g, '&gt;');
                }

                // Handle /me actions:
                let checkAction = /^\u0001ACTION (.*)\u0001/;
                let res = checkAction.exec(text);
                if( res && res.length > 1 )
                {
                    text = "<i>"+res[1]+"</i>";
                }

                // Let's grab the avatar:
                let username = nickparts[0].substr(1);
                this.fetchAvatar( 0, username );

                // Post the message:
                if( tags['display-name'] && tags['display-name'].length > 0 )
                    this.chatSingleMessage( username, text, tags['display-name'] );
                else
                    this.chatSingleMessage( username, text, username );
            }
        }
    },

    socketDisconnected: function()
    {
        console.log("IRC: Disconnected.");
        try {
            this.m_reconnectTimer.start();
        } catch(e) {
            console.log("IRC: Reconnect timer stopped: "+e);
        }
    },

    addUser: function( username, data )
    {
        this.m_users[username] = data;
    },

    removeUser: function( username )
    {
        if( this.m_users[username] )
            delete this.m_users[username];
    },

    fetchAvatar: function( userid, username, callback )
    {
        let self = this;
        if( !this.m_users[username] )
        {
            // Grab their avatar:
            let headers = [ [ 'Client-ID', this.m_clientid ], [ 'Authorization', 'Bearer '+this.m_authkey ] ];
            let url = 'https://api.twitch.tv/helix/users?login=' + username;

            this.httpRequester(url, function(pkt){
                console.log("Avatar response: "+pkt);
                let json = JSON.parse(pkt);
                let aurl = json['data'][0]['profile_image_url'];
                self.addUser( username, aurl );
                console.log("Avatar URL for '"+username+"' is '"+self.m_users[username]+"'");
                if( callback )
                    callback( username, aurl );

                for( let x=0; x < self.m_avatarHooks.length; x++ )
                {
                    self.m_avatarHooks[x]( username, aurl );
                }
            }, headers);
        }
        else if( callback )
            callback( username, this.m_users[username] );
    },

    chatSingleMessage: function(username, message, styledusername)
    {
        if( message.length === 0 ) return;

        message = message.replace('\r', '');

        let roles = [];
        if( username == this.m_username )
            roles.push('Owner');

        let msg = {
            'username': username,
            'userid': username,
            'styledusername': '<b>'+styledusername+'</b>', // TODO: roles based on IRC rank?
            'roles': roles, // TODO: roles based on IRC rank?
            'timestamp': new Date(),
            'historic': false,
            'message': message,
            'avatarUrl': this.m_users[username] || ''
        }

        console.log("Message: "+JSON.stringify(msg,null,2));
        for( var x=0; x < this.m_chatHooks.length; x++ )
        {
            this.m_chatHooks[x]( msg );
        }
    },

    sendMessage: function(msg) {
        console.log("Sending message: "+msg);
        this.write("PRIVMSG #"+this.m_channel+" :"+msg+"\n");
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
