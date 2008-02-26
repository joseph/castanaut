var Castanaut = Castanaut || {};

Castanaut.Coords = Castanaut.Coords || {
  documentPos: function (obj) {
    origObj = obj;
    var curleft = curtop = 0;
    if (obj.offsetParent) {
      do {
        curleft += obj.offsetLeft;
        curtop += obj.offsetTop;
      } while (obj = obj.offsetParent);
    }
    return [curleft,curtop,origObj.offsetWidth,origObj.offsetHeight];
  },

  windowPos: function (obj) {
    var pos = Castanaut.Coords.documentPos(obj);
    pos[0] -= window.scrollX;
    pos[1] -= window.scrollY;
    if (pos[0] > window.innerWidth || pos[0] < 0) {
      pos[0] = -1;
    }
    if (pos[1] > window.innerHeight || pos[1] < 0) {
      pos[1] = -1;
    }
    return pos;
  },

  forElement: function (selector, index) {
    var obj = Castanaut.DomQuery.select(selector)[index];
    var pos = Castanaut.Coords.windowPos(obj);
    if (pos[0] < 0 || pos[1] < 0) {
      obj.scrollIntoView();
      pos = Castanaut.Coords.windowPos(obj);
      if (pos[0] < 0 || pos[1] < 0) {
        return pos.join(' ');
      }
    }

    pos[0] += window.screenX + (window.outerWidth - window.innerWidth);

    pos[1] += window.screenY + (window.outerHeight - window.innerHeight);
    if (window.statusbar.visible) {
      pos[1] -= 14;
    }
    return pos.join(' ');
  }
}
