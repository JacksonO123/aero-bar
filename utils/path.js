.pragma library

const homePath = "/home/jotto";
function pathRelativeToHome(path) {
  return homePath + (homePath.endsWith("/") || path.startsWith("/") ? "" : '/') + path;
}

// "~/x" is x in your home directory; any other path stays as it is
function expandHome(path) {
  return path.startsWith("~") ? pathRelativeToHome(path.slice(1)) : path;
}

// the file:// URL of a local path, escaped so any file name works (#, ? and % included); "" stays ""
function fileUrl(path) {
  return path === "" ? "" : "file://" + path.split("/").map(encodeURIComponent).join("/");
}
