.pragma library

const homePath = "/home/jotto";
function pathRelativeToHome(path) {
  return homePath + (homePath.endsWith("/") || path.startsWith("/") ? "" : '/') + path;
}

// "~/x" is x in your home directory; any other path stays as it is
function expandHome(path) {
  return path.startsWith("~") ? pathRelativeToHome(path.slice(1)) : path;
}
