const ctx = $canvas.getContext('2d');

const getCanvasWidth = () => $canvas.width;
const getCanvasHeight = () => $canvas.height;

const rect = (x, y, width, height) => ctx.rect(x, y, width, height);
const clearRect = (x, y, width, height) => ctx.clearRect(x, y, width, height);
const fillRect = (x, y, width, height) => ctx.fillRect(x, y, width, height);
const strokeRect = (x, y, width, height) => ctx.strokeRect(x, y, width, height);
const arc = (x, y, radius, startAngle, endAngle) => ctx.arc(x, y, radius, startAngle, endAngle);

const fillColor = (r, g, b, a) => ctx.fillStyle = `rgba(${r}, ${g}, ${b}, ${a / 255.0})`;
const fillStyle = (style, len) => ctx.fillStyle = readString(style, len); // 'red|#ff0000|#f00|rgb(255,0,0)|rgba(255,0,0,1)';
const fill = () => ctx.fill();

const strokeWidth = (width) => ctx.lineWidth = width;
const strokeStyle = (style, len) => ctx.strokeStyle = readString(style, len); // 'red|#ff0000|#f00|rgb(255,0,0)|rgba(255,0,0,1)';
const stroke = () => ctx.stroke();

const beginPath = () => ctx.beginPath();
const moveTo = (x, y) => ctx.moveTo(x, y)
const lineTo = (x, y) => ctx.lineTo(x, y);
const quadraticCurveTo = (cx, cy, x, y) => ctx.quadraticCurveTo(cx, cy, x, y);
const bezierCurveTo = (cx1, cy1, cx2, cy2, x, y) => ctx.bezierCurveTo(cx1, cy1, cx2, cy2, x, y);
const closePath = () => ctx.closePath();

const createLinearGradient = (x1, y1, x2, y2) => ctx.createLinearGradient(x1, y1, x2, y2);
const createRadialGradient = (x1, y1, radius1, x2, y2, radius2) => ctx.createLinearGradient(x1, y1, radius1, x2, y2, radius2);
const addColorStop = (grd, index, color, len) => grd.addColorStop(index, readString(color, len));

const lineWidth = (width) => ctx.lineWidth = width;
const LineJoins = ['miter', 'round', 'bevel'];
const lineJoin = (index) => ctx.lineJoin = LineJoins[index];
const LineCaps = ['butt', 'round', 'square'];
const lineCap = (index) => ctx.lineCap = LineCaps[index];

const shadowColor = (r, g, b, a) => ctx.shadowColor = `rgba(${r}, ${g}, ${b}, ${a / 255.0})`;
const shadowStyle = (style, len) => ctx.shadowColor = readString(style, len);
const shadowBlur = (val) => ctx.shadowBlur = val;
const shadowOffsetX = (val) => ctx.shadowOffsetX = val;
const shadowOffsetY = (val) => ctx.shadowOffsetY = val;

const globalCompositeOperation = (op) => ctx.globalCompositeOperation = op;
const globalAlpha = (val) => ctx.globalAlpha = val; // between 0 and 1

var font_family = "sans-serif";
const fontFamily = (name, len) => font_family = readString(name, len);
const fontSize = (size) => ctx.font = size + "px " + font_family;
//const font = (style, len) => ctx.font = readString(style, len); // 'bold 40px Arial';
const fillText = (text, len, x, y) => ctx.fillText(readString(text, len), x, y);
const strokeText = (text, len, x, y) => ctx.strokeText(readString(text, len), x, y);
const TextAligns = ['left', 'center', 'right'];
const textAlign = (index) => ctx.textAlign = TextAligns[index];
const TextBaselines = ['top', 'hanging', 'middle', 'alphabetic', 'ideographic', 'bottom'];
const textBaseline = (index) => ctx.textBaseline = TextBaselines[index];
const measureText = (text, len) => ctx.measureText(readString(text, len)).width;

const translate = (x, y) => ctx.translate(x, y);
const scale = (x, y) => ctx.scale(x, y);
const rotate = (radians) => ctx.rotate(radians);
const transform = (a, b, c, d, e, f) => ctx.transform(a, b, c, d, e, f);
const setTransform = (a, b, c, d, e, f) => ctx.setTransform(a, b, c, d, e, f);

const save = () => ctx.save();
const restore = () => ctx.restore();

const clip = () => ctx.clip();

const getImageData = (x, y, width, height) => ctx.getImageData(x, y, width, height);
const putImageData = (imageData, x, y) => ctx.putImageData(imageData, x, y);

const createPattern = (imageObj, style) => ctx.createPattern(imageObj, readString(style, len));

const drawImage = (path, len, x, y) => {
    var imageObj = new Image();
    imageObj.onload = function () {
        ctx.drawImage(imageObj, x, y);
    };
    imageObj.src = readString(path, len);
}

const drawImageRect = (path, len, x, y, width, height) => {
    var imageObj = new Image();
    imageObj.onload = function () {
        ctx.drawImage(imageObj, x, y, width, height);
    };
    imageObj.src = readString(path, len);
}

const toDataURL = () => canvas.toDataURL();

var canvas = {
    getCanvasWidth,
    getCanvasHeight,
    rect,
    clearRect,
    fillRect,
    strokeRect,
    arc,
    fillColor,
    fillStyle,
    fill,
    strokeWidth,
    strokeStyle,
    stroke,
    beginPath,
    moveTo,
    lineTo,
    arc,
    quadraticCurveTo,
    bezierCurveTo,
    closePath,
    createLinearGradient,
    createRadialGradient,
    addColorStop,
    lineWidth,
    lineJoin,
    lineCap,
    shadowColor,
    shadowStyle,
    shadowBlur,
    shadowOffsetX,
    shadowOffsetY,
    globalCompositeOperation,
    globalAlpha,
    fontFamily,
    fontSize,
    fillText,
    strokeText,
    textAlign,
    textBaseline,
    measureText,
    translate,
    scale,
    rotate,
    scale,
    transform,
    setTransform,
    save,
    restore,
    clip,
    getImageData,
    putImageData,
    createPattern,
    drawImage,
    drawImageRect,
    toDataURL
};