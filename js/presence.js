firebase.initializeApp(firebaseConfig);
var database = firebase.database();

const lsKey = 'seating_v2.0.0_members_and_places';
const s = localStorage.getItem(lsKey);

var places = undefined;
var app;
var globalCache = null;

if(s){
	const {members,places} = JSON.parse(s);
	console.log('Init with local data',members, places);
	app = Elm.Main.init({flags: {members, places}});
	database.ref('/').once('value', (d) => {
		const obj = d.val();
		console.log('Update from server',obj);
		localStorage.setItem(lsKey, JSON.stringify(obj));
		// const places = obj.places;
		feedDataToView(obj.members);
	});	
}else{
	database.ref('/').once('value', (d) => {
		const obj = d.val();
		console.log('Init with server data',obj);
		globalCache = obj.members;
		localStorage.setItem(lsKey, JSON.stringify(obj));
		const places = obj.places;
		const members = obj.places;
		app = Elm.Main.init({flags: {members,places}});	
	});
}

app.ports.updateBackend.subscribe(function (data) {
	const { name, place, order } = data;
	if(name){
		const last_updated = new Date().getTime();
		const new_data = { place, order, name, last_updated };
		database.ref('members/' + order).set(new_data);
	}
});

function feedDataToView(members) {
	_.map(members, (m) => {
		// console.log('updateMember',m);
		app.ports.updateMember.send(m);
	})
}


function checkIdle(obj) {
	return;
	_.map(obj,(value,name) => {
		if(new Date().getTime() - value.last_updated >= 1000*60*60*6){
			const obj2 = {};
			value.place = '不明';
			obj2[name] = value;
			database.ref('members/' + value.name).set(value);
		}
	});
}

window.setInterval(() => {
	checkIdle(globalCache);
},10000);

database.ref('members').on('child_changed',(d) => {
	const obj = d.val();
	const obj_local = JSON.parse(localStorage.getItem(lsKey));
	obj_local.members[obj.order] = obj;
	localStorage.setItem(lsKey, JSON.stringify(obj_local));
	feedDataToView(obj_local.members);
});

database.ref('members').on('child_added',(d) => {
	const obj = d.val();
	const obj_local = JSON.parse(localStorage.getItem(lsKey));
	obj_local.members[obj.order] = obj;
	localStorage.setItem(lsKey, JSON.stringify(obj_local));
	feedDataToView(obj_local.members);
});

database.ref('members').on('child_removed',(d) => {
	const obj = d.val();
	console.log('child_removed',obj);
	const obj_local = JSON.parse(localStorage.getItem(lsKey));
	obj_local.members[obj.order] = obj;
	localStorage.setItem(lsKey, JSON.stringify(obj_local));
	feedDataToView(obj_local.members);
});