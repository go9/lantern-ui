// node_modules/@floating-ui/utils/dist/floating-ui.utils.mjs
var min = Math.min;
var max = Math.max;
var round = Math.round;
var floor = Math.floor;
var createCoords = (v) => ({
  x: v,
  y: v
});
var oppositeSideMap = {
  left: "right",
  right: "left",
  bottom: "top",
  top: "bottom"
};
function clamp(start, value, end) {
  return max(start, min(value, end));
}
function evaluate(value, param) {
  return typeof value === "function" ? value(param) : value;
}
function getSide(placement) {
  return placement.split("-")[0];
}
function getAlignment(placement) {
  return placement.split("-")[1];
}
function getOppositeAxis(axis) {
  return axis === "x" ? "y" : "x";
}
function getAxisLength(axis) {
  return axis === "y" ? "height" : "width";
}
function getSideAxis(placement) {
  const firstChar = placement[0];
  return firstChar === "t" || firstChar === "b" ? "y" : "x";
}
function getAlignmentAxis(placement) {
  return getOppositeAxis(getSideAxis(placement));
}
function getAlignmentSides(placement, rects, rtl) {
  if (rtl === void 0) {
    rtl = false;
  }
  const alignment = getAlignment(placement);
  const alignmentAxis = getAlignmentAxis(placement);
  const length = getAxisLength(alignmentAxis);
  let mainAlignmentSide = alignmentAxis === "x" ? alignment === (rtl ? "end" : "start") ? "right" : "left" : alignment === "start" ? "bottom" : "top";
  if (rects.reference[length] > rects.floating[length]) {
    mainAlignmentSide = getOppositePlacement(mainAlignmentSide);
  }
  return [mainAlignmentSide, getOppositePlacement(mainAlignmentSide)];
}
function getExpandedPlacements(placement) {
  const oppositePlacement = getOppositePlacement(placement);
  return [getOppositeAlignmentPlacement(placement), oppositePlacement, getOppositeAlignmentPlacement(oppositePlacement)];
}
function getOppositeAlignmentPlacement(placement) {
  return placement.includes("start") ? placement.replace("start", "end") : placement.replace("end", "start");
}
var lrPlacement = ["left", "right"];
var rlPlacement = ["right", "left"];
var tbPlacement = ["top", "bottom"];
var btPlacement = ["bottom", "top"];
function getSideList(side, isStart, rtl) {
  switch (side) {
    case "top":
    case "bottom":
      if (rtl) return isStart ? rlPlacement : lrPlacement;
      return isStart ? lrPlacement : rlPlacement;
    case "left":
    case "right":
      return isStart ? tbPlacement : btPlacement;
    default:
      return [];
  }
}
function getOppositeAxisPlacements(placement, flipAlignment, direction, rtl) {
  const alignment = getAlignment(placement);
  let list = getSideList(getSide(placement), direction === "start", rtl);
  if (alignment) {
    list = list.map((side) => side + "-" + alignment);
    if (flipAlignment) {
      list = list.concat(list.map(getOppositeAlignmentPlacement));
    }
  }
  return list;
}
function getOppositePlacement(placement) {
  const side = getSide(placement);
  return oppositeSideMap[side] + placement.slice(side.length);
}
function expandPaddingObject(padding) {
  var _padding$top, _padding$right, _padding$bottom, _padding$left;
  return {
    top: (_padding$top = padding.top) != null ? _padding$top : 0,
    right: (_padding$right = padding.right) != null ? _padding$right : 0,
    bottom: (_padding$bottom = padding.bottom) != null ? _padding$bottom : 0,
    left: (_padding$left = padding.left) != null ? _padding$left : 0
  };
}
function getPaddingObject(padding) {
  return typeof padding !== "number" ? expandPaddingObject(padding) : {
    top: padding,
    right: padding,
    bottom: padding,
    left: padding
  };
}
function rectToClientRect(rect) {
  const {
    x,
    y,
    width,
    height
  } = rect;
  return {
    width,
    height,
    top: y,
    left: x,
    right: x + width,
    bottom: y + height,
    x,
    y
  };
}

// node_modules/@floating-ui/core/dist/floating-ui.core.mjs
function computeCoordsFromPlacement(_ref, placement, rtl) {
  let {
    reference,
    floating
  } = _ref;
  const sideAxis = getSideAxis(placement);
  const alignmentAxis = getAlignmentAxis(placement);
  const alignLength = getAxisLength(alignmentAxis);
  const side = getSide(placement);
  const isVertical = sideAxis === "y";
  const commonX = reference.x + reference.width / 2 - floating.width / 2;
  const commonY = reference.y + reference.height / 2 - floating.height / 2;
  const commonAlign = reference[alignLength] / 2 - floating[alignLength] / 2;
  let coords;
  switch (side) {
    case "top":
      coords = {
        x: commonX,
        y: reference.y - floating.height
      };
      break;
    case "bottom":
      coords = {
        x: commonX,
        y: reference.y + reference.height
      };
      break;
    case "right":
      coords = {
        x: reference.x + reference.width,
        y: commonY
      };
      break;
    case "left":
      coords = {
        x: reference.x - floating.width,
        y: commonY
      };
      break;
    default:
      coords = {
        x: reference.x,
        y: reference.y
      };
  }
  const alignment = getAlignment(placement);
  if (alignment) {
    coords[alignmentAxis] += commonAlign * (alignment === "end" ? 1 : -1) * (rtl && isVertical ? -1 : 1);
  }
  return coords;
}
async function detectOverflow(state, options) {
  var _await$platform$isEle;
  if (options === void 0) {
    options = {};
  }
  const {
    x,
    y,
    platform: platform2,
    rects,
    elements,
    strategy
  } = state;
  const {
    boundary = "clippingAncestors",
    rootBoundary = "viewport",
    elementContext = "floating",
    altBoundary = false,
    padding = 0
  } = evaluate(options, state);
  const paddingObject = getPaddingObject(padding);
  const altContext = elementContext === "floating" ? "reference" : "floating";
  const element = elements[altBoundary ? altContext : elementContext];
  const clippingClientRect = rectToClientRect(await platform2.getClippingRect({
    element: ((_await$platform$isEle = await (platform2.isElement == null ? void 0 : platform2.isElement(element))) != null ? _await$platform$isEle : true) ? element : element.contextElement || await (platform2.getDocumentElement == null ? void 0 : platform2.getDocumentElement(elements.floating)),
    boundary,
    rootBoundary,
    strategy
  }));
  const rect = elementContext === "floating" ? {
    x,
    y,
    width: rects.floating.width,
    height: rects.floating.height
  } : rects.reference;
  const offsetParent = await (platform2.getOffsetParent == null ? void 0 : platform2.getOffsetParent(elements.floating));
  const offsetScale = await (platform2.isElement == null ? void 0 : platform2.isElement(offsetParent)) && await (platform2.getScale == null ? void 0 : platform2.getScale(offsetParent)) || {
    x: 1,
    y: 1
  };
  const elementClientRect = rectToClientRect(platform2.convertOffsetParentRelativeRectToViewportRelativeRect ? await platform2.convertOffsetParentRelativeRectToViewportRelativeRect({
    elements,
    rect,
    offsetParent,
    strategy
  }) : rect);
  return {
    top: (clippingClientRect.top - elementClientRect.top + paddingObject.top) / offsetScale.y,
    bottom: (elementClientRect.bottom - clippingClientRect.bottom + paddingObject.bottom) / offsetScale.y,
    left: (clippingClientRect.left - elementClientRect.left + paddingObject.left) / offsetScale.x,
    right: (elementClientRect.right - clippingClientRect.right + paddingObject.right) / offsetScale.x
  };
}
var MAX_RESET_COUNT = 50;
var computePosition = async (reference, floating, config) => {
  const {
    placement = "bottom",
    strategy = "absolute",
    middleware = [],
    platform: platform2
  } = config;
  const platformWithDetectOverflow = platform2.detectOverflow ? platform2 : {
    ...platform2,
    detectOverflow
  };
  const rtl = await (platform2.isRTL == null ? void 0 : platform2.isRTL(floating));
  let rects = await platform2.getElementRects({
    reference,
    floating,
    strategy
  });
  let {
    x,
    y
  } = computeCoordsFromPlacement(rects, placement, rtl);
  let statefulPlacement = placement;
  let resetCount = 0;
  const middlewareData = {};
  for (let i = 0; i < middleware.length; i++) {
    const currentMiddleware = middleware[i];
    if (!currentMiddleware) {
      continue;
    }
    const {
      name,
      fn
    } = currentMiddleware;
    const {
      x: nextX,
      y: nextY,
      data,
      reset
    } = await fn({
      x,
      y,
      initialPlacement: placement,
      placement: statefulPlacement,
      strategy,
      middlewareData,
      rects,
      platform: platformWithDetectOverflow,
      elements: {
        reference,
        floating
      }
    });
    x = nextX != null ? nextX : x;
    y = nextY != null ? nextY : y;
    middlewareData[name] = {
      ...middlewareData[name],
      ...data
    };
    if (reset && resetCount < MAX_RESET_COUNT) {
      resetCount++;
      if (typeof reset === "object") {
        if (reset.placement) {
          statefulPlacement = reset.placement;
        }
        if (reset.rects) {
          rects = reset.rects === true ? await platform2.getElementRects({
            reference,
            floating,
            strategy
          }) : reset.rects;
        }
        ({
          x,
          y
        } = computeCoordsFromPlacement(rects, statefulPlacement, rtl));
      }
      i = -1;
    }
  }
  return {
    x,
    y,
    placement: statefulPlacement,
    strategy,
    middlewareData
  };
};
var flip = function(options) {
  if (options === void 0) {
    options = {};
  }
  return {
    name: "flip",
    options,
    async fn(state) {
      var _middlewareData$arrow, _middlewareData$flip;
      const {
        placement,
        middlewareData,
        rects,
        initialPlacement,
        platform: platform2,
        elements
      } = state;
      const {
        mainAxis: checkMainAxis = true,
        crossAxis: checkCrossAxis = true,
        fallbackPlacements: specifiedFallbackPlacements,
        fallbackStrategy = "bestFit",
        fallbackAxisSideDirection = "none",
        flipAlignment = true,
        ...detectOverflowOptions
      } = evaluate(options, state);
      if ((_middlewareData$arrow = middlewareData.arrow) != null && _middlewareData$arrow.alignmentOffset) {
        return {};
      }
      const side = getSide(placement);
      const initialSideAxis = getSideAxis(initialPlacement);
      const isBasePlacement = getSide(initialPlacement) === initialPlacement;
      const rtl = await (platform2.isRTL == null ? void 0 : platform2.isRTL(elements.floating));
      const fallbackPlacements = specifiedFallbackPlacements || (isBasePlacement || !flipAlignment ? [getOppositePlacement(initialPlacement)] : getExpandedPlacements(initialPlacement));
      const hasFallbackAxisSideDirection = fallbackAxisSideDirection !== "none";
      if (!specifiedFallbackPlacements && hasFallbackAxisSideDirection) {
        fallbackPlacements.push(...getOppositeAxisPlacements(initialPlacement, flipAlignment, fallbackAxisSideDirection, rtl));
      }
      const placements2 = [initialPlacement, ...fallbackPlacements];
      const overflow = await platform2.detectOverflow(state, detectOverflowOptions);
      const overflows = [];
      let overflowsData = ((_middlewareData$flip = middlewareData.flip) == null ? void 0 : _middlewareData$flip.overflows) || [];
      if (checkMainAxis) {
        overflows.push(overflow[side]);
      }
      if (checkCrossAxis) {
        const sides2 = getAlignmentSides(placement, rects, rtl);
        overflows.push(overflow[sides2[0]], overflow[sides2[1]]);
      }
      overflowsData = [...overflowsData, {
        placement,
        overflows
      }];
      if (!overflows.every((side2) => side2 <= 0)) {
        var _middlewareData$flip2, _overflowsData$filter;
        const nextIndex = (((_middlewareData$flip2 = middlewareData.flip) == null ? void 0 : _middlewareData$flip2.index) || 0) + 1;
        const nextPlacement = placements2[nextIndex];
        if (nextPlacement) {
          const ignoreCrossAxisOverflow = checkCrossAxis === "alignment" ? initialSideAxis !== getSideAxis(nextPlacement) : false;
          if (!ignoreCrossAxisOverflow || // We leave the current main axis only if every placement on that axis
          // overflows the main axis.
          overflowsData.every((d) => getSideAxis(d.placement) === initialSideAxis ? d.overflows[0] > 0 : true)) {
            return {
              data: {
                index: nextIndex,
                overflows: overflowsData
              },
              reset: {
                placement: nextPlacement
              }
            };
          }
        }
        let resetPlacement = (_overflowsData$filter = overflowsData.filter((d) => d.overflows[0] <= 0).sort((a, b) => a.overflows[1] - b.overflows[1])[0]) == null ? void 0 : _overflowsData$filter.placement;
        if (!resetPlacement) {
          switch (fallbackStrategy) {
            case "bestFit": {
              var _overflowsData$filter2;
              const placement2 = (_overflowsData$filter2 = overflowsData.filter((d) => {
                if (hasFallbackAxisSideDirection) {
                  const currentSideAxis = getSideAxis(d.placement);
                  return currentSideAxis === initialSideAxis || // Create a bias to the `y` side axis due to horizontal
                  // reading directions favoring greater width.
                  currentSideAxis === "y";
                }
                return true;
              }).map((d) => [d.placement, d.overflows.filter((overflow2) => overflow2 > 0).reduce((acc, overflow2) => acc + overflow2, 0)]).sort((a, b) => a[1] - b[1])[0]) == null ? void 0 : _overflowsData$filter2[0];
              if (placement2) {
                resetPlacement = placement2;
              }
              break;
            }
            case "initialPlacement":
              resetPlacement = initialPlacement;
              break;
          }
        }
        if (placement !== resetPlacement) {
          return {
            reset: {
              placement: resetPlacement
            }
          };
        }
      }
      return {};
    }
  };
};
var originSides = /* @__PURE__ */ new Set(["left", "top"]);
async function convertValueToCoords(state, options) {
  const {
    placement,
    platform: platform2,
    elements
  } = state;
  const rtl = await (platform2.isRTL == null ? void 0 : platform2.isRTL(elements.floating));
  const side = getSide(placement);
  const alignment = getAlignment(placement);
  const isVertical = getSideAxis(placement) === "y";
  const mainAxisMulti = originSides.has(side) ? -1 : 1;
  const crossAxisMulti = rtl && isVertical ? -1 : 1;
  const rawValue = evaluate(options, state);
  let {
    mainAxis,
    crossAxis,
    alignmentAxis
  } = typeof rawValue === "number" ? {
    mainAxis: rawValue,
    crossAxis: 0,
    alignmentAxis: null
  } : {
    mainAxis: rawValue.mainAxis || 0,
    crossAxis: rawValue.crossAxis || 0,
    alignmentAxis: rawValue.alignmentAxis
  };
  if (alignment && typeof alignmentAxis === "number") {
    crossAxis = alignment === "end" ? alignmentAxis * -1 : alignmentAxis;
  }
  return isVertical ? {
    x: crossAxis * crossAxisMulti,
    y: mainAxis * mainAxisMulti
  } : {
    x: mainAxis * mainAxisMulti,
    y: crossAxis * crossAxisMulti
  };
}
var offset = function(options) {
  if (options === void 0) {
    options = 0;
  }
  return {
    name: "offset",
    options,
    async fn(state) {
      var _middlewareData$offse, _middlewareData$arrow;
      const {
        x,
        y,
        placement,
        middlewareData
      } = state;
      const diffCoords = await convertValueToCoords(state, options);
      if (placement === ((_middlewareData$offse = middlewareData.offset) == null ? void 0 : _middlewareData$offse.placement) && (_middlewareData$arrow = middlewareData.arrow) != null && _middlewareData$arrow.alignmentOffset) {
        return {};
      }
      return {
        x: x + diffCoords.x,
        y: y + diffCoords.y,
        data: {
          ...diffCoords,
          placement
        }
      };
    }
  };
};
var shift = function(options) {
  if (options === void 0) {
    options = {};
  }
  return {
    name: "shift",
    options,
    async fn(state) {
      const {
        x,
        y,
        placement,
        platform: platform2
      } = state;
      const {
        mainAxis: checkMainAxis = true,
        crossAxis: checkCrossAxis = false,
        limiter = {
          fn: (_ref) => {
            let {
              x: x2,
              y: y2
            } = _ref;
            return {
              x: x2,
              y: y2
            };
          }
        },
        ...detectOverflowOptions
      } = evaluate(options, state);
      const coords = {
        x,
        y
      };
      const overflow = await platform2.detectOverflow(state, detectOverflowOptions);
      const crossAxis = getSideAxis(placement);
      const mainAxis = getOppositeAxis(crossAxis);
      let mainAxisCoord = coords[mainAxis];
      let crossAxisCoord = coords[crossAxis];
      const clampCoord = (axis, coord) => clamp(coord + overflow[axis === "y" ? "top" : "left"], coord, coord - overflow[axis === "y" ? "bottom" : "right"]);
      if (checkMainAxis) {
        mainAxisCoord = clampCoord(mainAxis, mainAxisCoord);
      }
      if (checkCrossAxis) {
        crossAxisCoord = clampCoord(crossAxis, crossAxisCoord);
      }
      const limitedCoords = limiter.fn({
        ...state,
        [mainAxis]: mainAxisCoord,
        [crossAxis]: crossAxisCoord
      });
      return {
        ...limitedCoords,
        data: {
          x: limitedCoords.x - x,
          y: limitedCoords.y - y,
          enabled: {
            [mainAxis]: checkMainAxis,
            [crossAxis]: checkCrossAxis
          }
        }
      };
    }
  };
};

// node_modules/@floating-ui/utils/dist/floating-ui.utils.dom.mjs
function hasWindow() {
  return typeof window !== "undefined";
}
function getNodeName(node) {
  if (isNode(node)) {
    return (node.nodeName || "").toLowerCase();
  }
  return "#document";
}
function getWindow(node) {
  var _node$ownerDocument;
  return (node == null || (_node$ownerDocument = node.ownerDocument) == null ? void 0 : _node$ownerDocument.defaultView) || window;
}
function getDocumentElement(node) {
  var _ref;
  return (_ref = (isNode(node) ? node.ownerDocument : node.document) || window.document) == null ? void 0 : _ref.documentElement;
}
function isNode(value) {
  if (!hasWindow()) {
    return false;
  }
  return value instanceof Node || value instanceof getWindow(value).Node;
}
function isElement(value) {
  if (!hasWindow()) {
    return false;
  }
  return value instanceof Element || value instanceof getWindow(value).Element;
}
function isHTMLElement(value) {
  if (!hasWindow()) {
    return false;
  }
  return value instanceof HTMLElement || value instanceof getWindow(value).HTMLElement;
}
function isShadowRoot(value) {
  if (!hasWindow() || typeof ShadowRoot === "undefined") {
    return false;
  }
  return value instanceof ShadowRoot || value instanceof getWindow(value).ShadowRoot;
}
function isOverflowElement(element) {
  const {
    overflow,
    overflowX,
    overflowY,
    display
  } = getComputedStyle2(element);
  return /auto|scroll|overlay|hidden|clip/.test(overflow + overflowY + overflowX) && display !== "inline" && display !== "contents";
}
function isTableElement(element) {
  return /^(table|td|th)$/.test(getNodeName(element));
}
function isTopLayer(element) {
  try {
    if (element.matches(":popover-open")) {
      return true;
    }
  } catch (_e) {
  }
  try {
    return element.matches(":modal");
  } catch (_e) {
    return false;
  }
}
var willChangeRe = /transform|translate|scale|rotate|perspective|filter/;
var containRe = /paint|layout|strict|content/;
var isNotNone = (value) => !!value && value !== "none";
var isWebKitValue;
function isContainingBlock(elementOrCss) {
  const css = isElement(elementOrCss) ? getComputedStyle2(elementOrCss) : elementOrCss;
  return isNotNone(css.transform) || isNotNone(css.translate) || isNotNone(css.scale) || isNotNone(css.rotate) || isNotNone(css.perspective) || !isWebKit() && (isNotNone(css.backdropFilter) || isNotNone(css.filter)) || willChangeRe.test(css.willChange || "") || containRe.test(css.contain || "");
}
function getContainingBlock(element) {
  let currentNode = getParentNode(element);
  while (isHTMLElement(currentNode) && !isLastTraversableNode(currentNode)) {
    if (isContainingBlock(currentNode)) {
      return currentNode;
    } else if (isTopLayer(currentNode)) {
      return null;
    }
    currentNode = getParentNode(currentNode);
  }
  return null;
}
function isWebKit() {
  if (isWebKitValue == null) {
    isWebKitValue = typeof CSS !== "undefined" && CSS.supports && CSS.supports("-webkit-backdrop-filter", "none");
  }
  return isWebKitValue;
}
function isLastTraversableNode(node) {
  return /^(html|body|#document)$/.test(getNodeName(node));
}
function getComputedStyle2(element) {
  return getWindow(element).getComputedStyle(element);
}
function getNodeScroll(element) {
  if (isElement(element)) {
    return {
      scrollLeft: element.scrollLeft,
      scrollTop: element.scrollTop
    };
  }
  return {
    scrollLeft: element.scrollX,
    scrollTop: element.scrollY
  };
}
function getParentNode(node) {
  if (getNodeName(node) === "html") {
    return node;
  }
  const result = (
    // Step into the shadow DOM of the parent of a slotted node.
    node.assignedSlot || // DOM Element detected.
    node.parentNode || // ShadowRoot detected.
    isShadowRoot(node) && node.host || // Fallback.
    getDocumentElement(node)
  );
  return isShadowRoot(result) ? result.host : result;
}
function getNearestOverflowAncestor(node) {
  const parentNode = getParentNode(node);
  if (isLastTraversableNode(parentNode)) {
    return (node.ownerDocument || node).body;
  }
  if (isHTMLElement(parentNode) && isOverflowElement(parentNode)) {
    return parentNode;
  }
  return getNearestOverflowAncestor(parentNode);
}
function getOverflowAncestors(node, list, traverseIframes) {
  var _node$ownerDocument2;
  if (list === void 0) {
    list = [];
  }
  if (traverseIframes === void 0) {
    traverseIframes = true;
  }
  const scrollableAncestor = getNearestOverflowAncestor(node);
  const isBody = scrollableAncestor === ((_node$ownerDocument2 = node.ownerDocument) == null ? void 0 : _node$ownerDocument2.body);
  const win = getWindow(scrollableAncestor);
  if (isBody) {
    const frameElement = getFrameElement(win);
    return list.concat(win, win.visualViewport || [], isOverflowElement(scrollableAncestor) ? scrollableAncestor : [], frameElement && traverseIframes ? getOverflowAncestors(frameElement) : []);
  } else {
    return list.concat(scrollableAncestor, getOverflowAncestors(scrollableAncestor, [], traverseIframes));
  }
}
function getFrameElement(win) {
  return win.parent && Object.getPrototypeOf(win.parent) ? win.frameElement : null;
}

// node_modules/@floating-ui/dom/dist/floating-ui.dom.mjs
function getCssDimensions(element) {
  const css = getComputedStyle2(element);
  let width = parseFloat(css.width) || 0;
  let height = parseFloat(css.height) || 0;
  const hasOffset = isHTMLElement(element);
  const offsetWidth = hasOffset ? element.offsetWidth : width;
  const offsetHeight = hasOffset ? element.offsetHeight : height;
  const shouldFallback = round(width) !== offsetWidth || round(height) !== offsetHeight;
  if (shouldFallback) {
    width = offsetWidth;
    height = offsetHeight;
  }
  return {
    width,
    height,
    $: shouldFallback
  };
}
function unwrapElement(element) {
  return !isElement(element) ? element.contextElement : element;
}
function getScale(element) {
  const domElement = unwrapElement(element);
  if (!isHTMLElement(domElement)) {
    return createCoords(1);
  }
  const rect = domElement.getBoundingClientRect();
  const {
    width,
    height,
    $
  } = getCssDimensions(domElement);
  let x = ($ ? round(rect.width) : rect.width) / width;
  let y = ($ ? round(rect.height) : rect.height) / height;
  if (!x || !Number.isFinite(x)) {
    x = 1;
  }
  if (!y || !Number.isFinite(y)) {
    y = 1;
  }
  return {
    x,
    y
  };
}
var noOffsets = /* @__PURE__ */ createCoords(0);
function getVisualOffsets(element) {
  const win = getWindow(element);
  if (!isWebKit() || !win.visualViewport) {
    return noOffsets;
  }
  return {
    x: win.visualViewport.offsetLeft,
    y: win.visualViewport.offsetTop
  };
}
function shouldAddVisualOffsets(element, isFixed, floatingOffsetParent) {
  if (isFixed === void 0) {
    isFixed = false;
  }
  return !!floatingOffsetParent && isFixed && floatingOffsetParent === getWindow(element);
}
function getBoundingClientRect(element, includeScale, isFixedStrategy, offsetParent) {
  if (includeScale === void 0) {
    includeScale = false;
  }
  if (isFixedStrategy === void 0) {
    isFixedStrategy = false;
  }
  const clientRect = element.getBoundingClientRect();
  const domElement = unwrapElement(element);
  let scale = createCoords(1);
  if (includeScale) {
    if (offsetParent) {
      if (isElement(offsetParent)) {
        scale = getScale(offsetParent);
      }
    } else {
      scale = getScale(element);
    }
  }
  const visualOffsets = shouldAddVisualOffsets(domElement, isFixedStrategy, offsetParent) ? getVisualOffsets(domElement) : createCoords(0);
  let x = (clientRect.left + visualOffsets.x) / scale.x;
  let y = (clientRect.top + visualOffsets.y) / scale.y;
  let width = clientRect.width / scale.x;
  let height = clientRect.height / scale.y;
  if (domElement && offsetParent) {
    const win = getWindow(domElement);
    const offsetWin = isElement(offsetParent) ? getWindow(offsetParent) : offsetParent;
    let currentWin = win;
    let currentIFrame = getFrameElement(currentWin);
    while (currentIFrame && offsetWin !== currentWin) {
      const iframeScale = getScale(currentIFrame);
      const iframeRect = currentIFrame.getBoundingClientRect();
      const css = getComputedStyle2(currentIFrame);
      const left = iframeRect.left + (currentIFrame.clientLeft + parseFloat(css.paddingLeft)) * iframeScale.x;
      const top = iframeRect.top + (currentIFrame.clientTop + parseFloat(css.paddingTop)) * iframeScale.y;
      x *= iframeScale.x;
      y *= iframeScale.y;
      width *= iframeScale.x;
      height *= iframeScale.y;
      x += left;
      y += top;
      currentWin = getWindow(currentIFrame);
      currentIFrame = getFrameElement(currentWin);
    }
  }
  return rectToClientRect({
    width,
    height,
    x,
    y
  });
}
function getWindowScrollBarX(element, rect) {
  const leftScroll = getNodeScroll(element).scrollLeft;
  if (!rect) {
    return getBoundingClientRect(getDocumentElement(element)).left + leftScroll;
  }
  return rect.left + leftScroll;
}
function getHTMLOffset(documentElement, scroll) {
  const htmlRect = documentElement.getBoundingClientRect();
  const x = htmlRect.left + scroll.scrollLeft - getWindowScrollBarX(documentElement, htmlRect);
  const y = htmlRect.top + scroll.scrollTop;
  return {
    x,
    y
  };
}
function convertOffsetParentRelativeRectToViewportRelativeRect(_ref) {
  let {
    elements,
    rect,
    offsetParent,
    strategy
  } = _ref;
  const isFixed = strategy === "fixed";
  const documentElement = getDocumentElement(offsetParent);
  const topLayer = elements ? isTopLayer(elements.floating) : false;
  if (offsetParent === documentElement || topLayer && isFixed) {
    return rect;
  }
  let scroll = {
    scrollLeft: 0,
    scrollTop: 0
  };
  let scale = createCoords(1);
  const offsets = createCoords(0);
  const isOffsetParentAnElement = isHTMLElement(offsetParent);
  if (isOffsetParentAnElement || !isFixed) {
    if (getNodeName(offsetParent) !== "body" || isOverflowElement(documentElement)) {
      scroll = getNodeScroll(offsetParent);
    }
    if (isOffsetParentAnElement) {
      const offsetRect = getBoundingClientRect(offsetParent);
      scale = getScale(offsetParent);
      offsets.x = offsetRect.x + offsetParent.clientLeft;
      offsets.y = offsetRect.y + offsetParent.clientTop;
    }
  }
  const htmlOffset = documentElement && !isOffsetParentAnElement && !isFixed ? getHTMLOffset(documentElement, scroll) : createCoords(0);
  return {
    width: rect.width * scale.x,
    height: rect.height * scale.y,
    x: rect.x * scale.x - scroll.scrollLeft * scale.x + offsets.x + htmlOffset.x,
    y: rect.y * scale.y - scroll.scrollTop * scale.y + offsets.y + htmlOffset.y
  };
}
function getClientRects(element) {
  return element.getClientRects ? Array.from(element.getClientRects()) : [];
}
function getDocumentRect(html) {
  const scroll = getNodeScroll(html);
  const body = html.ownerDocument.body;
  const width = max(html.scrollWidth, html.clientWidth, body.scrollWidth, body.clientWidth);
  const height = max(html.scrollHeight, html.clientHeight, body.scrollHeight, body.clientHeight);
  let x = -scroll.scrollLeft + getWindowScrollBarX(html);
  const y = -scroll.scrollTop;
  if (getComputedStyle2(body).direction === "rtl") {
    x += max(html.clientWidth, body.clientWidth) - width;
  }
  return {
    width,
    height,
    x,
    y
  };
}
var SCROLLBAR_MAX = 25;
function getViewportRect(element, strategy, rootBoundary) {
  if (rootBoundary === void 0) {
    rootBoundary = "viewport";
  }
  const isLayoutViewport = rootBoundary === "layoutViewport";
  const win = getWindow(element);
  const html = getDocumentElement(element);
  const visualViewport = win.visualViewport;
  let width = html.clientWidth;
  let height = html.clientHeight;
  let x = 0;
  let y = 0;
  if (visualViewport) {
    const layoutRelativeClientCoords = !isWebKit() || strategy === "fixed";
    if (isLayoutViewport) {
      if (!layoutRelativeClientCoords) {
        x = -visualViewport.offsetLeft;
        y = -visualViewport.offsetTop;
      }
    } else {
      width = visualViewport.width;
      height = visualViewport.height;
      if (layoutRelativeClientCoords) {
        x = visualViewport.offsetLeft;
        y = visualViewport.offsetTop;
      }
    }
  }
  const windowScrollbarX = getWindowScrollBarX(html);
  if (windowScrollbarX <= 0) {
    const doc = html.ownerDocument;
    const body = doc.body;
    const bodyStyles = getComputedStyle(body);
    const bodyMarginInline = doc.compatMode === "CSS1Compat" ? parseFloat(bodyStyles.marginLeft) + parseFloat(bodyStyles.marginRight) || 0 : 0;
    const reservedWidth = Math.abs(html.clientWidth - body.clientWidth - bodyMarginInline);
    const gutter = getComputedStyle(html).scrollbarGutter === "stable both-edges" ? reservedWidth / 2 : reservedWidth;
    if (gutter <= SCROLLBAR_MAX) {
      width -= gutter;
    }
  }
  return {
    width,
    height,
    x,
    y
  };
}
function getInnerBoundingClientRect(element, strategy) {
  const clientRect = getBoundingClientRect(element, true, strategy === "fixed");
  const top = clientRect.top + element.clientTop;
  const left = clientRect.left + element.clientLeft;
  const scale = getScale(element);
  const width = element.clientWidth * scale.x;
  const height = element.clientHeight * scale.y;
  const x = left * scale.x;
  const y = top * scale.y;
  return {
    width,
    height,
    x,
    y
  };
}
function getClientRectFromClippingAncestor(element, clippingAncestor, strategy) {
  let rect;
  if (clippingAncestor === "viewport" || clippingAncestor === "layoutViewport") {
    rect = getViewportRect(element, strategy, clippingAncestor);
  } else if (clippingAncestor === "document") {
    rect = getDocumentRect(getDocumentElement(element));
  } else if (isElement(clippingAncestor)) {
    rect = getInnerBoundingClientRect(clippingAncestor, strategy);
  } else {
    const visualOffsets = getVisualOffsets(element);
    rect = {
      x: clippingAncestor.x - visualOffsets.x,
      y: clippingAncestor.y - visualOffsets.y,
      width: clippingAncestor.width,
      height: clippingAncestor.height
    };
  }
  return rectToClientRect(rect);
}
function getClippingElementAncestors(element, cache) {
  const cachedResult = cache.get(element);
  if (cachedResult) {
    return cachedResult;
  }
  let result = getOverflowAncestors(element, [], false).filter((el) => isElement(el) && getNodeName(el) !== "body");
  let lastKeptComputedStyle = null;
  const elementIsFixed = getComputedStyle2(element).position === "fixed";
  let currentNode = elementIsFixed ? getParentNode(element) : element;
  while (isElement(currentNode) && !isLastTraversableNode(currentNode)) {
    const computedStyle = getComputedStyle2(currentNode);
    const currentNodeIsContaining = isContainingBlock(currentNode);
    const lastPosition = lastKeptComputedStyle ? lastKeptComputedStyle.position : elementIsFixed ? "fixed" : "";
    const shouldDropCurrentNode = !currentNodeIsContaining && (lastPosition === "fixed" || lastPosition === "absolute" && computedStyle.position === "static");
    if (shouldDropCurrentNode) {
      result = result.filter((ancestor) => ancestor !== currentNode);
    } else {
      lastKeptComputedStyle = computedStyle;
    }
    currentNode = getParentNode(currentNode);
  }
  cache.set(element, result);
  return result;
}
function getClippingRect(_ref) {
  let {
    element,
    boundary,
    rootBoundary,
    strategy
  } = _ref;
  const elementClippingAncestors = boundary === "clippingAncestors" ? isTopLayer(element) ? [] : getClippingElementAncestors(element, this._c) : [].concat(boundary);
  const clippingAncestors = [...elementClippingAncestors, rootBoundary];
  const firstRect = getClientRectFromClippingAncestor(element, clippingAncestors[0], strategy);
  let top = firstRect.top;
  let right = firstRect.right;
  let bottom = firstRect.bottom;
  let left = firstRect.left;
  for (let i = 1; i < clippingAncestors.length; i++) {
    const rect = getClientRectFromClippingAncestor(element, clippingAncestors[i], strategy);
    top = max(rect.top, top);
    right = min(rect.right, right);
    bottom = min(rect.bottom, bottom);
    left = max(rect.left, left);
  }
  return {
    width: right - left,
    height: bottom - top,
    x: left,
    y: top
  };
}
function getDimensions(element) {
  const {
    width,
    height
  } = getCssDimensions(element);
  return {
    width,
    height
  };
}
function getRectRelativeToOffsetParent(element, offsetParent, strategy) {
  const isOffsetParentAnElement = isHTMLElement(offsetParent);
  const documentElement = getDocumentElement(offsetParent);
  const isFixed = strategy === "fixed";
  const rect = getBoundingClientRect(element, true, isFixed, offsetParent);
  let scroll = {
    scrollLeft: 0,
    scrollTop: 0
  };
  const offsets = createCoords(0);
  if (isOffsetParentAnElement || !isFixed) {
    if (getNodeName(offsetParent) !== "body" || isOverflowElement(documentElement)) {
      scroll = getNodeScroll(offsetParent);
    }
    if (isOffsetParentAnElement) {
      const offsetRect = getBoundingClientRect(offsetParent, true, isFixed, offsetParent);
      offsets.x = offsetRect.x + offsetParent.clientLeft;
      offsets.y = offsetRect.y + offsetParent.clientTop;
    }
  }
  if (!isOffsetParentAnElement && documentElement) {
    offsets.x = getWindowScrollBarX(documentElement);
  }
  const htmlOffset = documentElement && !isOffsetParentAnElement && !isFixed ? getHTMLOffset(documentElement, scroll) : createCoords(0);
  const x = rect.left + scroll.scrollLeft - offsets.x - htmlOffset.x;
  const y = rect.top + scroll.scrollTop - offsets.y - htmlOffset.y;
  return {
    x,
    y,
    width: rect.width,
    height: rect.height
  };
}
function isStaticPositioned(element) {
  return getComputedStyle2(element).position === "static";
}
function getTrueOffsetParent(element, polyfill) {
  if (!isHTMLElement(element) || getComputedStyle2(element).position === "fixed") {
    return null;
  }
  if (polyfill) {
    return polyfill(element);
  }
  let rawOffsetParent = element.offsetParent;
  if (getDocumentElement(element) === rawOffsetParent) {
    rawOffsetParent = rawOffsetParent.ownerDocument.body;
  }
  return rawOffsetParent;
}
function getOffsetParent(element, polyfill) {
  const win = getWindow(element);
  if (isTopLayer(element)) {
    return win;
  }
  if (!isHTMLElement(element)) {
    let svgOffsetParent = getParentNode(element);
    while (svgOffsetParent && !isLastTraversableNode(svgOffsetParent)) {
      if (isElement(svgOffsetParent) && !isStaticPositioned(svgOffsetParent)) {
        return svgOffsetParent;
      }
      svgOffsetParent = getParentNode(svgOffsetParent);
    }
    return win;
  }
  let offsetParent = getTrueOffsetParent(element, polyfill);
  while (offsetParent && isTableElement(offsetParent) && isStaticPositioned(offsetParent)) {
    offsetParent = getTrueOffsetParent(offsetParent, polyfill);
  }
  if (offsetParent && isLastTraversableNode(offsetParent) && isStaticPositioned(offsetParent) && !isContainingBlock(offsetParent)) {
    return win;
  }
  return offsetParent || getContainingBlock(element) || win;
}
var getElementRects = async function(data) {
  const getOffsetParentFn = this.getOffsetParent || getOffsetParent;
  const getDimensionsFn = this.getDimensions;
  const floatingDimensions = await getDimensionsFn(data.floating);
  return {
    reference: getRectRelativeToOffsetParent(data.reference, await getOffsetParentFn(data.floating), data.strategy),
    floating: {
      x: 0,
      y: 0,
      width: floatingDimensions.width,
      height: floatingDimensions.height
    }
  };
};
function isRTL(element) {
  return getComputedStyle2(element).direction === "rtl";
}
var platform = {
  convertOffsetParentRelativeRectToViewportRelativeRect,
  getDocumentElement,
  getClippingRect,
  getOffsetParent,
  getElementRects,
  getClientRects,
  getDimensions,
  getScale,
  isElement,
  isRTL
};
function rectsAreEqual(a, b) {
  return a.x === b.x && a.y === b.y && a.width === b.width && a.height === b.height;
}
function observeMove(element, onMove, ancestorResize) {
  let io = null;
  let timeoutId;
  const root = getDocumentElement(element);
  function cleanup() {
    var _io;
    clearTimeout(timeoutId);
    (_io = io) == null || _io.disconnect();
    io = null;
  }
  function refresh(skip, threshold) {
    if (skip === void 0) {
      skip = false;
    }
    if (threshold === void 0) {
      threshold = 1;
    }
    cleanup();
    const elementRectForRootMargin = element.getBoundingClientRect();
    const {
      left,
      top,
      width,
      height
    } = elementRectForRootMargin;
    if (!skip) {
      onMove();
    }
    if (!width || !height) {
      return;
    }
    const insetTop = floor(top);
    const insetRight = floor(root.clientWidth - (left + width));
    const insetBottom = floor(root.clientHeight - (top + height));
    const insetLeft = floor(left);
    const rootMargin = -insetTop + "px " + -insetRight + "px " + -insetBottom + "px " + -insetLeft + "px";
    const options = {
      rootMargin,
      threshold: max(0, min(1, threshold)) || 1
    };
    let isFirstUpdate = true;
    function handleObserve(entries) {
      const ratio = entries[0].intersectionRatio;
      if (!rectsAreEqual(elementRectForRootMargin, element.getBoundingClientRect())) {
        return refresh();
      }
      if (ratio !== threshold) {
        if (!isFirstUpdate) {
          return refresh();
        }
        if (!ratio) {
          timeoutId = setTimeout(() => {
            refresh(false, 1e-7);
          }, 1e3);
        } else {
          refresh(false, ratio);
        }
      }
      isFirstUpdate = false;
    }
    try {
      io = new IntersectionObserver(handleObserve, {
        ...options,
        // Handle <iframe>s
        root: root.ownerDocument
      });
    } catch (_e) {
      io = new IntersectionObserver(handleObserve, options);
    }
    io.observe(element);
  }
  const win = getWindow(element);
  const handleResize = () => refresh(ancestorResize);
  win.addEventListener("resize", handleResize);
  refresh(true);
  return () => {
    win.removeEventListener("resize", handleResize);
    cleanup();
  };
}
function autoUpdate(reference, floating, update, options) {
  if (options === void 0) {
    options = {};
  }
  const {
    ancestorScroll = true,
    ancestorResize = true,
    elementResize = typeof ResizeObserver === "function",
    layoutShift = typeof IntersectionObserver === "function",
    animationFrame = false
  } = options;
  const referenceEl = unwrapElement(reference);
  const ancestors = ancestorScroll || ancestorResize ? [...referenceEl ? getOverflowAncestors(referenceEl) : [], ...floating ? getOverflowAncestors(floating) : []] : [];
  ancestors.forEach((ancestor) => {
    ancestorScroll && ancestor.addEventListener("scroll", update);
    ancestorResize && ancestor.addEventListener("resize", update);
  });
  const cleanupIo = referenceEl && layoutShift ? observeMove(referenceEl, update, ancestorResize) : null;
  let reobserveFrame = -1;
  let resizeObserver = null;
  if (elementResize) {
    resizeObserver = new ResizeObserver((_ref) => {
      let [firstEntry] = _ref;
      if (firstEntry && firstEntry.target === referenceEl && resizeObserver && floating) {
        resizeObserver.unobserve(floating);
        cancelAnimationFrame(reobserveFrame);
        reobserveFrame = requestAnimationFrame(() => {
          var _resizeObserver;
          (_resizeObserver = resizeObserver) == null || _resizeObserver.observe(floating);
        });
      }
      update();
    });
    if (referenceEl && !animationFrame) {
      resizeObserver.observe(referenceEl);
    }
    if (floating) {
      resizeObserver.observe(floating);
    }
  }
  let frameId;
  let prevRefRect = animationFrame ? getBoundingClientRect(reference) : null;
  if (animationFrame) {
    frameLoop();
  }
  function frameLoop() {
    const nextRefRect = getBoundingClientRect(reference);
    if (prevRefRect && !rectsAreEqual(prevRefRect, nextRefRect)) {
      update();
    }
    prevRefRect = nextRefRect;
    frameId = requestAnimationFrame(frameLoop);
  }
  update();
  return () => {
    var _resizeObserver2;
    ancestors.forEach((ancestor) => {
      ancestorScroll && ancestor.removeEventListener("scroll", update);
      ancestorResize && ancestor.removeEventListener("resize", update);
    });
    cleanupIo == null || cleanupIo();
    (_resizeObserver2 = resizeObserver) == null || _resizeObserver2.disconnect();
    resizeObserver = null;
    if (animationFrame) {
      cancelAnimationFrame(frameId);
    }
  };
}
var offset2 = offset;
var shift2 = shift;
var flip2 = flip;
var computePosition2 = (reference, floating, options) => {
  const cache = /* @__PURE__ */ new Map();
  const mergedOptions = options != null ? options : {};
  const platformWithCache = {
    ...platform,
    ...mergedOptions.platform,
    _c: cache
  };
  return computePosition(reference, floating, {
    ...mergedOptions,
    platform: platformWithCache
  });
};

// assets/js/behaviours.js
var PERSIST_PREFIX = "lantern:persist:";
function typingTarget(el) {
  if (!el || el === document.body) return false;
  const tag = el.tagName;
  if (tag === "INPUT" || tag === "TEXTAREA" || tag === "SELECT") return true;
  return Boolean(el.isContentEditable);
}
function listItems(list) {
  return [...list.querySelectorAll("[data-lantern-list-item]")].filter(
    (el) => !el.hidden && el.offsetParent !== null
  );
}
function roveList(list, target) {
  const items = listItems(list);
  if (items.length === 0) return;
  for (const item of items) item.tabIndex = item === target ? 0 : -1;
  target?.focus();
}
function openListItem(item) {
  const link = item.matches("a[href]") ? item : item.querySelector("a[href]");
  if (link) {
    link.click();
    return;
  }
  item.click();
}
function onListNavKey(e) {
  if (e.defaultPrevented || e.metaKey || e.ctrlKey || e.altKey) return;
  if (typingTarget(e.target)) return;
  const list = e.target.closest?.("[data-lantern-list-nav]");
  if (!list) return;
  const items = listItems(list);
  if (items.length === 0) return;
  const current = items.find((item) => item === e.target || item.contains(e.target));
  if (e.key === "Enter") {
    if (!current) return;
    e.preventDefault();
    openListItem(current);
    return;
  }
  const from = current || items[0];
  const idx = items.indexOf(from);
  let next = null;
  if (e.key === "j" || e.key === "ArrowDown") next = items[Math.min(idx + 1, items.length - 1)];
  else if (e.key === "k" || e.key === "ArrowUp") next = items[Math.max(idx - 1, 0)];
  else if (e.key === "Home") next = items[0];
  else if (e.key === "End") next = items[items.length - 1];
  else return;
  if (next && next !== current) {
    e.preventDefault();
    roveList(list, next);
  }
}
function initList(list) {
  const items = listItems(list);
  const current = items.find((item) => item.tabIndex === 0) || items[0];
  for (const item of items) item.tabIndex = item === current ? 0 : -1;
}
function storage(root) {
  try {
    const view = root?.ownerDocument?.defaultView || (typeof window !== "undefined" ? window : null);
    return view?.localStorage ?? null;
  } catch {
    return null;
  }
}
function readPersist(root, key) {
  try {
    return storage(root)?.getItem(PERSIST_PREFIX + key) ?? null;
  } catch {
    return null;
  }
}
function writePersist(root, key, value) {
  try {
    storage(root)?.setItem(PERSIST_PREFIX + key, value);
  } catch {
  }
}
function persistRoot(el) {
  return el.closest("[data-lantern-persist]") || el;
}
function isPersistedOpen(root) {
  if (root.tagName === "DETAILS") return root.open;
  if (root.getAttribute("aria-expanded") === "true") return true;
  const toggle = root.querySelector("[data-lantern-persist-toggle], [aria-expanded]");
  if (toggle?.getAttribute("aria-expanded") === "true") return true;
  return root.dataset.open === "true" || root.hasAttribute("open");
}
function setPersistedOpen(root, open) {
  if (root.tagName === "DETAILS") {
    root.open = open;
    return;
  }
  const toggle = root.matches("[data-lantern-persist-toggle]") ? root : root.querySelector("[data-lantern-persist-toggle], [aria-expanded]");
  const panel = root.querySelector("[data-lantern-persist-panel]");
  root.dataset.open = open ? "true" : "false";
  if (open) root.setAttribute("open", "");
  else root.removeAttribute("open");
  if (toggle) toggle.setAttribute("aria-expanded", String(open));
  if (panel) panel.hidden = !open;
}
function restorePersist(root) {
  const key = root.getAttribute("data-lantern-persist");
  if (!key) return;
  const stored = readPersist(root, key);
  if (stored === "open") setPersistedOpen(root, true);
  if (stored === "closed") setPersistedOpen(root, false);
}
function collapseKey(control) {
  return control.getAttribute("data-lantern-collapse");
}
function applyCollapse(control, collapsed) {
  const key = collapseKey(control);
  if (!key) return;
  const band = control.closest(".lui-group-band");
  if (band) {
    if (collapsed) band.setAttribute("data-collapsed", "");
    else band.removeAttribute("data-collapsed");
  }
  control.setAttribute("aria-expanded", String(!collapsed));
  const container = (band || control).parentElement;
  if (!container) return;
  for (const el of container.children) {
    if (el.getAttribute("data-lantern-group") === key) el.hidden = collapsed;
  }
}
function persistKeyFor(control) {
  return persistRoot(control).getAttribute("data-lantern-persist");
}
function toggleCollapse(control) {
  const band = control.closest(".lui-group-band");
  const next = !band?.hasAttribute("data-collapsed");
  applyCollapse(control, next);
  const persistKey = persistKeyFor(control);
  if (persistKey) writePersist(control, persistKey, next ? "closed" : "open");
}
function restoreCollapse(control) {
  const persistKey = persistKeyFor(control);
  const stored = persistKey ? readPersist(control, persistKey) : null;
  let collapsed;
  if (stored === "closed") collapsed = true;
  else if (stored === "open") collapsed = false;
  else collapsed = Boolean(control.closest(".lui-group-band")?.hasAttribute("data-collapsed"));
  applyCollapse(control, collapsed);
}
function onCollapseClick(e) {
  const control = e.target.closest("[data-lantern-collapse]");
  if (!control) return;
  toggleCollapse(control);
}
function onCollapseKey(e) {
  if (e.defaultPrevented || e.metaKey || e.ctrlKey || e.altKey) return;
  if (e.key !== "Enter" && e.key !== " ") return;
  if (typingTarget(e.target)) return;
  const control = e.target.closest?.("[data-lantern-collapse]");
  if (!control) return;
  e.preventDefault();
  toggleCollapse(control);
}
var applying = false;
function restoreAll(doc) {
  if (applying || !doc) return;
  applying = true;
  try {
    doc.querySelectorAll("[data-lantern-persist]").forEach(restorePersist);
    doc.querySelectorAll("[data-lantern-list-nav]").forEach(initList);
    doc.querySelectorAll("[data-lantern-collapse]").forEach(restoreCollapse);
  } finally {
    applying = false;
  }
}
function installBehaviours(doc = typeof document === "undefined" ? null : document) {
  if (!doc?.documentElement) return;
  if (doc.documentElement.dataset.lanternBehaviours === "1") {
    restoreAll(doc);
    return;
  }
  doc.documentElement.dataset.lanternBehaviours = "1";
  doc.addEventListener("keydown", onListNavKey, true);
  doc.addEventListener("keydown", onCollapseKey);
  doc.addEventListener("click", onPersistClick);
  doc.addEventListener("click", onCollapseClick);
  doc.addEventListener("toggle", onPersistToggle, true);
  restoreAll(doc);
  const Observer = doc.defaultView?.MutationObserver;
  if (!Observer) return;
  let timer = 0;
  const mo = new Observer(() => {
    clearTimeout(timer);
    timer = setTimeout(() => restoreAll(doc), 0);
  });
  mo.observe(doc.documentElement, { childList: true, subtree: true });
}
function onPersistClick(e) {
  const toggle = e.target.closest("[data-lantern-persist-toggle]");
  if (!toggle) return;
  const root = persistRoot(toggle);
  const key = root.getAttribute("data-lantern-persist");
  if (!key) return;
  const next = !isPersistedOpen(root);
  setPersistedOpen(root, next);
  writePersist(root, key, next ? "open" : "closed");
}
function onPersistToggle(e) {
  const root = e.target;
  if (!root.matches?.("details[data-lantern-persist]")) return;
  const key = root.getAttribute("data-lantern-persist");
  if (!key) return;
  writePersist(root, key, root.open ? "open" : "closed");
}

// assets/js/lantern_ui_hooks.js
var esc = (s) => String(s).replace(
  /[&<>"']/g,
  (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" })[c]
);
var ChartHover = {
  mounted() {
    this.setup();
  },
  updated() {
    this.setup();
  },
  setup() {
    this.points = JSON.parse(this.el.dataset.points || "[]");
    this.top = parseFloat(this.el.dataset.top);
    this.bottom = parseFloat(this.el.dataset.bottom);
    const svg = this.el.querySelector("svg");
    this.hover = this.el.querySelector(".lantern-hover");
    if (!svg || !this.hover || this.points.length === 0) return;
    this.vbWidth = svg.viewBox.baseVal.width;
    if (this.svg && this._onMove) {
      this.svg.removeEventListener("mousemove", this._onMove);
      this.svg.removeEventListener("touchmove", this._onMove);
      this.svg.removeEventListener("mouseleave", this._onLeave);
      this.svg.removeEventListener("touchend", this._onLeave);
      this.svg.removeEventListener("touchcancel", this._onLeave);
    }
    this.svg = svg;
    this._onMove = (e) => this.onMove(e);
    this._onLeave = () => this.onLeave();
    svg.addEventListener("mousemove", this._onMove);
    svg.addEventListener("touchmove", this._onMove, { passive: false });
    svg.addEventListener("mouseleave", this._onLeave);
    svg.addEventListener("touchend", this._onLeave);
    svg.addEventListener("touchcancel", this._onLeave);
  },
  onMove(e) {
    const touch = e.touches && e.touches[0];
    if (touch) e.preventDefault();
    const clientX = touch ? touch.clientX : e.clientX;
    const rect = this.svg.getBoundingClientRect();
    const vx = (clientX - rect.left) / rect.width * this.vbWidth;
    let idx = 0;
    let best = Infinity;
    for (let i = 0; i < this.points.length; i++) {
      const dx = Math.abs(this.points[i].x - vx);
      if (dx < best) {
        best = dx;
        idx = i;
      }
    }
    const pt = this.points[idx];
    const surface = "var(--lantern-surface, var(--background-base, #ffffff))";
    const fg = "var(--lantern-fg, var(--foreground, #111827))";
    const fgMuted = "var(--lantern-fg-muted, var(--foreground-softer, #6b7280))";
    const boxW = 104;
    const boxH = 34;
    const bx = Math.min(Math.max(pt.x - boxW / 2, 4), this.vbWidth - boxW - 4);
    const by = pt.y - (boxH + 12) < this.top ? pt.y + 12 : pt.y - (boxH + 12);
    const label2 = pt.d == null ? "" : pt.d;
    this.hover.innerHTML = `<line x1="${pt.x}" x2="${pt.x}" y1="${this.top}" y2="${this.bottom}" stroke="currentColor" stroke-width="1.5" stroke-dasharray="4 3" opacity="0.5"/><circle cx="${pt.x}" cy="${pt.y}" r="6" fill="currentColor" opacity="0.18"/><circle cx="${pt.x}" cy="${pt.y}" r="3.5" fill="currentColor" stroke="${surface}" stroke-width="2"/><rect x="${bx}" y="${by}" width="${boxW}" height="${boxH}" rx="6" fill="${surface}" stroke="currentColor" stroke-opacity="0.25" stroke-width="0.5"/><text x="${bx + 10}" y="${by + 15}" font-size="12.5" font-weight="500" fill="${fg}">${esc(pt.p)}</text><text x="${bx + 10}" y="${by + 28}" font-size="10.5" fill="${fgMuted}">${esc(label2)}</text>`;
    this.hover.style.opacity = 1;
  },
  onLeave() {
    if (this.hover) this.hover.style.opacity = 0;
  }
};
var LineHover = {
  mounted() {
    this.setup();
  },
  updated() {
    this.setup();
  },
  setup() {
    this.series = JSON.parse(this.el.dataset.series || "[]");
    this.top = parseFloat(this.el.dataset.top);
    this.bottom = parseFloat(this.el.dataset.bottom);
    const svg = this.el.querySelector("svg");
    this.hover = this.el.querySelector(".lantern-hover");
    if (!svg || !this.hover || this.series.length === 0) return;
    this.vbWidth = svg.viewBox.baseVal.width;
    if (this.svg && this._onMove) {
      this.svg.removeEventListener("mousemove", this._onMove);
      this.svg.removeEventListener("touchmove", this._onMove);
      this.svg.removeEventListener("mouseleave", this._onLeave);
      this.svg.removeEventListener("touchend", this._onLeave);
      this.svg.removeEventListener("touchcancel", this._onLeave);
    }
    this.svg = svg;
    this._onMove = (e) => this.onMove(e);
    this._onLeave = () => this.onLeave();
    svg.addEventListener("mousemove", this._onMove);
    svg.addEventListener("touchmove", this._onMove, { passive: false });
    svg.addEventListener("mouseleave", this._onLeave);
    svg.addEventListener("touchend", this._onLeave);
    svg.addEventListener("touchcancel", this._onLeave);
  },
  nearest(pts, vx) {
    let idx = 0;
    let best = Infinity;
    for (let i = 0; i < pts.length; i++) {
      const dx = Math.abs(pts[i].x - vx);
      if (dx < best) {
        best = dx;
        idx = i;
      }
    }
    return pts[idx];
  },
  onMove(e) {
    const touch = e.touches && e.touches[0];
    if (touch) e.preventDefault();
    const clientX = touch ? touch.clientX : e.clientX;
    const rect = this.svg.getBoundingClientRect();
    const vx = (clientX - rect.left) / rect.width * this.vbWidth;
    const surface = "var(--lantern-surface, var(--background-base, #ffffff))";
    const fg = "var(--lantern-fg, var(--foreground, #111827))";
    const fgMuted = "var(--lantern-fg-muted, var(--foreground-softer, #6b7280))";
    const rows = [];
    let crossX = null;
    let tLabel = "";
    for (const s of this.series) {
      if (!s.pts || !s.pts.length) continue;
      const pt = this.nearest(s.pts, vx);
      if (crossX === null) {
        crossX = pt.x;
        tLabel = pt.t;
      }
      rows.push({ label: s.label, color: s.color, v: pt.v, x: pt.x, y: pt.y });
    }
    if (crossX === null) return;
    let out = `<line x1="${crossX}" x2="${crossX}" y1="${this.top}" y2="${this.bottom}" stroke="${fg}" stroke-width="1" stroke-dasharray="4 3" opacity="0.4"/>`;
    for (const r of rows) {
      out += `<circle cx="${r.x}" cy="${r.y}" r="3" fill="${r.color}" stroke="${surface}" stroke-width="1.5"/>`;
    }
    const rowH = 15;
    const labelW = Math.max(...rows.map((r) => String(r.label).length)) * 6.2;
    const valueW = Math.max(...rows.map((r) => String(r.v).length)) * 6.5;
    const boxW = Math.min(Math.max(120, 22 + labelW + 16 + valueW + 10), this.vbWidth - 8);
    const boxH = 20 + rows.length * rowH;
    const bx = Math.min(Math.max(crossX + 10, 4), this.vbWidth - boxW - 4);
    const by = Math.max(this.top, Math.min(this.bottom - boxH, rows[0].y - boxH / 2));
    out += `<rect x="${bx}" y="${by}" width="${boxW}" height="${boxH}" rx="6" fill="${surface}" stroke="${fg}" stroke-opacity="0.2" stroke-width="0.5"/>`;
    out += `<text x="${bx + 10}" y="${by + 14}" font-size="10.5" fill="${fgMuted}">${esc(tLabel)}</text>`;
    rows.forEach((r, i) => {
      const ry = by + 14 + (i + 1) * rowH;
      out += `<circle cx="${bx + 12}" cy="${ry - 3.5}" r="3.5" fill="${r.color}"/>`;
      out += `<text x="${bx + 22}" y="${ry}" font-size="11" fill="${fg}">${esc(r.label)}</text>`;
      out += `<text x="${bx + boxW - 10}" y="${ry}" font-size="11" font-weight="500" text-anchor="end" fill="${fg}">${esc(r.v)}</text>`;
    });
    this.hover.innerHTML = out;
    this.hover.style.opacity = 1;
  },
  onLeave() {
    if (this.hover) this.hover.style.opacity = 0;
  }
};
function canFloat() {
  return typeof window !== "undefined" && typeof window.getComputedStyle === "function";
}
function position(anchor, floating, { placement = "bottom-start", gap = 4 } = {}) {
  if (!anchor || !floating) return Promise.resolve(placement);
  floating.style.position = "fixed";
  floating.style.top = "0px";
  floating.style.left = "0px";
  if (!canFloat()) return Promise.resolve(placement);
  return computePosition2(anchor, floating, {
    placement,
    strategy: "fixed",
    middleware: [offset2(gap), flip2(), shift2({ padding: 8 })]
  }).then(({ x, y, placement: placed }) => {
    floating.style.left = `${x}px`;
    floating.style.top = `${y}px`;
    return placed;
  });
}
function trackPosition(anchor, floating, opts) {
  if (!canFloat()) {
    position(anchor, floating, opts);
    return () => {
    };
  }
  return autoUpdate(anchor, floating, () => {
    position(anchor, floating, opts);
  });
}
var FOCUSABLE = 'a[href], button:not([disabled]), input:not([disabled]), select:not([disabled]), textarea:not([disabled]), [tabindex]:not([tabindex="-1"])';
function trapFocus(container, initialFocusSelector = null) {
  const prev = document.activeElement;
  const visibleFocusable = (root) => [...root.querySelectorAll(FOCUSABLE)].filter((el) => el.offsetParent !== null);
  const onKeydown = (e) => {
    if (e.key !== "Tab") return;
    const items = visibleFocusable(container);
    if (items.length === 0) return;
    const first = items[0];
    const last = items[items.length - 1];
    if (e.shiftKey && document.activeElement === first) {
      last.focus();
      e.preventDefault();
    } else if (!e.shiftKey && document.activeElement === last) {
      first.focus();
      e.preventDefault();
    }
  };
  container.addEventListener("keydown", onKeydown);
  const initial = initialFocusSelector && container.querySelector(initialFocusSelector);
  const initialTarget = initial?.matches(FOCUSABLE) && initial.offsetParent !== null ? initial : initial && visibleFocusable(initial)[0];
  const target = initialTarget || visibleFocusable(container)[0];
  if (target) target.focus();
  return () => {
    container.removeEventListener("keydown", onKeydown);
    if (prev && prev.focus) prev.focus();
  };
}
function onDismiss(el, cb, { anchor = null } = {}) {
  const onKey = (e) => {
    if (e.key === "Escape") cb("escape");
  };
  const onPointer = (e) => {
    if (el.contains(e.target)) return;
    if (anchor && anchor.contains(e.target)) return;
    cb("outside");
  };
  document.addEventListener("keydown", onKey);
  document.addEventListener("pointerdown", onPointer);
  return () => {
    document.removeEventListener("keydown", onKey);
    document.removeEventListener("pointerdown", onPointer);
  };
}
var LanternOverlay = {
  mounted() {
    this.trigger = this.el.querySelector('[data-part="trigger"]');
    this.panel = this.el.querySelector('[data-part="panel"]');
    if (!this.trigger || !this.panel) return;
    this.open = false;
    this.cleanup = [];
    this.trigger.addEventListener("click", () => this.open ? this.hide() : this.show());
    this.trigger.addEventListener("keydown", (e) => {
      if ((e.key === "ArrowDown" || e.key === "Enter") && !this.open) {
        e.preventDefault();
        this.show();
      }
    });
  },
  show() {
    this.open = true;
    this.panel.hidden = false;
    this.cleanup.push(trackPosition(this.trigger, this.panel, { placement: this.el.dataset.placement }));
    this.trigger.setAttribute("aria-expanded", "true");
    this.cleanup.push(trapFocus(this.panel));
    this.cleanup.push(onDismiss(this.panel, () => this.hide(), { anchor: this.trigger }));
  },
  hide() {
    this.open = false;
    this.cleanup.forEach((fn) => fn());
    this.cleanup = [];
    this.panel.hidden = true;
    this.trigger.setAttribute("aria-expanded", "false");
  },
  destroyed() {
    this.cleanup.forEach((fn) => fn());
  }
};
var CAL_KEYS = { ArrowLeft: -1, ArrowRight: 1, ArrowUp: -7, ArrowDown: 7 };
var MONTHS = [
  "January",
  "February",
  "March",
  "April",
  "May",
  "June",
  "July",
  "August",
  "September",
  "October",
  "November",
  "December"
];
var LanternCalendar = {
  mounted() {
    this.month = this.el.dataset.month;
    this.weekStart = parseInt(this.el.dataset.weekStart || "0", 10);
    this.grid = this.el.querySelector('[data-part="grid"]');
    this.title = this.el.querySelector('[data-part="title"]');
    this.el.querySelector('[data-part="prev"]').addEventListener("click", () => this.nav(-1));
    this.el.querySelector('[data-part="next"]').addEventListener("click", () => this.nav(1));
    this.grid.addEventListener("click", (e) => {
      const day = e.target.closest(".lui-cal-day");
      if (day && !day.disabled) this.select(day.dataset.date);
    });
    this.grid.addEventListener("keydown", (e) => this.onKey(e));
    this.el.addEventListener("lantern:set-value", (e) => {
      const iso = e.detail.value;
      if (iso) {
        this.el.dataset.value = iso;
        this.month = iso.slice(0, 8) + "01";
      } else {
        delete this.el.dataset.value;
      }
      this.render();
    });
  },
  nav(delta) {
    const [y, m] = this.month.split("-").map(Number);
    const d = new Date(Date.UTC(y, m - 1 + delta, 1));
    this.month = d.toISOString().slice(0, 10);
    this.render();
  },
  select(iso) {
    this.el.dataset.value = iso;
    this.render();
    this.el.dispatchEvent(
      new CustomEvent("lantern:change", { bubbles: true, detail: { value: iso } })
    );
  },
  onKey(e) {
    const day = e.target.closest(".lui-cal-day");
    if (!day) return;
    let target = null;
    if (e.key in CAL_KEYS) {
      target = this.addDays(day.dataset.date, CAL_KEYS[e.key]);
    } else if (e.key === "PageUp" || e.key === "PageDown") {
      const sign = e.key === "PageUp" ? -1 : 1;
      target = this.addMonths(day.dataset.date, e.shiftKey ? sign * 12 : sign);
    } else if (e.key === "Home" || e.key === "End") {
      const dow = this.dayOffset(day.dataset.date);
      target = this.addDays(day.dataset.date, e.key === "Home" ? -dow : 6 - dow);
    } else if (e.key === "t") {
      target = (/* @__PURE__ */ new Date()).toISOString().slice(0, 10);
    } else if (e.key === "Enter" || e.key === " ") {
      e.preventDefault();
      if (!day.disabled) this.select(day.dataset.date);
      return;
    } else {
      return;
    }
    e.preventDefault();
    this.focusDate(target);
  },
  focusDate(iso) {
    if (iso.slice(0, 7) !== this.month.slice(0, 7)) {
      this.month = iso.slice(0, 8) + "01";
      this.render();
    }
    const btn = this.grid.querySelector(`[data-date="${iso}"]`);
    if (btn) {
      this.grid.querySelectorAll(".lui-cal-day").forEach((b) => b.tabIndex = -1);
      btn.tabIndex = 0;
      btn.focus();
    }
  },
  addDays(iso, n) {
    const d = /* @__PURE__ */ new Date(iso + "T00:00:00Z");
    d.setUTCDate(d.getUTCDate() + n);
    return d.toISOString().slice(0, 10);
  },
  addMonths(iso, n) {
    const d = /* @__PURE__ */ new Date(iso + "T00:00:00Z");
    const day = d.getUTCDate();
    d.setUTCDate(1);
    d.setUTCMonth(d.getUTCMonth() + n);
    const last = new Date(Date.UTC(d.getUTCFullYear(), d.getUTCMonth() + 1, 0)).getUTCDate();
    d.setUTCDate(Math.min(day, last));
    return d.toISOString().slice(0, 10);
  },
  dayOffset(iso) {
    const dow = (/* @__PURE__ */ new Date(iso + "T00:00:00Z")).getUTCDay();
    return (dow - this.weekStart + 7) % 7;
  },
  render() {
    const [y, m] = this.month.split("-").map(Number);
    const first = new Date(Date.UTC(y, m - 1, 1));
    const back = (first.getUTCDay() - this.weekStart + 7) % 7;
    const start = new Date(first);
    start.setUTCDate(start.getUTCDate() - back);
    const today = (/* @__PURE__ */ new Date()).toISOString().slice(0, 10);
    const selected = this.el.dataset.value;
    const min2 = this.el.dataset.min;
    const max2 = this.el.dataset.max;
    this.title.textContent = `${MONTHS[m - 1]} ${y}`;
    let focusTarget = null;
    const rows = [...this.grid.querySelectorAll('[role="row"]')].slice(1);
    rows.forEach((row, w) => {
      ;
      [...row.children].forEach((btn, i) => {
        const d = new Date(start);
        d.setUTCDate(d.getUTCDate() + w * 7 + i);
        const iso = d.toISOString().slice(0, 10);
        btn.dataset.date = iso;
        btn.textContent = d.getUTCDate();
        btn.toggleAttribute("data-outside", d.getUTCMonth() !== m - 1);
        btn.toggleAttribute("data-today", iso === today);
        if (iso === selected) btn.setAttribute("aria-selected", "true");
        else btn.removeAttribute("aria-selected");
        btn.disabled = !!(min2 && iso < min2 || max2 && iso > max2);
        btn.setAttribute("aria-label", `${MONTHS[m - 1]} ${d.getUTCDate()}, ${y}`);
        btn.tabIndex = -1;
        const inMonth = !btn.hasAttribute("data-outside");
        if (iso === selected && inMonth || !focusTarget && d.getUTCDate() === 1 && inMonth)
          focusTarget = btn;
      });
    });
    if (focusTarget) focusTarget.tabIndex = 0;
  }
};
var SEG_MAX = { month: 12, day: 31, year: 9999, hour: 12, minute: 59, second: 59, millisecond: 999 };
var SEG_MIN = { month: 1, day: 1, year: 1, hour: 1, minute: 0, second: 0, millisecond: 0 };
var SEG_PAD = { month: 2, day: 2, year: 4, hour: 2, minute: 2, second: 2, millisecond: 3 };
var LanternDatetimeField = {
  mounted() {
    this.mode = this.el.dataset.mode;
    this.hidden = this.el.querySelector('[data-part="value"]');
    this.segs = [...this.el.querySelectorAll(".lui-dtf-seg")];
    this.buf = "";
    this.values = {};
    for (const seg of this.segs) {
      const key = seg.dataset.seg;
      if (seg.dataset.set) {
        this.values[key] = key === "meridiem" ? seg.textContent.trim() : parseInt(seg.textContent, 10);
      }
    }
    if (this.el.dataset.disabled) return;
    this.el.addEventListener("keydown", (e) => this.onKey(e));
    this.el.addEventListener("focusin", () => this.buf = "");
    this.el.querySelector('[data-part="clear"]')?.addEventListener("click", () => this.clearAll());
    this.segs.forEach((s) => s.addEventListener("mousedown", () => this.buf = ""));
    this.el.addEventListener("lantern:set-date", (e) => {
      const [y, m, d] = e.detail.value.split("-").map(Number);
      Object.assign(this.values, { year: y, month: m, day: d });
      if (this.mode === "datetime" && this.values.hour == null) {
        Object.assign(this.values, { hour: 12, minute: 0, meridiem: "AM" });
      }
      this.renderAndCommit();
    });
    this.el.addEventListener("lantern:set-now", () => {
      const now = /* @__PURE__ */ new Date();
      const h = now.getHours();
      Object.assign(this.values, {
        year: now.getFullYear(),
        month: now.getMonth() + 1,
        day: now.getDate(),
        hour: h % 12 === 0 ? 12 : h % 12,
        minute: now.getMinutes(),
        second: now.getSeconds(),
        millisecond: now.getMilliseconds(),
        meridiem: h < 12 ? "AM" : "PM"
      });
      this.renderAndCommit();
    });
    this.el.addEventListener("lantern:set-time", (e) => {
      const m = /^(\d{2}):(\d{2}):(\d{2})\.(\d{3})$/.exec(e.detail.value || "");
      if (!m) return;
      const h24 = parseInt(m[1], 10);
      Object.assign(this.values, {
        hour: h24 % 12 === 0 ? 12 : h24 % 12,
        minute: parseInt(m[2], 10),
        second: parseInt(m[3], 10),
        millisecond: parseInt(m[4], 10),
        meridiem: h24 < 12 ? "AM" : "PM"
      });
      if (this.mode === "datetime" && this.values.year == null) {
        const now = /* @__PURE__ */ new Date();
        Object.assign(this.values, {
          year: now.getFullYear(),
          month: now.getMonth() + 1,
          day: now.getDate()
        });
      }
      this.renderAndCommit();
    });
    this.el.addEventListener("lantern:clear", () => this.clearAll());
  },
  onKey(e) {
    const seg = e.target.closest(".lui-dtf-seg");
    if (!seg) {
      if (e.key === "Backspace" && (e.metaKey || e.ctrlKey)) this.clearAll();
      return;
    }
    const key = seg.dataset.seg;
    if (e.key === "Backspace" && (e.metaKey || e.ctrlKey)) {
      e.preventDefault();
      return this.clearAll();
    }
    if (/^[0-9]$/.test(e.key) && key !== "meridiem") {
      e.preventDefault();
      return this.type(seg, key, e.key);
    }
    switch (e.key) {
      case "ArrowUp":
      case "ArrowDown": {
        e.preventDefault();
        this.buf = "";
        this.step(key, e.key === "ArrowUp" ? 1 : -1);
        return this.renderAndCommit();
      }
      case "ArrowLeft":
      case "ArrowRight":
        e.preventDefault();
        return this.move(seg, e.key === "ArrowRight" ? 1 : -1);
      case "Backspace":
      case "Delete":
        e.preventDefault();
        this.buf = "";
        delete this.values[key];
        return this.renderAndCommit();
      case "a":
      case "A":
      case "p":
      case "P":
        if (key === "meridiem" || this.mode !== "date") {
          e.preventDefault();
          this.values.meridiem = /a/i.test(e.key) ? "AM" : "PM";
          return this.renderAndCommit();
        }
        return;
      default:
        return;
    }
  },
  type(seg, key, digit) {
    this.buf += digit;
    let n = parseInt(this.buf, 10);
    const max2 = SEG_MAX[key];
    if (n > max2) {
      this.buf = digit;
      n = parseInt(digit, 10);
    }
    this.values[key] = key === "year" ? n : Math.max(n, 0);
    this.renderAndCommit();
    const full = this.buf.length >= SEG_PAD[key];
    const ambiguous = parseInt(this.buf + "0", 10) <= max2;
    if (full || !ambiguous) {
      this.buf = "";
      if (SEG_MIN[key] === 1 && this.values[key] === 0) this.values[key] = SEG_MIN[key];
      this.move(seg, 1);
    }
  },
  step(key, dir) {
    if (key === "meridiem") {
      this.values.meridiem = this.values.meridiem === "AM" ? "PM" : "AM";
      return;
    }
    const min2 = SEG_MIN[key];
    const max2 = SEG_MAX[key];
    const cur = this.values[key];
    if (cur == null) {
      this.values[key] = dir > 0 ? min2 : max2;
    } else if (key === "year") {
      this.values.year = Math.min(Math.max(cur + dir, 1), 9999);
    } else {
      const span = max2 - min2 + 1;
      this.values[key] = (cur - min2 + dir + span) % span + min2;
    }
  },
  move(fromSeg, dir) {
    const i = this.segs.indexOf(fromSeg);
    const next = this.segs[i + dir];
    if (next) {
      this.buf = "";
      next.focus();
    }
  },
  clearAll() {
    this.values = {};
    this.buf = "";
    this.renderAndCommit();
    this.segs[0]?.focus();
  },
  renderAndCommit() {
    for (const seg of this.segs) {
      const key = seg.dataset.seg;
      const v = this.values[key];
      if (v == null) {
        seg.textContent = seg.dataset.placeholder;
        seg.removeAttribute("data-set");
      } else {
        seg.textContent = key === "meridiem" ? v : String(v).padStart(SEG_PAD[key], "0");
        seg.setAttribute("data-set", "true");
      }
      if (key !== "meridiem") seg.setAttribute("aria-valuenow", v == null ? "" : v);
    }
    const prev = this.hidden.value;
    this.hidden.value = this.canonical();
    if (this.hidden.value !== prev) {
      this.el.dispatchEvent(
        new CustomEvent("lantern:change", { bubbles: true, detail: { value: this.hidden.value || null } })
      );
    }
  },
  canonical() {
    const v = this.values;
    const pad = (n, w = 2) => String(n).padStart(w, "0");
    const dateOk = v.year != null && v.month != null && v.day != null;
    const timeOk = v.hour != null && v.minute != null && v.meridiem != null;
    const date = dateOk ? `${pad(v.year, 4)}-${pad(v.month)}-${pad(v.day)}` : null;
    let time = null;
    if (timeOk) {
      let h = v.hour % 12;
      if (v.meridiem === "PM") h += 12;
      time = `${pad(h)}:${pad(v.minute)}:${pad(v.second ?? 0)}.${pad(v.millisecond ?? 0, 3)}`;
    }
    if (this.mode === "date") return date || "";
    if (this.mode === "time") return time || "";
    return date && time ? `${date}T${time}` : "";
  }
};
var LanternPicker = {
  mounted() {
    this.trigger = this.el.querySelector('[data-part="trigger"]');
    this.toggle = this.el.querySelector('[data-part="toggle"]');
    this.panel = this.el.querySelector('[data-part="panel"]');
    this.calendar = this.panel?.querySelector(".lui-cal");
    this.panelTime = this.panel?.querySelector('[data-part="panel-time"]');
    this.open = false;
    this.cleanup = [];
    this.panel?.addEventListener("lantern:change", (e) => {
      if (e.target.closest(".lui-cal")) {
        e.stopPropagation();
        this.trigger.dispatchEvent(
          new CustomEvent("lantern:set-date", { detail: { value: e.detail.value } })
        );
      } else if (this.panelTime && e.target.closest('[data-part="panel-time"]')) {
        e.stopPropagation();
        this.trigger.dispatchEvent(
          new CustomEvent("lantern:set-time", { detail: { value: e.detail.value } })
        );
      }
    });
    this.trigger.addEventListener("lantern:change", (e) => {
      const v = e.detail.value;
      this.calendar?.dispatchEvent(
        new CustomEvent("lantern:set-value", { detail: { value: v ? v.slice(0, 10) : null } })
      );
      if (this.panelTime && v && v.length >= 23) {
        this.panelTime.dispatchEvent(
          new CustomEvent("lantern:set-time", { detail: { value: v.slice(11) } })
        );
      }
    });
    this.toggle?.addEventListener("click", () => this.open ? this.hide() : this.show());
    this.panel?.querySelector('[data-part="today"]')?.addEventListener("click", () => {
      const now = /* @__PURE__ */ new Date();
      const iso = `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, "0")}-${String(now.getDate()).padStart(2, "0")}`;
      if (this.el.dataset.mode === "datetime") {
        this.trigger.dispatchEvent(new CustomEvent("lantern:set-now"));
      } else {
        this.trigger.dispatchEvent(new CustomEvent("lantern:set-date", { detail: { value: iso } }));
      }
    });
    this.panel?.querySelector('[data-part="clear-panel"]')?.addEventListener("click", () => {
      this.trigger.dispatchEvent(new CustomEvent("lantern:clear"));
    });
    this.panel?.querySelector('[data-part="done"]')?.addEventListener("click", () => this.hide());
  },
  show() {
    this.open = true;
    this.panel.hidden = false;
    this.cleanup.push(trackPosition(this.toggle, this.panel, { placement: "bottom-end", gap: 6 }));
    this.toggle.setAttribute("aria-expanded", "true");
    this.cleanup.push(onDismiss(this.panel, () => this.hide(), { anchor: this.el }));
    this.panel.querySelector('.lui-cal-day[tabindex="0"]')?.focus();
  },
  hide() {
    if (!this.open) return;
    this.open = false;
    this.cleanup.forEach((fn) => fn());
    this.cleanup = [];
    this.panel.hidden = true;
    this.toggle.setAttribute("aria-expanded", "false");
    this.toggle.focus();
  },
  destroyed() {
    this.cleanup.forEach((fn) => fn());
  }
};
var MOBILE_NAV_MQ = "(min-width: 769px)";
var LanternSidebar = {
  key() {
    return `lui-sidebar:${this.el.id}`;
  },
  mounted() {
    this.navOpen = false;
    this.syncCollapsed();
    this.onClick = (e) => {
      if (e.target.closest('[data-part="sidebar-collapse"]')) {
        return this.setCollapsed(!this.el.hasAttribute("data-collapsed"));
      }
      if (e.target.closest('[data-part="sidebar-toggle"]')) return this.setNav(!this.navOpen);
      if (e.target.closest('[data-part="sidebar-scrim"]')) return this.setNav(false);
      const disclosure = e.target.closest('[data-part="nav-disclosure"]');
      if (disclosure) {
        if (!this.el.hasAttribute("data-collapsed")) return;
        e.stopPropagation();
        this.setCollapsed(false);
        disclosure.setAttribute("data-expanded", "");
        disclosure.setAttribute("aria-expanded", "true");
        return;
      }
      if (e.target.closest('[data-part="sidebar"] .lui-nav-item')) this.setNav(false);
    };
    this.el.addEventListener("click", this.onClick);
    this.onKey = (e) => e.key === "Escape" && this.setNav(false);
    document.addEventListener("keydown", this.onKey);
    this.mq = window.matchMedia(MOBILE_NAV_MQ);
    this.onMq = () => this.mq.matches && this.setNav(false);
    this.mq.addEventListener("change", this.onMq);
  },
  setCollapsed(collapsed) {
    this.el.toggleAttribute("data-collapsed", collapsed);
    try {
      localStorage.setItem(this.key(), String(collapsed));
    } catch (_) {
    }
  },
  setNav(open) {
    if (this.navOpen === open) return;
    this.navOpen = open;
    this.el.toggleAttribute("data-nav-open", open);
    const btn = this.el.querySelector('[data-part="sidebar-toggle"]');
    if (btn) btn.setAttribute("aria-expanded", String(open));
    document.body.style.overflow = open ? "hidden" : "";
  },
  syncCollapsed() {
    const stored = localStorage.getItem(this.key());
    if (stored === "true") this.el.setAttribute("data-collapsed", "");
    if (stored === "false") this.el.removeAttribute("data-collapsed");
  },
  updated() {
    this.syncCollapsed();
    this.el.toggleAttribute("data-nav-open", this.navOpen);
  },
  destroyed() {
    this.el.removeEventListener("click", this.onClick);
    document.removeEventListener("keydown", this.onKey);
    this.mq.removeEventListener("change", this.onMq);
    if (this.navOpen) document.body.style.overflow = "";
  }
};
var LanternSelect = {
  mounted() {
    this.toggle = this.el.querySelector('[data-part="toggle"]');
    this.panel = this.el.querySelector('[data-part="panel"]');
    this.native = this.el.querySelector('[data-part="native"]');
    this.label = this.el.querySelector('[data-part="label"]');
    this.search = this.el.querySelector('[data-part="search-input"]');
    this.noResults = this.el.querySelector('[data-part="no-results"]');
    this.multiple = this.el.hasAttribute("data-multiple");
    this.max = parseInt(this.el.dataset.max || "0", 10) || null;
    this.cleanup = [];
    this.open = false;
    this.el.addEventListener("click", (e) => {
      if (e.target.closest('[data-part="clear"]')) {
        e.stopPropagation();
        this.clear();
        return;
      }
      if (e.target.closest('[data-part="toggle"]')) this.open ? this.hide() : this.show();
      const opt = e.target.closest('[data-part="option"]');
      if (opt) this.select(opt);
    });
    this.el.addEventListener("keydown", (e) => this.onKey(e));
    if (this.search) {
      this.search.addEventListener("input", () => this.filter());
    }
  },
  options(visibleOnly = false) {
    const all = [...this.el.querySelectorAll('[data-part="option"]')];
    return visibleOnly ? all.filter((o) => !o.hidden) : all;
  },
  values() {
    return this.native ? [...this.native.selectedOptions].map((o) => o.value).filter((v) => v !== "") : [];
  },
  // Reflect the chosen values onto the hidden native <select> (the real form
  // control) and fire input+change so LiveView — and LiveViewTest's form/3 —
  // see them. Mirrors Fluxon, which drives a hidden <select> from its custom UI.
  setNative(values) {
    if (!this.native) return;
    const set = new Set(values.map(String));
    let changed = false;
    for (const opt of this.native.options) {
      const sel = set.has(opt.value);
      if (opt.selected !== sel) {
        opt.selected = sel;
        changed = true;
      }
    }
    if (changed) {
      this.native.dispatchEvent(new Event("input", { bubbles: true }));
      this.native.dispatchEvent(new Event("change", { bubbles: true }));
    }
  },
  show() {
    this.open = true;
    this.panel.hidden = false;
    this.cleanup.push(trackPosition(this.toggle, this.panel, { placement: "bottom-start" }));
    this.panel.style.minWidth = `${this.toggle.offsetWidth}px`;
    this.toggle.setAttribute("aria-expanded", "true");
    if (this.search) {
      this.search.value = "";
      this.filter();
      this.search.focus();
    } else {
      const current = this.options().find((o) => o.getAttribute("aria-selected") === "true") || this.options()[0];
      current?.focus();
    }
    this.cleanup.push(onDismiss(this.panel, () => this.hide(), { anchor: this.toggle }));
  },
  hide(refocus = true) {
    if (!this.open) return;
    this.open = false;
    this.cleanup.forEach((fn) => fn());
    this.cleanup = [];
    this.panel.hidden = true;
    this.toggle.setAttribute("aria-expanded", "false");
    if (refocus) this.toggle.focus();
  },
  filter() {
    const q = (this.search?.value || "").trim().toLowerCase();
    let any = false;
    this.options().forEach((o) => {
      const hit = q === "" || o.textContent.trim().toLowerCase().includes(q);
      o.hidden = !hit;
      any = any || hit;
    });
    if (this.noResults) this.noResults.hidden = any;
  },
  select(opt) {
    const value = opt.dataset.value;
    if (this.multiple) {
      const selected = opt.getAttribute("aria-selected") === "true";
      if (!selected && this.max && this.values().length >= this.max) return;
      opt.setAttribute("aria-selected", String(!selected));
      this.syncMultiple();
    } else {
      this.setNative([value]);
      this.options().forEach((o) => o.setAttribute("aria-selected", String(o === opt)));
      this.setLabel(opt.querySelector(".lui-select-option-label")?.textContent.trim());
      this.hide();
    }
  },
  syncMultiple() {
    const picked = this.options().filter((o) => o.getAttribute("aria-selected") === "true");
    this.setNative(picked.map((o) => o.dataset.value));
    const labels = picked.map(
      (o) => o.querySelector(".lui-select-option-label")?.textContent.trim()
    );
    this.setLabel(
      labels.length === 0 ? null : labels.length === 1 ? labels[0] : `${labels.length} selected`
    );
  },
  clear() {
    this.setNative([]);
    this.options().forEach((o) => o.setAttribute("aria-selected", "false"));
    this.setLabel(null);
    const clearBtn = this.el.querySelector('[data-part="clear"]');
    if (clearBtn) clearBtn.style.display = "none";
    if (this.open) this.hide();
  },
  setLabel(text) {
    if (!this.label) return;
    if (text) {
      this.label.textContent = text;
      this.label.removeAttribute("data-empty");
    } else {
      this.label.textContent = this.label.dataset.placeholder || "";
      this.label.setAttribute("data-empty", "");
    }
  },
  onKey(e) {
    const opts = this.options(true);
    if (!this.open) {
      if (["ArrowDown", "Enter", " "].includes(e.key) && e.target === this.toggle) {
        e.preventDefault();
        this.show();
      }
      return;
    }
    const idx = opts.indexOf(document.activeElement);
    if (e.key === "ArrowDown") {
      e.preventDefault();
      opts[Math.min(idx + 1, opts.length - 1)]?.focus();
    } else if (e.key === "ArrowUp") {
      e.preventDefault();
      if (idx <= 0 && this.search) this.search.focus();
      else opts[Math.max(idx - 1, 0)]?.focus();
    } else if (e.key === "Home") {
      e.preventDefault();
      opts[0]?.focus();
    } else if (e.key === "End") {
      e.preventDefault();
      opts[opts.length - 1]?.focus();
    } else if (e.key === "Enter" || e.key === " " && e.target !== this.search) {
      e.preventDefault();
      if (idx >= 0) this.select(opts[idx]);
      else if (this.search && e.key === "Enter" && opts[0]) this.select(opts[0]);
    } else if (e.key.length === 1 && /\S/.test(e.key) && e.target !== this.search) {
      const q = e.key.toLowerCase();
      const start = idx + 1;
      const hit = opts.slice(start).find((o) => o.textContent.trim().toLowerCase().startsWith(q)) || opts.find((o) => o.textContent.trim().toLowerCase().startsWith(q));
      hit?.focus();
    }
  },
  destroyed() {
    this.cleanup.forEach((fn) => fn());
  }
};
var LanternAutocomplete = {
  mounted() {
    this.open = false;
    this.activeIndex = -1;
    this.loading = false;
    this.dismissRelease = null;
    this.positionStop = null;
    this.pendingSearch = null;
    this.inFlightSearches = [];
    this.searchSequence = 0;
    this.captureElements();
    this.onClick = (e) => {
      const clear = e.target.closest('[data-part="clear"]');
      if (clear) {
        e.preventDefault();
        e.stopPropagation();
        this.clear();
        return;
      }
      const opt = e.target.closest('[data-part="option"]');
      if (opt) {
        this.select(opt);
        return;
      }
      if (!this.input?.disabled && e.target.closest(".lui-autocomplete-control")) {
        this.input.focus();
        this.show();
      }
    };
    this.onInput = (e) => {
      if (e.target !== this.input || this.input.disabled) return;
      this.activeIndex = -1;
      this.show();
      this.search();
    };
    this.onFocus = (e) => {
      if (e.target === this.input && this.el.dataset.openOnFocus === "true") this.show();
    };
    this.onKeydown = (e) => this.onKey(e);
    this.el.addEventListener("click", this.onClick);
    this.el.addEventListener("input", this.onInput);
    this.el.addEventListener("focusin", this.onFocus);
    this.el.addEventListener("keydown", this.onKeydown);
    this.updateResults();
  },
  captureElements() {
    this.input = this.el.querySelector('[data-part="input"]');
    this.hidden = this.el.querySelector('[data-part="value"]');
    this.control = this.el.querySelector(".lui-autocomplete-control");
    this.panel = this.el.querySelector('[data-part="panel"]');
    this.resultsContainer = this.el.querySelector('[data-part="options"]');
    this.loadingEl = this.el.querySelector('[data-part="loading"]');
    this.noResults = this.el.querySelector('[data-part="no-results"]');
    this.clearButton = this.el.querySelector('[data-part="clear"]');
  },
  resultSignature() {
    return JSON.stringify({
      options: this.options().map((option) => [
        option.id,
        option.dataset.value,
        this.optionLabel(option),
        option.getAttribute("aria-selected")
      ]),
      groups: [...this.el.querySelectorAll('[data-part="group"]')].map((group) => [
        group.dataset.depth,
        group.textContent.trim()
      ]),
      empty: this.noResults?.textContent.trim() || ""
    });
  },
  beforeUpdate() {
    this.patchState = {
      activeValue: this.activeOption()?.dataset.value,
      focused: document.activeElement === this.input,
      hiddenValue: this.hidden?.value || "",
      inputValue: this.input?.value || "",
      selectedLabel: this.selectedLabel(),
      resultsContainer: this.resultsContainer,
      noResults: this.noResults,
      resultSignature: this.resultSignature()
    };
    if (this.open) this.releaseDismissal();
  },
  updated() {
    const state = this.patchState || {};
    this.captureElements();
    const resultsPatched = state.resultsContainer !== this.resultsContainer || state.noResults !== this.noResults || state.resultSignature !== this.resultSignature();
    if (resultsPatched && this.inFlightSearches.length > 0) {
      this.inFlightSearches[0].resultsPatched = true;
    }
    if (state.hiddenValue && state.hiddenValue === (this.hidden?.value || "") && !this.selectedOption()) {
      this.retainedValue = state.hiddenValue;
      this.retainedLabel = state.selectedLabel;
    } else if (this.selectedOption()) {
      this.retainedValue = this.hidden.value;
      this.retainedLabel = this.optionLabel(this.selectedOption());
    }
    const pendingQuery = this.pendingSearch?.query;
    if (this.input && pendingQuery != null) this.input.value = pendingQuery;
    else if (state.focused && this.input) this.input.value = state.inputValue;
    else if (this.input && this.retainedValue === (this.hidden?.value || "")) {
      this.input.value = this.retainedLabel || "";
    }
    this.setLoading(this.loading);
    if (this.open) {
      this.panel.hidden = false;
      this.input?.setAttribute("aria-expanded", "true");
      this.positionPanel();
      this.armDismissal();
    }
    this.updateResults();
    const byValue = this.options(true).find((option) => option.dataset.value === state.activeValue);
    if (byValue) this.setActive(this.options(true).indexOf(byValue));
    else this.setActive(Math.min(this.activeIndex, this.options(true).length - 1));
    if (state.focused) this.input?.focus();
  },
  options(visibleOnly = false) {
    const all = [...this.el.querySelectorAll('[data-part="option"]')];
    return visibleOnly ? all.filter((option) => !option.hidden) : all;
  },
  optionLabel(option) {
    return option?.dataset.label || option?.textContent.trim() || "";
  },
  selectedOption() {
    const value = this.hidden?.value || "";
    return this.options().find((option) => option.dataset.value === value);
  },
  selectedLabel() {
    const selected = this.selectedOption();
    if (selected) return this.optionLabel(selected);
    if (this.retainedValue === (this.hidden?.value || "")) return this.retainedLabel || "";
    return "";
  },
  activeOption() {
    return this.options(true)[this.activeIndex];
  },
  positionPanel() {
    if (!this.panel || !this.input) return;
    position(this.control || this.input, this.panel, { placement: "bottom-start" });
    this.panel.style.minWidth = `${(this.control || this.input).offsetWidth}px`;
  },
  armDismissal() {
    this.releaseDismissal();
    if (!this.panel || !this.control) return;
    this.dismissRelease = onDismiss(
      this.panel,
      (reason) => this.hide({ refocus: false, restore: reason === "outside" }),
      { anchor: this.control }
    );
  },
  releaseDismissal() {
    this.dismissRelease?.();
    this.dismissRelease = null;
  },
  show() {
    if (!this.input || !this.panel || this.input.disabled) return;
    if (!this.open) {
      this.open = true;
      this.armDismissal();
      this.positionStop?.();
      this.positionStop = trackPosition(this.control || this.input, this.panel, { placement: "bottom-start" });
    } else if (!this.dismissRelease) {
      this.armDismissal();
    }
    this.panel.hidden = false;
    this.input.setAttribute("aria-expanded", "true");
    this.positionPanel();
    this.updateResults();
  },
  hide({ refocus = true, restore = false } = {}) {
    if (!this.open) return;
    this.open = false;
    this.positionStop?.();
    this.positionStop = null;
    this.releaseDismissal();
    this.panel.hidden = true;
    this.input?.setAttribute("aria-expanded", "false");
    this.setActive(-1);
    if (restore && this.input) this.input.value = this.selectedLabel();
    if (refocus) this.input?.focus();
  },
  search() {
    const query = (this.input?.value || "").trim();
    const threshold = Math.max(0, parseInt(this.el.dataset.searchThreshold || "0", 10));
    clearTimeout(this.searchTimer);
    if (this.input?.disabled) {
      this.pendingSearch = null;
      this.setLoading(false);
      return;
    }
    if (query.length < threshold) {
      this.pendingSearch = null;
      this.setLoading(false);
      this.updateResults();
      return;
    }
    const event = this.el.dataset.serverSearch;
    if (!event) {
      this.pendingSearch = null;
      this.updateResults();
      return;
    }
    const request = { query, token: ++this.searchSequence, phase: "debouncing" };
    this.pendingSearch = request;
    this.setLoading(true);
    const debounce = Math.max(0, parseInt(this.el.dataset.debounce || "200", 10));
    this.searchTimer = setTimeout(() => {
      if (this.input?.disabled || this.pendingSearch?.token !== request.token) return;
      request.phase = "waiting";
      this.inFlightSearches.push(request);
      this.pushEvent(event, { query }, () => {
        setTimeout(() => this.completeSearch(request), 0);
      });
    }, debounce);
  },
  completeSearch(request) {
    this.inFlightSearches = this.inFlightSearches.filter((item) => item.token !== request.token);
    if (this.pendingSearch?.token !== request.token) return;
    this.pendingSearch = null;
    this.setLoading(false);
    this.updateResults();
  },
  matches(label, query) {
    const candidate = label.toLocaleLowerCase();
    const needle = query.toLocaleLowerCase();
    if (this.el.dataset.searchMode === "exact") return candidate === needle;
    if (this.el.dataset.searchMode === "starts-with") return candidate.startsWith(needle);
    return candidate.includes(needle);
  },
  updateResults() {
    if (!this.input) return;
    const query = this.input.value.trim();
    const threshold = Math.max(0, parseInt(this.el.dataset.searchThreshold || "0", 10));
    const server = !!this.el.dataset.serverSearch;
    this.options().forEach((option) => {
      option.hidden = query.length < threshold || !server && !this.matches(this.optionLabel(option), query);
    });
    this.updateGroups();
    const any = this.options(true).length > 0;
    if (this.noResults) {
      this.noResults.hidden = this.loading || query.length < threshold || any;
      if (!this.noResults.hidden && this.noResults.dataset.defaultText !== "false") {
        const template = this.el.dataset.emptyTemplate || "No results";
        if (!this.noResults.querySelector("*")) this.noResults.textContent = template.replaceAll("%{query}", query);
      }
    }
    this.setActive(Math.min(this.activeIndex, this.options(true).length - 1));
  },
  updateGroups() {
    const children = [...this.resultsContainer?.children || []];
    children.forEach((item, index) => {
      if (item.dataset.part !== "group") return;
      const depth = parseInt(item.dataset.depth || "0", 10);
      let any = false;
      for (let i = index + 1; i < children.length; i++) {
        const child = children[i];
        const childDepth = parseInt(child.dataset.depth || "0", 10);
        if (child.dataset.part === "group" && childDepth <= depth) break;
        if (child.dataset.part === "option" && !child.hidden) any = true;
      }
      item.hidden = !any;
    });
  },
  setLoading(loading) {
    this.loading = loading;
    if (this.loadingEl) this.loadingEl.hidden = !loading;
    this.el.toggleAttribute("data-loading", loading);
    if (loading && this.noResults) this.noResults.hidden = true;
  },
  setActive(index) {
    const options = this.options(true);
    this.activeIndex = options.length === 0 ? -1 : Math.max(-1, Math.min(index, options.length - 1));
    options.forEach((option, optionIndex) => option.toggleAttribute("data-active", optionIndex === this.activeIndex));
    const active = options[this.activeIndex];
    if (active) {
      this.input?.setAttribute("aria-activedescendant", active.id);
      active.scrollIntoView?.({ block: "nearest" });
    } else {
      this.input?.removeAttribute("aria-activedescendant");
    }
  },
  select(option) {
    const value = option.dataset.value || "";
    const label = this.optionLabel(option);
    if (this.hidden) {
      this.hidden.value = value;
      this.hidden.dispatchEvent(new Event("input", { bubbles: true }));
      this.hidden.dispatchEvent(new Event("change", { bubbles: true }));
    }
    this.retainedValue = value;
    this.retainedLabel = label;
    this.options().forEach((item) => item.setAttribute("aria-selected", String(item === option)));
    if (this.input) this.input.value = label;
    if (this.clearButton) this.clearButton.hidden = false;
    this.hide();
  },
  clear() {
    clearTimeout(this.searchTimer);
    this.pendingSearch = null;
    this.inFlightSearches = [];
    this.setLoading(false);
    if (this.hidden) {
      this.hidden.value = "";
      this.hidden.dispatchEvent(new Event("input", { bubbles: true }));
      this.hidden.dispatchEvent(new Event("change", { bubbles: true }));
    }
    this.retainedValue = "";
    this.retainedLabel = "";
    this.options().forEach((option) => option.setAttribute("aria-selected", "false"));
    if (this.input) this.input.value = "";
    if (this.clearButton) this.clearButton.hidden = true;
    this.hide();
  },
  onKey(e) {
    if (e.target !== this.input || !this.input || this.input.disabled) return;
    if (e.key === "Escape" && this.open) {
      e.preventDefault();
      e.stopPropagation();
      this.hide({ restore: true });
      return;
    }
    if (!["ArrowDown", "ArrowUp", "Enter"].includes(e.key)) return;
    if (!this.open) this.show();
    const options = this.options(true);
    if (e.key === "ArrowDown") {
      e.preventDefault();
      this.setActive(options.length ? (this.activeIndex + 1) % options.length : -1);
    } else if (e.key === "ArrowUp") {
      e.preventDefault();
      this.setActive(options.length ? this.activeIndex <= 0 ? options.length - 1 : this.activeIndex - 1 : -1);
    } else if (e.key === "Enter" && this.activeOption()) {
      e.preventDefault();
      this.select(this.activeOption());
    }
  },
  destroyed() {
    clearTimeout(this.searchTimer);
    this.positionStop?.();
    this.positionStop = null;
    this.releaseDismissal();
    this.el.removeEventListener("click", this.onClick);
    this.el.removeEventListener("input", this.onInput);
    this.el.removeEventListener("focusin", this.onFocus);
    this.el.removeEventListener("keydown", this.onKeydown);
  }
};
var LanternSlider = {
  mounted() {
    this.input = this.el.querySelector('[data-part="input"]');
    this.track = this.el.querySelector('[data-part="track"]');
    this.thumb = this.el.querySelector('[data-part="thumb"]');
    this.onPointerDown = (e) => this.startDrag(e);
    this.onKeydown = (e) => this.onKey(e);
    this.el.addEventListener("pointerdown", this.onPointerDown);
    this.thumb.addEventListener("keydown", this.onKeydown);
  },
  disabled() {
    return this.el.hasAttribute("data-disabled");
  },
  bounds() {
    const num = (key, fallback) => {
      const v = parseFloat(this.el.dataset[key]);
      return Number.isFinite(v) ? v : fallback;
    };
    const min2 = num("min", 0);
    return { min: min2, max: Math.max(num("max", 100), min2), step: Math.abs(num("step", 1)) || 1 };
  },
  value() {
    const v = parseFloat(this.input.value);
    return Number.isFinite(v) ? v : this.bounds().min;
  },
  // Snap to the step grid (anchored at min), clamp, and kill float drift —
  // min 0 / step 0.1 must yield 0.3, not 0.30000000000000004.
  snap(raw) {
    const { min: min2, max: max2, step } = this.bounds();
    const decimals = (s) => (String(s).split(".")[1] || "").length;
    const places = Math.max(decimals(step), decimals(min2));
    const v = min2 + Math.round((raw - min2) / step) * step;
    return Math.min(max2, Math.max(min2, parseFloat(v.toFixed(places))));
  },
  valueFromPointer(e) {
    const rect = this.track.getBoundingClientRect();
    const { min: min2, max: max2 } = this.bounds();
    const ratio = rect.width === 0 ? 0 : (e.clientX - rect.left) / rect.width;
    return min2 + Math.min(1, Math.max(0, ratio)) * (max2 - min2);
  },
  set(raw, { commit } = {}) {
    const v = this.snap(raw);
    const { min: min2, max: max2 } = this.bounds();
    this.thumb.setAttribute("aria-valuenow", String(v));
    const tpl = this.el.dataset.valueText;
    if (tpl) this.thumb.setAttribute("aria-valuetext", tpl.replace("{value}", String(v)));
    const pct = max2 === min2 ? 0 : (v - min2) / (max2 - min2) * 100;
    this.el.style.setProperty("--lui-slider-pct", `${pct}%`);
    if (commit && this.input.value !== String(v)) {
      this.input.value = String(v);
      this.input.dispatchEvent(new Event("input", { bubbles: true }));
      this.input.dispatchEvent(new Event("change", { bubbles: true }));
    }
  },
  startDrag(e) {
    if (this.disabled() || e.button !== 0) return;
    e.preventDefault();
    this.thumb.focus();
    this.el.setPointerCapture?.(e.pointerId);
    this.set(this.valueFromPointer(e));
    const move = (ev) => this.set(this.valueFromPointer(ev));
    const stop = (ev) => {
      this.el.removeEventListener("pointermove", move);
      this.el.removeEventListener("pointerup", stop);
      this.el.removeEventListener("pointercancel", stop);
      this.set(this.valueFromPointer(ev), { commit: true });
    };
    this.el.addEventListener("pointermove", move);
    this.el.addEventListener("pointerup", stop);
    this.el.addEventListener("pointercancel", stop);
  },
  onKey(e) {
    if (this.disabled()) return;
    const { min: min2, max: max2, step } = this.bounds();
    const cur = this.value();
    let next;
    if (e.key === "ArrowRight" || e.key === "ArrowUp") next = cur + step;
    else if (e.key === "ArrowLeft" || e.key === "ArrowDown") next = cur - step;
    else if (e.key === "Home") next = min2;
    else if (e.key === "End") next = max2;
    else if (e.key === "PageUp") next = cur + step * 10;
    else if (e.key === "PageDown") next = cur - step * 10;
    else return;
    e.preventDefault();
    this.set(next, { commit: true });
  },
  destroyed() {
    this.el.removeEventListener("pointerdown", this.onPointerDown);
    this.thumb.removeEventListener("keydown", this.onKeydown);
  }
};
var LanternCollapse = {
  key() {
    return `lui-collapse:${this.el.id}`;
  },
  restore() {
    const stored = localStorage.getItem(this.key());
    if (stored === "true") this.el.setAttribute("data-collapsed", "");
    if (stored === "false") this.el.removeAttribute("data-collapsed");
  },
  mounted() {
    this.restore();
    this.onClick = (e) => {
      if (!e.target.closest('[data-part="collapse-toggle"]')) return;
      const collapsed = this.el.toggleAttribute("data-collapsed");
      try {
        localStorage.setItem(this.key(), String(collapsed));
      } catch (_) {
      }
    };
    this.el.addEventListener("click", this.onClick);
  },
  // LiveView patches strip client-set attributes — re-apply after every patch.
  updated() {
    this.restore();
  },
  destroyed() {
    this.el.removeEventListener("click", this.onClick);
  }
};
var LanternTableChrome = {
  mounted() {
    this.path = this.el.dataset.path;
    this.onInput = (e) => {
      const t = e.target;
      if (t.matches('[data-part="search"]')) {
        clearTimeout(this.debounce);
        this.debounce = setTimeout(() => this.apply(), 300);
      }
    };
    this.onChange = (e) => {
      if (e.target.matches('[data-part="filter"]') || e.target.closest('[data-part="filter-rich"]'))
        this.apply();
    };
    this.onClick = (e) => {
      if (!e.target.closest('[data-part="clear-filters"]')) return;
      this.suspended = true;
      this.el.querySelectorAll('[data-part="filter"]').forEach((sel) => sel.value = "");
      this.el.querySelectorAll('[data-part="filter-rich"] input[data-part="value"]').forEach((i) => i.remove());
      this.el.querySelectorAll('[data-part="filter-rich"] [data-part="clear"]').forEach((btn) => btn.click());
      this.suspended = false;
      this.apply();
    };
    this.el.addEventListener("input", this.onInput);
    this.el.addEventListener("change", this.onChange);
    this.el.addEventListener("click", this.onClick);
  },
  apply() {
    if (this.suspended) return;
    const base = JSON.parse(this.el.dataset.params || "{}");
    const filters = JSON.parse(this.el.dataset.keepFilters || "[]");
    const search = this.el.querySelector('[data-part="search"]');
    if (search && search.value.trim() !== "") {
      filters.push({ field: search.dataset.field, op: search.dataset.op, value: search.value.trim() });
    }
    this.el.querySelectorAll('[data-part="filter"]').forEach((sel) => {
      if (sel.value !== "") {
        filters.push({ field: sel.dataset.field, op: sel.dataset.op, value: sel.value });
      }
    });
    this.el.querySelectorAll('[data-part="filter-rich"]').forEach((wrap) => {
      const native = wrap.querySelector('select[data-part="native"]');
      const values = native ? [...native.selectedOptions].map((o) => o.value).filter((v) => v !== "") : [...wrap.querySelectorAll('input[data-part="value"]')].map((i) => i.value).filter((v) => v !== "");
      if (values.length === 0) return;
      if (wrap.dataset.op === "in") {
        filters.push({ field: wrap.dataset.field, op: "in", values });
      } else {
        filters.push({ field: wrap.dataset.field, op: wrap.dataset.op, value: values[0] });
      }
    });
    const params = { ...base };
    delete params.page;
    filters.forEach((f, i) => {
      params[`filters[${i}][field]`] = f.field;
      if (f.op && f.op !== "==") params[`filters[${i}][op]`] = f.op;
      if (f.values) params[`filters[${i}][value]`] = f.values;
      else params[`filters[${i}][value]`] = f.value;
    });
    const query = Object.entries(params).flatMap(
      ([k, v]) => Array.isArray(v) ? v.map((item) => `${encodeURIComponent(k)}[]=${encodeURIComponent(item)}`) : [`${encodeURIComponent(k)}=${encodeURIComponent(v)}`]
    ).join("&");
    this.patch(`${this.path}?${query}`);
  },
  patch(url) {
    const a = document.createElement("a");
    a.href = url;
    a.setAttribute("data-phx-link", "patch");
    a.setAttribute("data-phx-link-state", "push");
    a.style.display = "none";
    this.el.appendChild(a);
    a.click();
    a.remove();
  },
  destroyed() {
    clearTimeout(this.debounce);
    this.el.removeEventListener("input", this.onInput);
    this.el.removeEventListener("change", this.onChange);
  }
};
var LanternTheme = {
  mounted() {
    this.key = this.el.dataset.storageKey || "lui-theme";
    try {
      this.config = JSON.parse(localStorage.getItem(this.key) || "null");
    } catch (_) {
      this.config = null;
    }
    this.apply();
    this.onSet = (e) => this.set(e.detail);
    window.addEventListener("lantern:set-theme", this.onSet);
    this.handleEvent("lantern:set-theme", (config) => this.set(config));
  },
  set(config) {
    if (!config || config.reset) {
      this.config = null;
      try {
        localStorage.removeItem(this.key);
      } catch (_) {
      }
    } else {
      this.config = { ...this.config || {}, ...config };
      try {
        localStorage.setItem(this.key, JSON.stringify(this.config));
      } catch (_) {
      }
    }
    this.apply();
  },
  vars(map) {
    return Object.entries(map || {}).map(([k, v]) => `--lantern-${k.replace(/_/g, "-")}: ${v};`).join(" ");
  },
  apply() {
    let styleEl = document.getElementById("lantern-theme-overrides");
    const html = document.documentElement;
    if (!this.config) {
      styleEl?.remove();
      html.removeAttribute("data-lantern-density");
      return;
    }
    if (!styleEl) {
      styleEl = document.createElement("style");
      styleEl.id = "lantern-theme-overrides";
      document.head.appendChild(styleEl);
    }
    const light = { ...this.config.light || {} };
    if (this.config.radius) light.radius = this.config.radius;
    const dark = { ...this.config.dark || {} };
    if (this.config.radius) dark.radius = this.config.radius;
    styleEl.textContent = [
      `:root, .light { ${this.vars(light)} }`,
      `.dark { ${this.vars(dark)} }`,
      `@media (prefers-color-scheme: dark) { :root:not(.light) { ${this.vars(dark)} } }`
    ].join("\n");
    if (this.config.density) html.setAttribute("data-lantern-density", this.config.density);
    else html.removeAttribute("data-lantern-density");
  },
  destroyed() {
    window.removeEventListener("lantern:set-theme", this.onSet);
  }
};
var runtime = { position, trackPosition, trapFocus, onDismiss, installBehaviours };
var LanternModal = {
  // The SERVER owns `open` for this overlay: the component renders
  // `data-open={@open || nil}` and `hidden={!@open}` from an assign. Without
  // this, the hook only ever learns about opening in `mounted()`, so a sheet
  // opened by a LiveView patch leaves `this.open === false` — and `hide()`
  // starts with `if (!this.open) return`, so the close button, Escape, and the
  // backdrop ALL silently no-op. The overlay is visible and unclosable.
  //
  // Follow the DOM rather than assert over it (the opposite of LanternCommand,
  // where the hook owns the state and re-asserts `hidden`).
  updated() {
    const wantOpen = this.el.dataset.open != null;
    if (wantOpen === this.open) return;
    if (wantOpen) {
      this.show();
      return;
    }
    this.open = false;
    this.cleanup.forEach((fn) => fn());
    this.cleanup = [];
    document.body.style.overflow = "";
    clearTimeout(this.closeTimer);
    this.el.hidden = true;
    this.el.removeAttribute("data-closing");
  },
  mounted() {
    this.panel = this.el.querySelector('[data-part="panel"]');
    this.cleanup = [];
    this.el.addEventListener("lantern:dialog:open", () => this.show());
    this.el.addEventListener("lantern:dialog:close", () => this.hide());
    this.handleEvent("lantern:dialog:open", ({ id }) => id === this.el.id && this.show());
    this.handleEvent("lantern:dialog:close", ({ id }) => id === this.el.id && this.hide());
    this.el.querySelectorAll('[data-part="close"]').forEach(
      (btn) => btn.addEventListener("click", () => this.hide())
    );
    if (this.el.dataset.open != null) this.show();
  },
  show() {
    if (this.open) return;
    this.open = true;
    this.el.hidden = false;
    document.body.style.overflow = "hidden";
    this.cleanup.push(trapFocus(this.panel, this.el.dataset.initialFocus));
    const esc2 = this.el.dataset.closeOnEsc === "true";
    const outside = this.el.dataset.closeOnOutside === "true";
    this.cleanup.push(
      onDismiss(this.panel, (reason) => {
        if (reason === "escape" && !esc2) return;
        if (reason === "outside" && !outside) return;
        this.hide();
      })
    );
  },
  hide() {
    if (!this.open) return;
    this.open = false;
    this.cleanup.forEach((fn) => fn());
    this.cleanup = [];
    this.el.hidden = true;
    document.body.style.overflow = "";
  },
  destroyed() {
    this.cleanup.forEach((fn) => fn());
    document.body.style.overflow = "";
  }
};
var LanternCommand = {
  mounted() {
    this.open = false;
    this.activeIndex = -1;
    this.cleanup = [];
    this.capture();
    this.onClick = (e) => {
      const item = e.target.closest('[data-part="item"]');
      if (item && !item.disabled && this.el.contains(item)) this.select(item);
    };
    this.onInput = (e) => {
      if (e.target !== this.input) return;
      this.activeIndex = -1;
      this.search();
    };
    this.onKeydown = (e) => this.onKey(e);
    this.onHotkey = (e) => {
      const key = this.el.dataset.hotkey;
      if (!key || e.key.toLowerCase() !== key.toLowerCase()) return;
      if (!e.metaKey && !e.ctrlKey) return;
      e.preventDefault();
      this.open ? this.hide() : this.show();
    };
    this.el.addEventListener("click", this.onClick);
    this.el.addEventListener("input", this.onInput);
    this.el.addEventListener("keydown", this.onKeydown);
    document.addEventListener("keydown", this.onHotkey);
    this.el.addEventListener("lantern:dialog:open", () => this.show());
    this.el.addEventListener("lantern:dialog:close", () => this.hide());
    this.handleEvent("lantern:dialog:open", ({ id }) => id === this.el.id && this.show());
    this.handleEvent("lantern:dialog:close", ({ id }) => id === this.el.id && this.hide());
    this.el.querySelectorAll('[data-part="close"]').forEach(
      (btn) => btn.addEventListener("click", () => this.hide())
    );
    this.syncEmpty();
    if (this.el.dataset.open != null) this.show();
  },
  capture() {
    this.panel = this.el.querySelector('[data-part="panel"]');
    this.input = this.el.querySelector('[data-part="input"]');
    this.list = this.el.querySelector('[data-part="list"]');
    this.emptyEl = this.el.querySelector('[data-part="empty"]');
  },
  beforeUpdate() {
    this.patchState = {
      activeValue: this.items()[this.activeIndex]?.dataset.value,
      focused: document.activeElement === this.input,
      query: this.input?.value || ""
    };
  },
  updated() {
    const state = this.patchState || {};
    this.capture();
    this.el.hidden = !this.open;
    if (this.input && this.input.value !== state.query) this.input.value = state.query;
    this.syncEmpty();
    const byValue = this.items().findIndex((i) => i.dataset.value === state.activeValue);
    this.setActive(byValue >= 0 ? byValue : Math.min(this.activeIndex, this.items().length - 1));
    if (state.focused && this.open) this.input?.focus();
  },
  // pushEvent goes to the parent LiveView. When the palette is rendered from a
  // LiveComponent that is the wrong target — the parent would have to define
  // handlers it does not own — so route to the component when data-target is
  // present.
  //
  // Keep this name distinct from every other method on the hook. An object
  // literal silently keeps only the LAST definition of a duplicated key, so a
  // second `push` further down shadowed this router entirely: the LiveComponent
  // routing became dead code and the surviving method recursed into itself on
  // every keystroke.
  pushTo(event, payload) {
    const target = this.el.dataset.target;
    if (target) {
      this.pushEventTo(target, event, payload);
    } else {
      this.pushEvent(event, payload);
    }
  },
  items() {
    return [...this.el.querySelectorAll('[data-part="item"]')].filter((i) => !i.disabled);
  },
  // Visibility only, never filtering: an explicit empty state must not sit
  // alongside results when a patch races the consumer's own `:if`.
  syncEmpty() {
    if (this.emptyEl) this.emptyEl.hidden = this.items().length > 0;
  },
  show() {
    if (this.open) return;
    this.open = true;
    this.el.hidden = false;
    document.body.style.overflow = "hidden";
    if (this.input) this.input.value = "";
    this.setActive(-1);
    this.cleanup.push(trapFocus(this.panel, '[data-part="input"]'));
    const esc2 = this.el.dataset.closeOnEsc === "true";
    const outside = this.el.dataset.closeOnOutside === "true";
    this.cleanup.push(
      onDismiss(this.panel, (reason) => {
        if (reason === "escape" && !esc2) return;
        if (reason === "outside" && !outside) return;
        this.hide();
      })
    );
    if (this.el.dataset.searchOnOpen === "true") this.pushSearch();
  },
  hide() {
    if (!this.open) return;
    this.open = false;
    clearTimeout(this.searchTimer);
    this.cleanup.forEach((fn) => fn());
    this.cleanup = [];
    this.setActive(-1);
    this.el.hidden = true;
    document.body.style.overflow = "";
  },
  search() {
    clearTimeout(this.searchTimer);
    const debounce = Math.max(0, parseInt(this.el.dataset.debounce || "200", 10));
    this.searchTimer = setTimeout(() => this.pushSearch(), debounce);
  },
  pushSearch() {
    const event = this.el.dataset.onSearch;
    if (!event) return;
    this.pushTo(event, { query: (this.input?.value || "").trim() });
  },
  select(item) {
    const event = this.el.dataset.onSelect;
    if (event && !item.hasAttribute("phx-click")) {
      this.pushTo(event, { value: item.dataset.value ?? null });
    }
    if (this.el.dataset.closeOnSelect === "true") this.hide();
  },
  setActive(index) {
    const items = this.items();
    this.activeIndex = items.length === 0 ? -1 : Math.max(-1, Math.min(index, items.length - 1));
    items.forEach((item, i) => {
      const active2 = i === this.activeIndex;
      item.toggleAttribute("data-active", active2);
      item.setAttribute("aria-selected", active2 ? "true" : "false");
    });
    const active = items[this.activeIndex];
    if (active) {
      this.input?.setAttribute("aria-activedescendant", active.id);
      active.scrollIntoView({ block: "nearest" });
    } else {
      this.input?.removeAttribute("aria-activedescendant");
    }
  },
  onKey(e) {
    if (!this.open) return;
    const items = this.items();
    switch (e.key) {
      case "ArrowDown":
        e.preventDefault();
        this.setActive(this.activeIndex + 1 >= items.length ? 0 : this.activeIndex + 1);
        break;
      case "ArrowUp":
        e.preventDefault();
        this.setActive(this.activeIndex <= 0 ? items.length - 1 : this.activeIndex - 1);
        break;
      case "Home":
        e.preventDefault();
        this.setActive(0);
        break;
      case "End":
        e.preventDefault();
        this.setActive(items.length - 1);
        break;
      case "Enter": {
        const active = items[this.activeIndex];
        if (!active) return;
        e.preventDefault();
        active.click();
        break;
      }
    }
  },
  destroyed() {
    clearTimeout(this.searchTimer);
    this.cleanup.forEach((fn) => fn());
    document.removeEventListener("keydown", this.onHotkey);
    document.body.style.overflow = "";
  }
};
var LanternSheet = {
  // The SERVER owns `open` for this overlay: the component renders
  // `data-open={@open || nil}` and `hidden={!@open}` from an assign. Without
  // this, the hook only ever learns about opening in `mounted()`, so a sheet
  // opened by a LiveView patch leaves `this.open === false` — and `hide()`
  // starts with `if (!this.open) return`, so the close button, Escape, and the
  // backdrop ALL silently no-op. The overlay is visible and unclosable.
  //
  // Follow the DOM rather than assert over it (the opposite of LanternCommand,
  // where the hook owns the state and re-asserts `hidden`).
  updated() {
    const wantOpen = this.el.dataset.open != null;
    if (wantOpen === this.open) return;
    if (wantOpen) {
      this.show();
      return;
    }
    this.open = false;
    this.cleanup.forEach((fn) => fn());
    this.cleanup = [];
    document.body.style.overflow = "";
    clearTimeout(this.closeTimer);
    this.el.hidden = true;
    this.el.removeAttribute("data-closing");
  },
  mounted() {
    this.panel = this.el.querySelector('[data-part="panel"]');
    this.cleanup = [];
    this.el.addEventListener("lantern:dialog:open", () => this.show());
    this.el.addEventListener("lantern:dialog:close", () => this.hide());
    this.handleEvent("lantern:dialog:open", ({ id }) => id === this.el.id && this.show());
    this.handleEvent("lantern:dialog:close", ({ id }) => id === this.el.id && this.hide());
    this.el.querySelectorAll('[data-part="close"]').forEach(
      (btn) => btn.addEventListener("click", () => this.hide())
    );
    if (this.el.dataset.open != null) this.show();
  },
  show() {
    if (this.open) return;
    this.open = true;
    clearTimeout(this.closeTimer);
    this.el.removeAttribute("data-closing");
    this.el.hidden = false;
    document.body.style.overflow = "hidden";
    this.cleanup.push(trapFocus(this.panel));
    const esc2 = this.el.dataset.closeOnEsc === "true";
    const outside = this.el.dataset.closeOnOutside === "true";
    this.cleanup.push(
      onDismiss(this.panel, (reason) => {
        if (reason === "escape" && !esc2) return;
        if (reason === "outside" && !outside) return;
        this.hide();
      })
    );
  },
  hide() {
    if (!this.open) return;
    this.open = false;
    this.cleanup.forEach((fn) => fn());
    this.cleanup = [];
    document.body.style.overflow = "";
    if (this.el.dataset.onClose) this.liveSocket.execJS(this.el, this.el.dataset.onClose);
    const reduce = window.matchMedia("(prefers-reduced-motion: reduce)").matches;
    if (reduce) {
      this.el.hidden = true;
      return;
    }
    this.el.setAttribute("data-closing", "");
    this.closeTimer = setTimeout(() => {
      this.el.hidden = true;
      this.el.removeAttribute("data-closing");
    }, 200);
  },
  destroyed() {
    this.cleanup.forEach((fn) => fn());
    clearTimeout(this.closeTimer);
    document.body.style.overflow = "";
  }
};
var LanternDropdown = {
  mounted() {
    this.trigger = this.el.querySelector('[data-part="trigger"]');
    this.panel = this.el.querySelector('[data-part="panel"]');
    if (!this.trigger || !this.panel) return;
    this.open = false;
    this.cleanup = [];
    this.trigger.addEventListener("click", () => this.open ? this.hide() : this.show());
    this.trigger.addEventListener("keydown", (e) => {
      if ((e.key === "ArrowDown" || e.key === "Enter") && !this.open) {
        e.preventDefault();
        this.show();
      }
    });
    this.panel.addEventListener("click", (e) => {
      if (e.target.closest('[role="menuitem"]')) this.hide();
    });
    this.panel.addEventListener("keydown", (e) => {
      const items = this.items();
      if (items.length === 0) return;
      const idx = items.indexOf(document.activeElement);
      if (e.key === "ArrowDown") {
        e.preventDefault();
        items[Math.min(idx + 1, items.length - 1)].focus();
      } else if (e.key === "ArrowUp") {
        e.preventDefault();
        items[Math.max(idx - 1, 0)].focus();
      } else if (e.key === "Home") {
        e.preventDefault();
        items[0].focus();
      } else if (e.key === "End") {
        e.preventDefault();
        items[items.length - 1].focus();
      }
    });
  },
  items() {
    return [...this.panel.querySelectorAll('[role="menuitem"]:not([disabled]):not([data-disabled])')];
  },
  show() {
    this.open = true;
    this.panel.hidden = false;
    this.cleanup.push(trackPosition(this.trigger, this.panel, { placement: this.el.dataset.placement }));
    this.trigger.querySelector("[aria-haspopup]")?.setAttribute("aria-expanded", "true");
    const first = this.items()[0];
    if (first) first.focus();
    this.cleanup.push(onDismiss(this.panel, () => this.hide(), { anchor: this.trigger }));
  },
  hide() {
    if (!this.open) return;
    this.open = false;
    this.cleanup.forEach((fn) => fn());
    this.cleanup = [];
    this.panel.hidden = true;
    this.trigger.querySelector("[aria-haspopup]")?.setAttribute("aria-expanded", "false");
  },
  destroyed() {
    this.cleanup.forEach((fn) => fn());
  }
};
var menuItems = (menu) => [...menu.querySelectorAll('[role="menuitem"]:not([disabled]):not([data-disabled])')];
var rove = (items, target) => {
  items.forEach((el) => el.setAttribute("tabindex", el === target ? "0" : "-1"));
  target.focus();
};
var menuNav = (key, items) => {
  const idx = items.indexOf(document.activeElement);
  switch (key) {
    case "ArrowDown":
      return items[(idx + 1) % items.length];
    case "ArrowUp":
      return items[(idx - 1 + items.length) % items.length];
    case "Home":
      return items[0];
    case "End":
      return items[items.length - 1];
    default:
      return null;
  }
};
var LanternMenu = {
  mounted() {
    this.trigger = this.el.querySelector('[data-part="trigger"]');
    this.menu = this.el.querySelector('[data-part="menu"]');
    if (!this.trigger || !this.menu) return;
    this.open = false;
    this.cleanup = [];
    this.trigger.addEventListener("click", () => this.open ? this.hide() : this.show());
    this.trigger.addEventListener("keydown", (e) => {
      if (this.open) return;
      if (e.key === "ArrowDown" || e.key === "ArrowUp") {
        e.preventDefault();
        this.show(e.key === "ArrowUp" ? "last" : "first");
      }
    });
    this.menu.addEventListener("click", (e) => {
      if (e.target.closest('[role="menuitem"]')) {
        this.hide();
        this.trigger.focus();
      }
    });
    this.menu.addEventListener("keydown", (e) => {
      const items = menuItems(this.menu);
      if (items.length === 0) return;
      const next = menuNav(e.key, items);
      if (next) {
        e.preventDefault();
        rove(items, next);
      } else if (e.key === "Tab") {
        this.hide();
      }
    });
  },
  show(focusTarget = "first") {
    this.open = true;
    this.menu.hidden = false;
    this.cleanup.push(trackPosition(this.trigger, this.menu, { placement: this.el.dataset.placement }));
    this.trigger.setAttribute("aria-expanded", "true");
    const items = menuItems(this.menu);
    const target = focusTarget === "last" ? items[items.length - 1] : items[0];
    if (target) rove(items, target);
    this.cleanup.push(
      onDismiss(
        this.menu,
        (reason) => {
          this.hide();
          if (reason === "escape") this.trigger.focus();
        },
        { anchor: this.trigger }
      )
    );
  },
  hide() {
    if (!this.open) return;
    this.open = false;
    this.cleanup.forEach((fn) => fn());
    this.cleanup = [];
    this.menu.hidden = true;
    this.trigger.setAttribute("aria-expanded", "false");
  },
  destroyed() {
    this.cleanup.forEach((fn) => fn());
  }
};
var LanternMenubar = {
  mounted() {
    this.openTrigger = null;
    this.cleanup = [];
    const triggers = this.triggers();
    triggers.forEach((t, i) => t.setAttribute("tabindex", i === 0 ? "0" : "-1"));
    this.el.addEventListener("click", (e) => {
      const trigger = e.target.closest('[data-part="trigger"]');
      if (trigger) {
        this.openTrigger === trigger ? this.close() : this.openMenu(trigger);
      } else if (e.target.closest('[role="menuitem"]')) {
        const opener = this.openTrigger;
        this.close();
        if (opener) opener.focus();
      }
    });
    this.el.addEventListener("keydown", (e) => {
      const triggers2 = this.triggers();
      const onTrigger = e.target.closest('[data-part="trigger"]');
      if (onTrigger) {
        let next2 = null;
        const idx = triggers2.indexOf(onTrigger);
        if (e.key === "ArrowRight") next2 = triggers2[(idx + 1) % triggers2.length];
        else if (e.key === "ArrowLeft") next2 = triggers2[(idx - 1 + triggers2.length) % triggers2.length];
        else if (e.key === "Home") next2 = triggers2[0];
        else if (e.key === "End") next2 = triggers2[triggers2.length - 1];
        else if (e.key === "ArrowDown" || e.key === "ArrowUp") {
          e.preventDefault();
          this.openMenu(onTrigger, e.key === "ArrowUp" ? "last" : "first");
          return;
        }
        if (next2) {
          e.preventDefault();
          const wasOpen = this.openTrigger !== null;
          rove(triggers2, next2);
          if (wasOpen) this.openMenu(next2);
        }
        return;
      }
      const menu = e.target.closest('[data-part="menu"]');
      if (!menu || !this.openTrigger) return;
      const items = menuItems(menu);
      const next = items.length > 0 && menuNav(e.key, items);
      if (next) {
        e.preventDefault();
        rove(items, next);
      } else if (e.key === "ArrowRight" || e.key === "ArrowLeft") {
        e.preventDefault();
        const dir = e.key === "ArrowRight" ? 1 : -1;
        const idx = triggers2.indexOf(this.openTrigger);
        const adjacent = triggers2[(idx + dir + triggers2.length) % triggers2.length];
        rove(triggers2, adjacent);
        this.openMenu(adjacent);
      } else if (e.key === "Tab") {
        this.close();
      }
    });
  },
  triggers() {
    return [...this.el.querySelectorAll('[data-part="trigger"]:not([disabled])')];
  },
  menuFor(trigger) {
    return document.getElementById(trigger.getAttribute("aria-controls"));
  },
  openMenu(trigger, focusTarget = "first") {
    this.close();
    const menu = this.menuFor(trigger);
    if (!menu) return;
    this.openTrigger = trigger;
    rove(this.triggers(), trigger);
    menu.hidden = false;
    this.cleanup.push(trackPosition(trigger, menu, { placement: "bottom-start" }));
    trigger.setAttribute("aria-expanded", "true");
    const items = menuItems(menu);
    const target = focusTarget === "last" ? items[items.length - 1] : items[0];
    if (target) rove(items, target);
    this.cleanup.push(
      onDismiss(
        menu,
        (reason) => {
          this.close();
          if (reason === "escape") rove(this.triggers(), trigger);
        },
        { anchor: trigger }
      )
    );
  },
  close() {
    if (!this.openTrigger) return;
    const menu = this.menuFor(this.openTrigger);
    this.cleanup.forEach((fn) => fn());
    this.cleanup = [];
    if (menu) menu.hidden = true;
    this.openTrigger.setAttribute("aria-expanded", "false");
    this.openTrigger = null;
  },
  destroyed() {
    this.cleanup.forEach((fn) => fn());
  }
};
var LanternTooltip = {
  mounted() {
    this.trigger = this.el.querySelector('[data-part="trigger"]');
    this.panel = this.el.querySelector('[data-part="panel"]');
    if (!this.trigger || !this.panel) return;
    this.open = false;
    this.delay = parseInt(this.el.dataset.delay || "200", 10);
    this.onEnter = () => this.scheduleShow();
    this.onLeave = () => this.hide();
    this.onFocusOut = (e) => {
      if (!this.trigger.contains(e.relatedTarget)) this.hide();
    };
    this.onKey = (e) => {
      if (e.key === "Escape") this.hide();
    };
    this.trigger.addEventListener("mouseenter", this.onEnter);
    this.trigger.addEventListener("focusin", this.onEnter);
    this.trigger.addEventListener("mouseleave", this.onLeave);
    this.trigger.addEventListener("focusout", this.onFocusOut);
    document.addEventListener("keydown", this.onKey);
  },
  scheduleShow() {
    clearTimeout(this.timer);
    this.timer = setTimeout(() => this.show(), this.delay);
  },
  show() {
    clearTimeout(this.timer);
    if (!this.open) {
      this.open = true;
      this.panel.hidden = false;
      this.stopTrack = canFloat() ? autoUpdate(this.trigger, this.panel, () => this.place()) : () => {
      };
    }
    this.place();
  },
  hide() {
    clearTimeout(this.timer);
    if (!this.open) return;
    this.open = false;
    this.panel.hidden = true;
    this.stopTrack?.();
    this.stopTrack = null;
  },
  place() {
    const placement = this.el.dataset.placement || "top";
    if (placement === "left" || placement === "right") {
      this.placeSide(placement);
    } else {
      position(this.trigger, this.panel, { placement: `${placement}-start`, gap: 6 }).then((chosen) => {
        this.centerHorizontal(String(chosen || placement).split("-")[0]);
      });
    }
  },
  centerHorizontal(side) {
    const a = this.trigger.getBoundingClientRect();
    const f = this.panel.getBoundingClientRect();
    const vw = document.documentElement.clientWidth;
    const left = Math.min(Math.max(a.left + (a.width - f.width) / 2, 8), vw - f.width - 8);
    this.panel.style.left = `${left}px`;
    this.panel.dataset.placement = side;
    this.panel.style.setProperty("--lui-tooltip-arrow-x", `${a.left + a.width / 2 - left}px`);
    this.panel.style.removeProperty("--lui-tooltip-arrow-y");
  },
  placeSide(preferred) {
    const gap = 6;
    const a = this.trigger.getBoundingClientRect();
    const f = this.panel.getBoundingClientRect();
    const vw = document.documentElement.clientWidth;
    const vh = document.documentElement.clientHeight;
    const fitsLeft = a.left - gap - f.width >= 8;
    const fitsRight = a.right + gap + f.width <= vw - 8;
    let side = preferred;
    if (side === "left" && !fitsLeft && fitsRight) side = "right";
    if (side === "right" && !fitsRight && fitsLeft) side = "left";
    let left = side === "left" ? a.left - gap - f.width : a.right + gap;
    let top = a.top + (a.height - f.height) / 2;
    left = Math.min(Math.max(left, 8), vw - f.width - 8);
    top = Math.min(Math.max(top, 8), vh - f.height - 8);
    this.panel.style.position = "fixed";
    this.panel.style.left = `${left}px`;
    this.panel.style.top = `${top}px`;
    this.panel.dataset.placement = side;
    this.panel.style.setProperty("--lui-tooltip-arrow-y", `${a.top + a.height / 2 - top}px`);
    this.panel.style.removeProperty("--lui-tooltip-arrow-x");
  },
  destroyed() {
    clearTimeout(this.timer);
    this.hide();
    if (!this.trigger) return;
    this.trigger.removeEventListener("mouseenter", this.onEnter);
    this.trigger.removeEventListener("focusin", this.onEnter);
    this.trigger.removeEventListener("mouseleave", this.onLeave);
    this.trigger.removeEventListener("focusout", this.onFocusOut);
    document.removeEventListener("keydown", this.onKey);
  }
};
var LanternToast = {
  mounted() {
    this.timers = /* @__PURE__ */ new Set();
    this.toastTimers = /* @__PURE__ */ new Map();
    this.handleEvent("lantern:toast", (toast) => this.add(toast));
  },
  add({ kind = "info", message = "", title = null, duration = 4e3 } = {}) {
    const toast = document.createElement("div");
    toast.className = "lui-toast lui-toast-in";
    toast.dataset.kind = kind || "info";
    const dot = document.createElement("span");
    dot.className = "lui-toast-dot";
    dot.setAttribute("aria-hidden", "true");
    const body = document.createElement("div");
    body.className = "lui-toast-body";
    if (title) {
      const heading = document.createElement("strong");
      heading.className = "lui-toast-title";
      heading.textContent = String(title);
      body.appendChild(heading);
    }
    const copy = document.createElement("p");
    copy.className = "lui-toast-message";
    copy.textContent = message == null ? "" : String(message);
    body.appendChild(copy);
    const close = document.createElement("button");
    close.type = "button";
    close.className = "lui-toast-close";
    close.dataset.part = "close";
    close.setAttribute("aria-label", "Close");
    close.textContent = "\xD7";
    close.addEventListener("click", () => this.remove(toast));
    toast.append(dot, body, close);
    this.el.appendChild(toast);
    const rawDuration = duration == null ? 4e3 : Number(duration);
    const ms = Number.isFinite(rawDuration) ? rawDuration : 4e3;
    if (ms > 0) {
      const timer = this.setTimer(() => this.remove(toast), ms);
      this.toastTimers.set(toast, timer);
    }
  },
  remove(toast) {
    if (!toast || !toast.parentNode) return;
    if (toast.classList.contains("lui-toast-out")) return;
    this.clearTimer(this.toastTimers.get(toast));
    this.toastTimers.delete(toast);
    toast.classList.remove("lui-toast-in");
    toast.classList.add("lui-toast-out");
    this.setTimer(() => toast.remove(), 150);
  },
  setTimer(callback, ms) {
    const timer = setTimeout(() => {
      this.timers.delete(timer);
      callback();
    }, ms);
    this.timers.add(timer);
    return timer;
  },
  clearTimer(timer) {
    if (!timer) return;
    clearTimeout(timer);
    this.timers.delete(timer);
  },
  destroyed() {
    this.timers.forEach((timer) => clearTimeout(timer));
    this.timers.clear();
    this.toastTimers.clear();
  }
};
var LanternAccordion = {
  // A nested accordion's triggers are descendants of the outer root too. Every
  // query and delegated event must therefore verify which hook root owns it.
  ownedTrigger(node) {
    const trigger = node && node.closest && node.closest('[data-part="trigger"]');
    if (!trigger || trigger.disabled) return null;
    return trigger.closest('[phx-hook="LanternAccordion"]') === this.el ? trigger : null;
  },
  triggers() {
    return Array.from(this.el.querySelectorAll('[data-part="trigger"]')).filter(
      (trigger) => this.ownedTrigger(trigger) === trigger
    );
  },
  isMultiple() {
    return this.el.dataset.multiple === "true";
  },
  preventsAllClosed() {
    return this.el.dataset.preventAllClosed === "true";
  },
  panelFor(trigger) {
    const item = trigger.closest('[data-part="item"]');
    if (!item || item.closest('[phx-hook="LanternAccordion"]') !== this.el) return null;
    return Array.from(item.querySelectorAll('[data-part="panel"]')).find(
      (panel) => panel.closest('[data-part="item"]') === item
    );
  },
  remember(trigger, open) {
    if (trigger.id) this.stateById.set(trigger.id, open);
    const position2 = this.triggers().indexOf(trigger);
    if (position2 !== -1) this.stateByPosition[position2] = open;
  },
  setOpen(trigger, open) {
    const item = trigger.closest('[data-part="item"]');
    const panel = this.panelFor(trigger);
    trigger.setAttribute("aria-expanded", String(open));
    if (panel) panel.hidden = !open;
    if (item) item.setAttribute("data-state", open ? "open" : "closed");
    this.remember(trigger, open);
  },
  syncAriaDisabled() {
    const triggers = this.triggers();
    const open = triggers.filter((trigger) => trigger.getAttribute("aria-expanded") === "true");
    const inoperable = this.preventsAllClosed() && open.length === 1 ? open[0] : null;
    triggers.forEach((trigger) => {
      if (trigger === inoperable) trigger.setAttribute("aria-disabled", "true");
      else trigger.removeAttribute("aria-disabled");
    });
  },
  enforceConstraints() {
    const triggers = this.triggers();
    const open = triggers.filter((trigger) => trigger.getAttribute("aria-expanded") === "true");
    if (!this.isMultiple()) open.slice(1).forEach((trigger) => this.setOpen(trigger, false));
    const allClosed = this.triggers().every(
      (trigger) => trigger.getAttribute("aria-expanded") !== "true"
    );
    if (this.preventsAllClosed() && allClosed) {
      const first = triggers[0];
      if (first) this.setOpen(first, true);
    }
    this.syncAriaDisabled();
  },
  toggle(trigger) {
    const open = trigger.getAttribute("aria-expanded") === "true";
    if (open && trigger.getAttribute("aria-disabled") === "true") return;
    if (!open && !this.isMultiple()) {
      this.triggers().forEach((item) => item !== trigger && this.setOpen(item, false));
    }
    this.setOpen(trigger, !open);
    this.enforceConstraints();
  },
  focusBy(current, delta) {
    const items = this.triggers();
    const i = items.indexOf(current);
    if (i === -1) return;
    const next = (i + delta + items.length) % items.length;
    items[next].focus();
  },
  captureFocus() {
    const active = this.ownedTrigger(document.activeElement);
    this.focusedId = active && active.id;
    this.focusedPosition = active ? this.triggers().indexOf(active) : -1;
  },
  restoreFocus() {
    if (this.focusedPosition < 0) return;
    const triggers = this.triggers();
    const byId = triggers.find((item) => item.id === this.focusedId);
    const trigger = byId || triggers[this.focusedPosition];
    if (trigger) trigger.focus();
  },
  restoreState() {
    const previousById = this.stateById;
    const previousByPosition = this.stateByPosition;
    this.stateById = /* @__PURE__ */ new Map();
    this.stateByPosition = [];
    this.triggers().forEach((trigger, position2) => {
      const serverOpen = trigger.getAttribute("aria-expanded") === "true";
      const open = previousById.has(trigger.id) ? previousById.get(trigger.id) : previousByPosition[position2] ?? serverOpen;
      this.setOpen(trigger, open);
    });
    this.enforceConstraints();
  },
  mounted() {
    this.stateById = /* @__PURE__ */ new Map();
    this.stateByPosition = [];
    this.focusedId = null;
    this.focusedPosition = -1;
    this.triggers().forEach((trigger) => {
      this.remember(trigger, trigger.getAttribute("aria-expanded") === "true");
    });
    this.enforceConstraints();
    this.onClick = (event) => {
      const trigger = this.ownedTrigger(event.target);
      if (trigger) this.toggle(trigger);
    };
    this.onKeydown = (event) => {
      const trigger = this.ownedTrigger(event.target);
      if (!trigger) return;
      const items = this.triggers();
      switch (event.key) {
        case "ArrowDown":
          event.preventDefault();
          this.focusBy(trigger, 1);
          break;
        case "ArrowUp":
          event.preventDefault();
          this.focusBy(trigger, -1);
          break;
        case "Home":
          event.preventDefault();
          items[0] && items[0].focus();
          break;
        case "End":
          event.preventDefault();
          items[items.length - 1] && items[items.length - 1].focus();
          break;
      }
    };
    this.el.addEventListener("click", this.onClick);
    this.el.addEventListener("keydown", this.onKeydown);
  },
  beforeUpdate() {
    this.captureFocus();
  },
  // LiveView patches re-render the server's initial state and may regenerate
  // optional ids. Reapply client-owned state by stable id, then item position.
  updated() {
    this.restoreState();
    this.restoreFocus();
  },
  disconnected() {
    this.captureFocus();
  },
  reconnected() {
    this.restoreState();
    this.restoreFocus();
  },
  destroyed() {
    this.el.removeEventListener("click", this.onClick);
    this.el.removeEventListener("keydown", this.onKeydown);
  }
};
var Hooks = {
  ChartHover,
  LineHover,
  LanternOverlay,
  LanternCalendar,
  LanternDatetimeField,
  LanternPicker,
  LanternModal,
  LanternCommand,
  LanternSheet,
  LanternDropdown,
  LanternMenu,
  LanternMenubar,
  LanternTooltip,
  LanternToast,
  LanternSidebar,
  LanternSelect,
  LanternSlider,
  LanternAutocomplete,
  LanternCollapse,
  LanternAccordion,
  LanternTableChrome,
  LanternTheme
};
var lantern_ui_hooks_default = Hooks;
var LanternMessageScroller = {
  mounted() {
    this.viewport = this.el.querySelector('[data-part="viewport"]');
    this.content = this.el.querySelector('[data-part="content"]');
    this.button = this.el.querySelector('[data-part="jump-latest"]');
    this.following = this.el.dataset.follow === "true";
    this.reducedMotion = window.matchMedia?.("(prefers-reduced-motion: reduce)").matches ?? false;
    this.atBottom = true;
    this.updateState = () => {
      this.atBottom = this.viewport.scrollHeight - this.viewport.scrollTop - this.viewport.clientHeight <= 32;
      this.el.dataset.scrollable = this.atBottom ? "false" : "true";
      this.button.dataset.active = String(!this.atBottom);
      this.button.setAttribute("aria-hidden", this.atBottom ? "true" : "false");
      this.button.setAttribute("tabindex", this.atBottom ? "-1" : "0");
    };
    this.scroll = () => {
      this.updateState();
      if (this.atBottom) this.following = true;
      else if (this.following) this.following = false;
    };
    this.viewport.addEventListener("scroll", this.scroll);
    this._onRootClick = (event) => {
      if (!event.target.closest('[data-part="jump-latest"]')) return;
      this.following = true;
      this.scrollToBottom();
    };
    this.el.addEventListener("click", this._onRootClick);
    this.observer = new MutationObserver((records) => {
      const anchor = records.flatMap((record) => [...record.addedNodes]).flatMap((node) => {
        if (node.nodeType !== 1) return [];
        return [node, ...node.querySelectorAll?.("[data-scroll-anchor]") || []];
      }).find((node) => node.hasAttribute?.("data-scroll-anchor"));
      const following = this.following;
      if (anchor && following) {
        this.viewport.scrollTop = Math.max(0, (anchor.offsetTop || 0) - Number(this.el.dataset.peek || 40));
        this.updateState();
      } else if (following) this.scrollToBottom();
      else this.updateState();
    });
    this.observer.observe(this.content, { childList: true, subtree: true, characterData: true });
    this.resize = () => {
      if (this.following) this.scrollToBottom();
    };
    window.addEventListener("resize", this.resize);
    requestAnimationFrame(() => {
      if (this.following) this.scrollToBottom();
      else this.updateState();
    });
  },
  scrollToBottom() {
    this.el.dataset.autoscrolling = "true";
    this.viewport.scrollTop = this.viewport.scrollHeight;
    this.updateState();
    if (this.reducedMotion) this.el.removeAttribute("data-autoscrolling");
    else requestAnimationFrame(() => this.el.removeAttribute("data-autoscrolling"));
  },
  destroyed() {
    this.viewport?.removeEventListener("scroll", this.scroll);
    this.el.removeEventListener("click", this._onRootClick);
    this.observer?.disconnect();
    window.removeEventListener("resize", this.resize);
  }
};
Hooks.LanternMessageScroller = LanternMessageScroller;
var LanternSidePanel = {
  storageKey() {
    return `lui-side-panel:${this.el.dataset.panelKey || this.el.id}`;
  },
  readStored() {
    try {
      const stored = window.localStorage.getItem(this.storageKey());
      if (stored === "open") return true;
      if (stored === "closed") return false;
    } catch (_e) {
    }
    return null;
  },
  writeStored(open) {
    try {
      window.localStorage.setItem(this.storageKey(), open ? "open" : "closed");
    } catch (_e) {
    }
  },
  isOpen() {
    return this.el.getAttribute("aria-pressed") === "true";
  },
  eventName() {
    return this.el.dataset.event || "set_panel";
  },
  persistEventName() {
    return this.el.dataset.persistEvent || "side_panel";
  },
  mounted() {
    let open = this.readStored();
    if (open === null) open = window.innerWidth >= 1280;
    if (open !== this.isOpen()) this.pushEvent(this.eventName(), { open });
    this.handleEvent(this.persistEventName(), ({ open: open2 }) => this.writeStored(!!open2));
  },
  updated() {
    this.writeStored(this.isOpen());
  }
};
Hooks.LanternSidePanel = LanternSidePanel;
var LanternSegmented = {
  mounted() {
    this.onKey = (event) => this.onKeydown(event);
    this.el.addEventListener("keydown", this.onKey);
  },
  destroyed() {
    this.el.removeEventListener("keydown", this.onKey);
  },
  segments() {
    return [...this.el.querySelectorAll('[data-part="segment"]')].filter((el) => {
      if (el.disabled || el.getAttribute("aria-disabled") === "true") return false;
      return true;
    });
  },
  onKeydown(event) {
    const keys = ["ArrowLeft", "ArrowRight", "ArrowUp", "ArrowDown", "Home", "End"];
    if (!keys.includes(event.key)) return;
    const segs = this.segments();
    if (segs.length === 0) return;
    const current = segs.findIndex((el2) => el2 === event.target || el2.contains(event.target));
    if (current < 0) return;
    event.preventDefault();
    let next = current;
    if (event.key === "Home") next = 0;
    else if (event.key === "End") next = segs.length - 1;
    else if (event.key === "ArrowLeft" || event.key === "ArrowUp") {
      next = (current - 1 + segs.length) % segs.length;
    } else {
      next = (current + 1) % segs.length;
    }
    const el = segs[next];
    el.focus();
    el.click();
  }
};
Hooks.LanternSegmented = LanternSegmented;
if (typeof document !== "undefined") installBehaviours(document);
export {
  ChartHover,
  Hooks,
  LanternAccordion,
  LanternAutocomplete,
  LanternCalendar,
  LanternCollapse,
  LanternCommand,
  LanternDatetimeField,
  LanternDropdown,
  LanternMenu,
  LanternMenubar,
  LanternMessageScroller,
  LanternModal,
  LanternOverlay,
  LanternPicker,
  LanternSegmented,
  LanternSelect,
  LanternSheet,
  LanternSidePanel,
  LanternSidebar,
  LanternSlider,
  LanternTableChrome,
  LanternTheme,
  LanternToast,
  LanternTooltip,
  LineHover,
  lantern_ui_hooks_default as default,
  installBehaviours,
  runtime
};
