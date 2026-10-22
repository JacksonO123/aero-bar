.pragma library

const homePath = "/home/jotto";
function pathRelativeToHome(path) {
  return homePath + (homePath.endsWith("/") || path.startsWith("/") ? "" : '/') + path;
}
