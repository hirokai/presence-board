firebase.initializeApp(firebaseConfig);
var database = firebase.database();

const lsKey = "seating_v2.0.0_members_and_places";
const s = localStorage.getItem(lsKey);

var places = undefined;
var app;
var globalCache = null;

if (s) {
  const { members: members0, places: places0 } = JSON.parse(s);
  const places = places0.map((p) => {
    return {
      ...p,
      span: p.span || 1,
      order: p.order == undefined ? 100 : p.order,
    };
  });
  console.log({ members0 });
  const members = members0
    .filter((p) => p)
    .map((p) => {
      return {
        ...p,
        last_updated: p.last_updated || -1,
      };
    });
  console.log("Init with local data", { members, places });
  app = Elm.Presence.init({ flags: { members, places } });
  app.ports.updateBackend.subscribe(updateBackendCallback);
  database.ref("/").once("value", (d) => {
    const obj = d.val();
    console.log("Update from server", obj);
    localStorage.setItem(lsKey, JSON.stringify(obj));
    // const places = obj.places;
    feedDataToView(obj.members);
    feedPlacesToView(obj.places);
  });
} else {
  database.ref("/").once("value", (d) => {
    const obj = d.val();
    console.log("Init with server data", obj);
    globalCache = obj.members;
    localStorage.setItem(lsKey, JSON.stringify(obj));
    const places = obj.places.map((p) => {
      return { ...p, span: p.span || 1 };
    });
    const members = obj.members;
    app = Elm.Presence.init({ flags: { members, places } });
    console.log(app);
    app.ports.updateBackend.subscribe(updateBackendCallback);
  });
}

function updateBackendCallback(data) {
  const { name, place, order } = data.member;
  if (name) {
    const last_updated = new Date().getTime();
    const new_data = { place, order, name, last_updated };
    database.ref("members/" + order).set(new_data);
    if (!data.noLog) {
      database.ref("logs/").push({ place, name, timestamp: last_updated });
    }
  }
}

function feedDataToView(members) {
  _.map(members, (m) => {
    // console.log('updateMember',m);
    app.ports.updateMember.send(m);
  });
}

function feedPlacesToView(places) {
  _.map(places, (p) => {
    app.ports.updatePlace.send({ ...p, span: p.span || 1 });
  });
}

function checkIdle(obj) {
  return;
  _.map(obj, (value, name) => {
    if (new Date().getTime() - value.last_updated >= 1000 * 60 * 60 * 6) {
      const obj2 = {};
      value.place = "不明";
      obj2[name] = value;
      database.ref("members/" + value.name).set(value);
    }
  });
}

window.setInterval(() => {
  checkIdle(globalCache);
}, 10000);

database.ref("members").on("child_changed", (d) => {
  const obj = d.val();
  const obj_local = JSON.parse(localStorage.getItem(lsKey)) || { members: {} };
  obj_local.members[obj.order] = obj;
  localStorage.setItem(lsKey, JSON.stringify(obj_local));
  feedDataToView(obj_local.members);
});

database.ref("members").on("child_added", (d) => {
  const obj = d.val();
  const obj_local = JSON.parse(localStorage.getItem(lsKey)) || { members: {} };
  obj_local.members[obj.order] = obj;
  localStorage.setItem(lsKey, JSON.stringify(obj_local));
  feedDataToView(obj_local.members);
});

database.ref("members").on("child_removed", (d) => {
  const obj = d.val();
  console.log("child_removed", obj);
  const obj_local = JSON.parse(localStorage.getItem(lsKey)) || { members: {} };
  obj_local.members[obj.order] = obj;
  localStorage.setItem(lsKey, JSON.stringify(obj_local));
  feedDataToView(obj_local.members);
});
