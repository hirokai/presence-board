firebase.initializeApp(firebaseConfig);
var database = firebase.database();

database.ref("/").once("value", (d) => {
  const obj = d.val();
  const places = obj.places
    .filter((p) => p)
    .map((p) => {
      return {
        ...p,
        span: p.span || 1,
        order: p.order == undefined ? 100 : p.order,
      };
    });
  const members_all = obj.members
    .filter((p) => p)
    .map((p) => {
      return {
        ...p,
        last_updated: p.last_updated || -1,
      };
    });

  const members = _.orderBy(members_all, "order");
  // const logs = _.map(_.orderBy(obj.logs, "timestamp", "desc"), (l) => {
  //   return {
  //     timestamp: l.timestamp,
  //     time: new Date(l.timestamp).toString(),
  //     name: l.name,
  //     place: l.place,
  //   };
  // });
  const flags = { members, places, logs: [] };
  console.log(flags);
  const app = Elm.Admin.init({ flags });

  app.ports.sendChangeMembers.subscribe((d) => {
    const names = _.uniq(_.filter(d.split("\n"), (s) => s.trim() != ""));
    database.ref("members").remove();
    _.map(names, (name, order) => {
      const m = _.find(members, (m) => {
        return m.name == name;
      });
      const place = m ? m.place : "不明";
      console.log(m, place);
      database.ref("members/" + order).set({
        name,
        order,
        place,
      });
    });
    alert("メンバー一覧を更新しました。");
  });

  app.ports.sendChangePlaces.subscribe((d) => {
    const places0 = _.map(
      _.filter(d.split("\n"), (s) => s.trim() != ""),
      (s) => {
        return s.split(",");
      }
    );
    if (
      !_.every(
        places0.map((p) => {
          const span = parseInt(p[2]);
          return p.length == 3 && !isNaN(span) && span >= 1 && span <= 4;
        })
      )
    ) {
      alert("フォーマットが正しくありません");
      return;
    }
    const places = places0.map((p) => {
      return { name: p[0], color: p[1], span: parseInt(p[2]) };
    });
    database.ref("places").remove();
    _.map(places, (p, order) => {
      const obj = {
        name: p.name,
        order,
        color: p.color,
      };
      if (p.span != 1) {
        obj.span = p.span;
      }
      database.ref("places/" + order).set(obj);
    });
    alert("場所一覧を更新しました。");
  });

  app.ports.downloadLogs.subscribe(() => {
    database.ref("logs").once("value", (d) => {
      const logs = d.val();
      if (!logs) {
        alert("ログがありません。");
        return;
      }
      var dataStr =
        "data:text/csv;charset=utf-8," +
        encodeURIComponent(
          Papa.unparse(
            _.orderBy(Object.values(logs), "timestamp").map((l) => {
              return [
                l.timestamp,
                new Date(l.timestamp).toString(),
                l.name,
                l.place,
              ];
            })
          )
        );
      var dlAnchorElem = document.getElementById("downloadAnchorElem");
      dlAnchorElem.setAttribute("href", dataStr);
      dlAnchorElem.setAttribute("download", "presence_log.csv");
      dlAnchorElem.click();
    });
  });

  app.ports.clearLogs.subscribe(() => {
    if (
      confirm(
        "ログを削除して良いですか？ 取り消せません。（削除前にログがCSVとしてダウンロードされます。）"
      )
    ) {
      database.ref("logs").once("value", (d) => {
        const logs = d.val();
        if (!logs) {
          alert("ログがありません。");
          return;
        }
        var dataStr =
          "data:text/csv;charset=utf-8," +
          encodeURIComponent(
            Papa.unparse(
              _.orderBy(Object.values(logs), "timestamp").map((l) => {
                return [
                  l.timestamp,
                  new Date(l.timestamp).toString(),
                  l.name,
                  l.place,
                ];
              })
            )
          );
        var dlAnchorElem = document.getElementById("downloadAnchorElem");
        dlAnchorElem.setAttribute("href", dataStr);
        dlAnchorElem.setAttribute("download", "presence_log.csv");
        dlAnchorElem.click();
        database.ref("logs").remove();
        alert("ログが削除されました。");
      });
    }
  });

  database.ref("logs").on("child_added", (d) => {
    const l = d.val();
    app.ports.addLog.send({
      timestamp: l.timestamp,
      time: new Date(l.timestamp).toString(),
      name: l.name,
      place: l.place,
    });
  });
});
