.pragma library

const homePath = "/home/jotto";
function pathRelativeToHome(path) {
  return homePath + (homePath.endsWith("/") || path.startsWith("/") ? "" : '/') + path;
}

function expandHome(path) {
  return path.startsWith("~") ? pathRelativeToHome(path.slice(1)) : path;
}

// escaped per segment so names with #, ? or % still load
function fileUrl(path) {
  return path === "" ? "" : "file://" + path.split("/").map(encodeURIComponent).join("/");
}
