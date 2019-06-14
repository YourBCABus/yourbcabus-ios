let meta = document.createElement("meta");
meta.setAttribute("name", "viewport");
meta.setAttribute("content", "width=device-width, initial-scale=1.0, user-scalable=no");
document.head.appendChild(meta);

document.body.style.fontFamily = "system-ui, -apple-system, sans-serif";
document.body.style.fontSize = "18px";
document.body.style.margin = "0.5em";

document.querySelector(":root").style.colorScheme = "light dark";
