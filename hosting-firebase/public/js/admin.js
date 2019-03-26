firebase.initializeApp(firebaseConfig);
var database = firebase.database();

database.ref('members').once('value', (d) => {
	const members = _.orderBy(_.map(d.val(),(value,key) => value), 'order');
	console.log('members', members);
	const app = Elm.Main.init({ flags: members });

	app.ports.sendChange.subscribe((d) => {
		const names = _.filter(d.split('\n'),(s) => s.trim() != '');
		database.ref('members').remove();
		_.map(names,(name,order) => {
			const m = _.find(members, (m) => {return m.name == name;});
			const place = m ? m.place : '不明';
			console.log(m,place);
			database.ref('members/' + order).set({
				name, order,
				place});	
		});
		console.log(names);
	})
});

