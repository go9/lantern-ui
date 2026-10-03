// node_modules/@zag-js/anatomy/dist/create-anatomy.mjs
var createAnatomy = (name, parts2 = []) => ({
  parts: (...values) => {
    if (isEmpty(parts2)) {
      return createAnatomy(name, values);
    }
    throw new Error("createAnatomy().parts(...) should only be called once. Did you mean to use .extendWith(...) ?");
  },
  extendWith: (...values) => createAnatomy(name, [...parts2, ...values]),
  omit: (...values) => createAnatomy(name, parts2.filter((part2) => !values.includes(part2))),
  rename: (newName) => createAnatomy(newName, parts2),
  keys: () => parts2,
  build: () => [...new Set(parts2)].reduce(
    (prev, part2) => Object.assign(prev, {
      [part2]: {
        selector: [
          `&[data-scope="${toKebabCase(name)}"][data-part="${toKebabCase(part2)}"]`,
          `& [data-scope="${toKebabCase(name)}"][data-part="${toKebabCase(part2)}"]`
        ].join(", "),
        attrs: { "data-scope": toKebabCase(name), "data-part": toKebabCase(part2) }
      }
    }),
    {}
  )
});
var toKebabCase = (value) => value.replace(/([A-Z])([A-Z])/g, "$1-$2").replace(/([a-z])([A-Z])/g, "$1-$2").replace(/[\s_]+/g, "-").toLowerCase();
var isEmpty = (v) => v.length === 0;

// node_modules/@zag-js/select/dist/select.anatomy.mjs
var anatomy = createAnatomy("select").parts(
  "label",
  "positioner",
  "trigger",
  "indicator",
  "clearTrigger",
  "item",
  "itemText",
  "itemIndicator",
  "itemGroup",
  "itemGroupLabel",
  "list",
  "content",
  "root",
  "control",
  "valueText"
);
var parts = anatomy.build();

// node_modules/@zag-js/collection/dist/chunk-QZ7TP4HQ.mjs
var __defProp = Object.defineProperty;
var __defNormalProp = (obj, key, value) => key in obj ? __defProp(obj, key, { enumerable: true, configurable: true, writable: true, value }) : obj[key] = value;
var __publicField = (obj, key, value) => __defNormalProp(obj, typeof key !== "symbol" ? key + "" : key, value);

// node_modules/@zag-js/utils/dist/array.mjs
function toArray(v) {
  if (v == null) return [];
  return Array.isArray(v) ? v : [v];
}
var has = (v, t) => v.indexOf(t) !== -1;
var add = (v, ...items) => v.concat(items);
var remove = (v, ...items) => v.filter((t) => !items.includes(t));
var addOrRemove = (v, item) => has(v, item) ? remove(v, item) : add(v, item);

// node_modules/@zag-js/utils/dist/equal.mjs
var isArrayLike = (value) => value?.constructor.name === "Array";
var isArrayEqual = (a, b) => {
  if (a.length !== b.length) return false;
  for (let i = 0; i < a.length; i++) {
    if (!isEqual(a[i], b[i])) return false;
  }
  return true;
};
var isEqual = (a, b) => {
  if (Object.is(a, b)) return true;
  if (a == null && b != null || a != null && b == null) return false;
  if (typeof a?.isEqual === "function" && typeof b?.isEqual === "function") {
    return a.isEqual(b);
  }
  if (typeof a === "function" && typeof b === "function") {
    return a.toString() === b.toString();
  }
  if (isArrayLike(a) && isArrayLike(b)) {
    return isArrayEqual(Array.from(a), Array.from(b));
  }
  if (!(typeof a === "object") || !(typeof b === "object")) return false;
  const keys = Object.keys(b ?? /* @__PURE__ */ Object.create(null));
  const length = keys.length;
  for (let i = 0; i < length; i++) {
    const hasKey = Reflect.has(a, keys[i]);
    if (!hasKey) return false;
  }
  for (let i = 0; i < length; i++) {
    const key = keys[i];
    if (!isEqual(a[key], b[key])) return false;
  }
  return true;
};

// node_modules/@zag-js/utils/dist/guard.mjs
var isArray = (v) => Array.isArray(v);
var isObjectLike = (v) => v != null && typeof v === "object";
var isObject = (v) => isObjectLike(v) && !isArray(v);
var isString = (v) => typeof v === "string";
var isFunction = (v) => typeof v === "function";
var isNull = (v) => v == null;
var hasProp = (obj, prop) => Object.prototype.hasOwnProperty.call(obj, prop);
var baseGetTag = (v) => Object.prototype.toString.call(v);
var fnToString = Function.prototype.toString;
var objectCtorString = fnToString.call(Object);
var isPlainObject = (v) => {
  if (!isObjectLike(v) || baseGetTag(v) != "[object Object]" || isFrameworkElement(v)) return false;
  const proto = Object.getPrototypeOf(v);
  if (proto === null) return true;
  const Ctor = hasProp(proto, "constructor") && proto.constructor;
  return typeof Ctor == "function" && Ctor instanceof Ctor && fnToString.call(Ctor) == objectCtorString;
};
var isReactElement = (x) => typeof x === "object" && x !== null && "$$typeof" in x && "props" in x;
var isVueElement = (x) => typeof x === "object" && x !== null && "__v_isVNode" in x;
var isFrameworkElement = (x) => isReactElement(x) || isVueElement(x);

// node_modules/@zag-js/utils/dist/functions.mjs
var runIfFn = (v, ...a) => {
  const res = typeof v === "function" ? v(...a) : v;
  return res ?? void 0;
};
var identity = (v) => v();
var noop = () => {
};
var callAll = (...fns) => (...a) => {
  fns.forEach(function(fn) {
    fn?.(...a);
  });
};

// node_modules/@zag-js/utils/dist/object.mjs
function compact(obj) {
  if (!isPlainObject(obj) || obj === void 0) return obj;
  const keys2 = Reflect.ownKeys(obj).filter((key) => typeof key === "string");
  const filtered = {};
  for (const key of keys2) {
    const value = obj[key];
    if (value !== void 0) {
      filtered[key] = compact(value);
    }
  }
  return filtered;
}
function mergeWithDefault(defaults, overrides) {
  if (!overrides) return defaults;
  const result = { ...defaults };
  const source = overrides;
  for (const key in source) {
    const value = source[key];
    if (value !== void 0) result[key] = value;
  }
  return result;
}

// node_modules/@zag-js/utils/dist/warning.mjs
function warn(...a) {
  const m = a.length === 1 ? a[0] : a[1];
  const c = a.length === 2 ? a[0] : true;
  if (c && true) {
    console.warn(m);
  }
}
function invariant(...a) {
  const m = a.length === 1 ? a[0] : a[1];
  const c = a.length === 2 ? a[0] : true;
  if (c && true) {
    throw new Error(m);
  }
}
function ensure(c, m) {
  if (c == null) throw new Error(m());
}

// node_modules/@zag-js/collection/dist/list-collection.mjs
var fallback = {
  itemToValue(item) {
    if (typeof item === "string") return item;
    if (isObject(item) && hasProp(item, "value")) return item.value;
    return "";
  },
  itemToString(item) {
    if (typeof item === "string") return item;
    if (isObject(item) && hasProp(item, "label")) return item.label;
    return fallback.itemToValue(item);
  },
  isItemDisabled(item) {
    if (isObject(item) && hasProp(item, "disabled")) return !!item.disabled;
    return false;
  }
};
var ListCollection = class _ListCollection {
  constructor(options) {
    __publicField(this, "options", options);
    __publicField(this, "items");
    __publicField(this, "indexMap", null);
    __publicField(this, "copy", (items) => {
      return new _ListCollection({ ...this.options, items: items ?? [...this.items] });
    });
    __publicField(this, "isEqual", (other) => {
      return isEqual(this.items, other.items);
    });
    __publicField(this, "setItems", (items) => {
      return this.copy(items);
    });
    __publicField(this, "getValues", (items = this.items) => {
      const values = [];
      for (const item of items) {
        const value = this.getItemValue(item);
        if (value != null) values.push(value);
      }
      return values;
    });
    __publicField(this, "find", (value) => {
      if (value == null) return null;
      const index = this.indexOf(value);
      return index !== -1 ? this.at(index) : null;
    });
    __publicField(this, "findMany", (values) => {
      const result = [];
      for (const value of values) {
        const item = this.find(value);
        if (item != null) result.push(item);
      }
      return result;
    });
    __publicField(this, "at", (index) => {
      if (!this.options.groupBy && !this.options.groupSort) {
        return this.items[index] ?? null;
      }
      let idx = 0;
      const groups = this.group();
      for (const [, items] of groups) {
        for (const item of items) {
          if (idx === index) return item;
          idx++;
        }
      }
      return null;
    });
    __publicField(this, "sortFn", (valueA, valueB) => {
      const indexA = this.indexOf(valueA);
      const indexB = this.indexOf(valueB);
      return (indexA ?? 0) - (indexB ?? 0);
    });
    __publicField(this, "sort", (values) => {
      return [...values].sort(this.sortFn.bind(this));
    });
    __publicField(this, "getItemValue", (item) => {
      if (item == null) return null;
      return this.options.itemToValue?.(item) ?? fallback.itemToValue(item);
    });
    __publicField(this, "getItemDisabled", (item) => {
      if (item == null) return false;
      return this.options.isItemDisabled?.(item) ?? fallback.isItemDisabled(item);
    });
    __publicField(this, "stringifyItem", (item) => {
      if (item == null) return null;
      return this.options.itemToString?.(item) ?? fallback.itemToString(item);
    });
    __publicField(this, "stringify", (value) => {
      if (value == null) return null;
      return this.stringifyItem(this.find(value));
    });
    __publicField(this, "stringifyItems", (items, separator = ", ") => {
      const strs = [];
      for (const item of items) {
        const str = this.stringifyItem(item);
        if (str != null) strs.push(str);
      }
      return strs.join(separator);
    });
    __publicField(this, "stringifyMany", (value, separator) => {
      return this.stringifyItems(this.findMany(value), separator);
    });
    __publicField(this, "has", (value) => {
      return this.indexOf(value) !== -1;
    });
    __publicField(this, "hasItem", (item) => {
      if (item == null) return false;
      return this.has(this.getItemValue(item));
    });
    __publicField(this, "group", () => {
      const { groupBy, groupSort } = this.options;
      if (!groupBy) return [["", [...this.items]]];
      const groups = /* @__PURE__ */ new Map();
      this.items.forEach((item, index) => {
        const groupKey = groupBy(item, index);
        if (!groups.has(groupKey)) {
          groups.set(groupKey, []);
        }
        groups.get(groupKey).push(item);
      });
      let entries = Array.from(groups.entries());
      if (groupSort) {
        entries.sort(([a], [b]) => {
          if (typeof groupSort === "function") return groupSort(a, b);
          if (Array.isArray(groupSort)) {
            const indexA = groupSort.indexOf(a);
            const indexB = groupSort.indexOf(b);
            if (indexA === -1) return 1;
            if (indexB === -1) return -1;
            return indexA - indexB;
          }
          if (groupSort === "asc") return a.localeCompare(b);
          if (groupSort === "desc") return b.localeCompare(a);
          return 0;
        });
      }
      return entries;
    });
    __publicField(this, "getNextValue", (value, step = 1, clamp2 = false) => {
      let index = this.indexOf(value);
      if (index === -1) return null;
      index = clamp2 ? Math.min(index + step, this.size - 1) : index + step;
      while (index <= this.size && this.getItemDisabled(this.at(index))) index++;
      return this.getItemValue(this.at(index));
    });
    __publicField(this, "getPreviousValue", (value, step = 1, clamp2 = false) => {
      let index = this.indexOf(value);
      if (index === -1) return null;
      index = clamp2 ? Math.max(index - step, 0) : index - step;
      while (index >= 0 && this.getItemDisabled(this.at(index))) index--;
      return this.getItemValue(this.at(index));
    });
    __publicField(this, "indexOf", (value) => {
      if (value == null) return -1;
      if (!this.options.groupBy && !this.options.groupSort) {
        return this.items.findIndex((item) => this.getItemValue(item) === value);
      }
      if (!this.indexMap) {
        this.indexMap = /* @__PURE__ */ new Map();
        let idx = 0;
        const groups = this.group();
        for (const [, items] of groups) {
          for (const item of items) {
            const itemValue = this.getItemValue(item);
            if (itemValue != null) {
              this.indexMap.set(itemValue, idx);
            }
            idx++;
          }
        }
      }
      return this.indexMap.get(value) ?? -1;
    });
    __publicField(this, "getByText", (text, current) => {
      const currentIndex = current != null ? this.indexOf(current) : -1;
      const isSingleKey = text.length === 1;
      for (let i = 0; i < this.items.length; i++) {
        const item = this.items[(currentIndex + i + 1) % this.items.length];
        if (isSingleKey && this.getItemValue(item) === current) continue;
        if (this.getItemDisabled(item)) continue;
        if (match(this.stringifyItem(item), text)) return item;
      }
      return void 0;
    });
    __publicField(this, "search", (queryString, options2) => {
      const { state, currentValue, timeout = 350 } = options2;
      const search = state.keysSoFar + queryString;
      const isRepeated = search.length > 1 && Array.from(search).every((char) => char === search[0]);
      const query = isRepeated ? search[0] : search;
      const item = this.getByText(query, currentValue);
      const value = this.getItemValue(item);
      function cleanup() {
        clearTimeout(state.timer);
        state.timer = -1;
      }
      function update(value2) {
        state.keysSoFar = value2;
        cleanup();
        if (value2 !== "") {
          state.timer = +setTimeout(() => {
            update("");
            cleanup();
          }, timeout);
        }
      }
      update(search);
      return value;
    });
    __publicField(this, "update", (value, item) => {
      let index = this.indexOf(value);
      if (index === -1) return this;
      return this.copy([...this.items.slice(0, index), item, ...this.items.slice(index + 1)]);
    });
    __publicField(this, "upsert", (value, item, mode = "append") => {
      let index = this.indexOf(value);
      if (index === -1) {
        const fn = mode === "append" ? this.append : this.prepend;
        return fn(item);
      }
      return this.copy([...this.items.slice(0, index), item, ...this.items.slice(index + 1)]);
    });
    __publicField(this, "insert", (index, ...items) => {
      return this.copy(insert(this.items, index, ...items));
    });
    __publicField(this, "insertBefore", (value, ...items) => {
      let toIndex = this.indexOf(value);
      if (toIndex === -1) {
        if (this.items.length === 0) toIndex = 0;
        else return this;
      }
      return this.copy(insert(this.items, toIndex, ...items));
    });
    __publicField(this, "insertAfter", (value, ...items) => {
      let toIndex = this.indexOf(value);
      if (toIndex === -1) {
        if (this.items.length === 0) toIndex = 0;
        else return this;
      }
      return this.copy(insert(this.items, toIndex + 1, ...items));
    });
    __publicField(this, "prepend", (...items) => {
      return this.copy(insert(this.items, 0, ...items));
    });
    __publicField(this, "append", (...items) => {
      return this.copy(insert(this.items, this.items.length, ...items));
    });
    __publicField(this, "filter", (fn) => {
      const filteredItems = this.items.filter((item, index) => fn(this.stringifyItem(item), index, item));
      return this.copy(filteredItems);
    });
    __publicField(this, "remove", (...itemsOrValues) => {
      const values = itemsOrValues.map(
        (itemOrValue) => typeof itemOrValue === "string" ? itemOrValue : this.getItemValue(itemOrValue)
      );
      return this.copy(
        this.items.filter((item) => {
          const value = this.getItemValue(item);
          if (value == null) return false;
          return !values.includes(value);
        })
      );
    });
    __publicField(this, "move", (value, toIndex) => {
      const fromIndex = this.indexOf(value);
      if (fromIndex === -1) return this;
      return this.copy(move(this.items, [fromIndex], toIndex));
    });
    __publicField(this, "moveBefore", (value, ...values) => {
      let toIndex = this.items.findIndex((item) => this.getItemValue(item) === value);
      if (toIndex === -1) return this;
      let indices = values.map((value2) => this.items.findIndex((item) => this.getItemValue(item) === value2)).sort((a, b) => a - b);
      return this.copy(move(this.items, indices, toIndex));
    });
    __publicField(this, "moveAfter", (value, ...values) => {
      let toIndex = this.items.findIndex((item) => this.getItemValue(item) === value);
      if (toIndex === -1) return this;
      let indices = values.map((value2) => this.items.findIndex((item) => this.getItemValue(item) === value2)).sort((a, b) => a - b);
      return this.copy(move(this.items, indices, toIndex + 1));
    });
    __publicField(this, "reorder", (fromIndex, toIndex) => {
      return this.copy(move(this.items, [fromIndex], toIndex));
    });
    __publicField(this, "compareValue", (a, b) => {
      const indexA = this.indexOf(a);
      const indexB = this.indexOf(b);
      if (indexA < indexB) return -1;
      if (indexA > indexB) return 1;
      return 0;
    });
    __publicField(this, "range", (from, to) => {
      let keys = [];
      let key = from;
      while (key != null) {
        let item = this.find(key);
        if (item) keys.push(key);
        if (key === to) return keys;
        key = this.getNextValue(key);
      }
      return [];
    });
    __publicField(this, "getValueRange", (from, to) => {
      if (from && to) {
        if (this.compareValue(from, to) <= 0) {
          return this.range(from, to);
        }
        return this.range(to, from);
      }
      return [];
    });
    __publicField(this, "toString", () => {
      let result = "";
      for (const item of this.items) {
        const value = this.getItemValue(item);
        const label = this.stringifyItem(item);
        const disabled = this.getItemDisabled(item);
        const itemString = [value, label, disabled].filter(Boolean).join(":");
        result += itemString + ",";
      }
      return result;
    });
    __publicField(this, "toJSON", () => {
      return {
        size: this.size,
        first: this.firstValue,
        last: this.lastValue
      };
    });
    this.items = [...options.items];
  }
  /**
   * Returns the number of items in the collection
   */
  get size() {
    return this.items.length;
  }
  /**
   * Returns the first value in the collection
   */
  get firstValue() {
    let index = 0;
    while (this.getItemDisabled(this.at(index))) index++;
    return this.getItemValue(this.at(index));
  }
  /**
   * Returns the last value in the collection
   */
  get lastValue() {
    let index = this.size - 1;
    while (this.getItemDisabled(this.at(index))) index--;
    return this.getItemValue(this.at(index));
  }
  *[Symbol.iterator]() {
    yield* this.items;
  }
};
var match = (label, query) => {
  return !!label?.toLowerCase().startsWith(query.toLowerCase());
};
function insert(items, index, ...values) {
  return [...items.slice(0, index), ...values, ...items.slice(index)];
}
function move(items, indices, toIndex) {
  indices = [...indices].sort((a, b) => a - b);
  const itemsToMove = indices.map((i) => items[i]);
  for (let i = indices.length - 1; i >= 0; i--) {
    items = [...items.slice(0, indices[i]), ...items.slice(indices[i] + 1)];
  }
  toIndex = Math.max(0, toIndex - indices.filter((i) => i < toIndex).length);
  return [...items.slice(0, toIndex), ...itemsToMove, ...items.slice(toIndex)];
}

// node_modules/@zag-js/collection/dist/selection-map.mjs
function resolveSelectedItems({
  values,
  collection: collection2,
  selectedItemMap
}) {
  const result = [];
  for (const value of values) {
    const item = collection2.find(value) ?? selectedItemMap.get(value);
    if (item != null) result.push(item);
  }
  return result;
}
function updateSelectedItemMap({
  selectedItemMap,
  values,
  selectedItems,
  collection: collection2
}) {
  const nextMap = new Map(selectedItemMap);
  for (const item of selectedItems) {
    const value = collection2.getItemValue(item);
    if (value != null) nextMap.set(value, item);
  }
  const allowedValues = new Set(values);
  for (const value of nextMap.keys()) {
    if (!allowedValues.has(value)) nextMap.delete(value);
  }
  return nextMap;
}
function deriveSelectionState({
  values,
  collection: collection2,
  selectedItemMap
}) {
  const selectedItems = resolveSelectedItems({ values, collection: collection2, selectedItemMap });
  const nextSelectedItemMap = updateSelectedItemMap({
    selectedItemMap,
    values,
    selectedItems,
    collection: collection2
  });
  return { selectedItems, nextSelectedItemMap };
}
function createSelectedItemMap({
  selectedItems,
  collection: collection2
}) {
  return updateSelectedItemMap({
    selectedItemMap: /* @__PURE__ */ new Map(),
    values: selectedItems.map((item) => collection2.getItemValue(item)).filter(Boolean),
    selectedItems,
    collection: collection2
  });
}

// node_modules/@zag-js/select/dist/select.collection.mjs
var collection = (options) => {
  return new ListCollection(options);
};
collection.empty = () => {
  return new ListCollection({ items: [] });
};

// node_modules/@zag-js/dom-query/dist/chunk-QZ7TP4HQ.mjs
var __defProp2 = Object.defineProperty;
var __defNormalProp2 = (obj, key, value) => key in obj ? __defProp2(obj, key, { enumerable: true, configurable: true, writable: true, value }) : obj[key] = value;
var __publicField2 = (obj, key, value) => __defNormalProp2(obj, typeof key !== "symbol" ? key + "" : key, value);

// node_modules/@zag-js/dom-query/dist/shared.mjs
var wrap = (v, idx) => {
  return v.map((_, index) => v[(Math.max(idx, 0) + index) % v.length]);
};
var noop2 = () => void 0;
var isObject2 = (v) => typeof v === "object" && v !== null;
var dataAttr = (guard) => guard ? "" : void 0;
var ariaAttr = (guard) => guard ? "true" : void 0;

// node_modules/@zag-js/dom-query/dist/node.mjs
var ELEMENT_NODE = 1;
var DOCUMENT_NODE = 9;
var DOCUMENT_FRAGMENT_NODE = 11;
var isHTMLElement = (el) => isObject2(el) && el.nodeType === ELEMENT_NODE && typeof el.nodeName === "string";
var isDocument = (el) => isObject2(el) && el.nodeType === DOCUMENT_NODE;
var isWindow = (el) => isObject2(el) && el === el.window;
var getNodeName = (node) => {
  if (isHTMLElement(node)) return node.localName || "";
  return "#document";
};
function isRootElement(node) {
  return ["html", "body", "#document"].includes(getNodeName(node));
}
var isNode = (el) => isObject2(el) && el.nodeType !== void 0;
var isShadowRoot = (el) => isNode(el) && el.nodeType === DOCUMENT_FRAGMENT_NODE && "host" in el;
var isInputElement = (el) => isHTMLElement(el) && el.localName === "input";
var isElementVisible = (el) => {
  if (!isHTMLElement(el)) return false;
  return el.offsetWidth > 0 || el.offsetHeight > 0 || el.getClientRects().length > 0;
};
function isActiveElement(element) {
  if (!element) return false;
  const rootNode = element.getRootNode();
  return getActiveElement(rootNode) === element;
}
var TEXTAREA_SELECT_REGEX = /(textarea|select)/;
function isEditableElement(el) {
  if (el == null || !isHTMLElement(el)) return false;
  try {
    return isInputElement(el) && el.selectionStart != null || TEXTAREA_SELECT_REGEX.test(el.localName) || el.isContentEditable || el.getAttribute("contenteditable") === "true" || el.getAttribute("contenteditable") === "";
  } catch {
    return false;
  }
}
function contains(parent, child) {
  if (!parent || !child) return false;
  if (!isHTMLElement(parent) || !isNode(child)) return false;
  if (isHTMLElement(child) && parent === child) return true;
  if (parent.contains(child)) return true;
  const rootNode = child.getRootNode?.();
  if (rootNode && isShadowRoot(rootNode)) {
    let next = child;
    while (next) {
      if (parent === next) return true;
      next = next.parentNode || next.host;
    }
  }
  return false;
}
function getDocument(el) {
  if (isDocument(el)) return el;
  if (isWindow(el)) return el.document;
  return el?.ownerDocument ?? document;
}
function getDocumentElement(el) {
  return getDocument(el).documentElement;
}
function getWindow(el) {
  if (isShadowRoot(el)) return getWindow(el.host);
  if (isDocument(el)) return el.defaultView ?? window;
  if (isHTMLElement(el)) return el.ownerDocument?.defaultView ?? window;
  return window;
}
function getActiveElement(rootNode) {
  let activeElement = rootNode.activeElement;
  while (activeElement?.shadowRoot) {
    const el = activeElement.shadowRoot.activeElement;
    if (!el || el === activeElement) break;
    else activeElement = el;
  }
  return activeElement;
}
function getParentNode(node) {
  if (getNodeName(node) === "html") return node;
  const result = node.assignedSlot || node.parentNode || isShadowRoot(node) && node.host || getDocumentElement(node);
  return isShadowRoot(result) ? result.host : result;
}
function getRootNode(node) {
  let result;
  try {
    result = node.getRootNode({ composed: true });
    if (isDocument(result) || isShadowRoot(result)) return result;
  } catch {
  }
  return node.ownerDocument ?? document;
}

// node_modules/@zag-js/dom-query/dist/computed-style.mjs
var styleCache = /* @__PURE__ */ new WeakMap();
function getComputedStyle2(el) {
  if (!styleCache.has(el)) {
    styleCache.set(el, getWindow(el).getComputedStyle(el));
  }
  return styleCache.get(el);
}

// node_modules/@zag-js/dom-query/dist/platform.mjs
var isDom = () => typeof document !== "undefined";
function getPlatform() {
  const agent = navigator.userAgentData;
  return agent?.platform ?? navigator.platform;
}
function getUserAgent() {
  const ua2 = navigator.userAgentData;
  if (ua2 && Array.isArray(ua2.brands)) {
    return ua2.brands.map(({ brand, version }) => `${brand}/${version}`).join(" ");
  }
  return navigator.userAgent;
}
var pt = (v) => isDom() && v.test(getPlatform());
var ua = (v) => isDom() && v.test(getUserAgent());
var MAC_REGEX = /^Mac/i;
var ANDROID_REGEX = /Android/i;
var isTouchDevice = () => isDom() && !!navigator.maxTouchPoints;
var isMac = () => pt(MAC_REGEX);
var isAndroid = () => ua(ANDROID_REGEX);

// node_modules/@zag-js/dom-query/dist/controller.mjs
var INTERACTIVE_CONTAINER_ROLE = /* @__PURE__ */ new Set(["menu", "listbox", "dialog", "grid", "tree", "region", "application"]);
var isInteractiveContainerRole = (role) => INTERACTIVE_CONTAINER_ROLE.has(role);
var getAriaControls = (element) => element.getAttribute("aria-controls")?.split(" ") || [];
function isControlledElement(container, element) {
  const visitedIds = /* @__PURE__ */ new Set();
  const rootNode = getRootNode(container);
  const checkElement = (searchRoot) => {
    const controllingElements = searchRoot.querySelectorAll("[aria-controls]");
    for (const controller of controllingElements) {
      if (controller.getAttribute("aria-expanded") !== "true") continue;
      const controlledIds = getAriaControls(controller);
      for (const id of controlledIds) {
        if (!id || visitedIds.has(id)) continue;
        visitedIds.add(id);
        const controlledElement = rootNode.getElementById(id);
        if (controlledElement) {
          const role = controlledElement.getAttribute("role");
          const modal = controlledElement.getAttribute("aria-modal") === "true";
          if (role && isInteractiveContainerRole(role) && !modal) {
            if (controlledElement === element || controlledElement.contains(element)) {
              return true;
            }
            if (checkElement(controlledElement)) {
              return true;
            }
          }
        }
      }
    }
    return false;
  };
  return checkElement(container);
}

// node_modules/@zag-js/dom-query/dist/event.mjs
function getComposedPath(event) {
  return event.composedPath?.() ?? event.nativeEvent?.composedPath?.();
}
function getEventTarget(event) {
  const composedPath = getComposedPath(event);
  return composedPath?.[0] ?? event.target;
}
function isVirtualClick(e) {
  if (e.pointerType === "" && e.isTrusted) return true;
  if (isAndroid() && e.pointerType) {
    return e.type === "click" && e.buttons === 1;
  }
  return e.detail === 0 && !e.pointerType;
}
var isContextMenuEvent = (e) => {
  return e.button === 2 || isMac() && e.ctrlKey && e.button === 0;
};
var keyMap = {
  Up: "ArrowUp",
  Down: "ArrowDown",
  Esc: "Escape",
  " ": "Space",
  ",": "Comma",
  Left: "ArrowLeft",
  Right: "ArrowRight"
};
var rtlKeyMap = {
  ArrowLeft: "ArrowRight",
  ArrowRight: "ArrowLeft"
};
function getEventKey(event, options = {}) {
  const { dir = "ltr", orientation = "horizontal" } = options;
  let key = event.key;
  key = keyMap[key] ?? key;
  const isRtl = dir === "rtl" && orientation === "horizontal";
  if (isRtl && key in rtlKeyMap) key = rtlKeyMap[key];
  return key;
}
function getNativeEvent(event) {
  return event.nativeEvent ?? event;
}
var addDomEvent = (target, eventName, handler, options) => {
  const node = typeof target === "function" ? target() : target;
  node?.addEventListener(eventName, handler, options);
  return () => {
    node?.removeEventListener(eventName, handler, options);
  };
};

// node_modules/@zag-js/dom-query/dist/form.mjs
function isFormElement(el) {
  return el.matches("textarea, input, select, button");
}
function trackFormReset(el, callback) {
  if (!el) return;
  const form = isFormElement(el) ? el.form : el.closest("form");
  const onReset = (e) => {
    if (e.defaultPrevented) return;
    callback();
  };
  form?.addEventListener("reset", onReset, { passive: true });
  return () => form?.removeEventListener("reset", onReset);
}
function trackFieldsetDisabled(el, callback) {
  const fieldset = el?.closest("fieldset");
  if (!fieldset) return;
  callback(fieldset.disabled);
  const win = getWindow(fieldset);
  const obs = new win.MutationObserver(() => callback(fieldset.disabled));
  obs.observe(fieldset, {
    attributes: true,
    attributeFilter: ["disabled"]
  });
  return () => obs.disconnect();
}
function trackFormControl(el, options) {
  if (!el) return;
  const { onFieldsetDisabledChange, onFormReset } = options;
  const cleanups = [trackFormReset(el, onFormReset), trackFieldsetDisabled(el, onFieldsetDisabledChange)];
  return () => cleanups.forEach((cleanup) => cleanup?.());
}
var INTERNAL_CHANGE_EVENT = /* @__PURE__ */ Symbol.for("zag.changeEvent");
function isInternalChangeEvent(e) {
  return Object.prototype.hasOwnProperty.call(e, INTERNAL_CHANGE_EVENT);
}
function markAsInternalChangeEvent(event) {
  if (isInternalChangeEvent(event)) return event;
  Object.defineProperty(event, INTERNAL_CHANGE_EVENT, { value: true });
  return event;
}

// node_modules/@zag-js/dom-query/dist/tabbable.mjs
var isFrame = (el) => isHTMLElement(el) && el.tagName === "IFRAME";
function parseTabIndex(el) {
  const attr = el.getAttribute("tabindex");
  if (!attr) return NaN;
  return parseInt(attr, 10);
}
var hasNegativeTabIndex = (el) => parseTabIndex(el) < 0;
function isRadioInput(element) {
  return isInputElement(element) && element.type === "radio";
}
function isTabbableRadio(element) {
  if (!isRadioInput(element) || !element.name) return true;
  if (element.checked) return true;
  const selector = `input[type="radio"][name="${CSS.escape(element.name)}"]`;
  const scope = element.form ?? element.ownerDocument;
  const group = Array.from(scope.querySelectorAll(selector)).filter(
    (radio) => radio.form === element.form && isFocusable(radio)
  );
  const checked = group.find((radio) => radio.checked);
  if (checked) return checked === element;
  return group[0] === element;
}
function getShadowRootForNode(element, getShadowRoot) {
  if (!getShadowRoot) return null;
  if (getShadowRoot === true) {
    return element.shadowRoot || null;
  }
  const result = getShadowRoot(element);
  return (result === true ? element.shadowRoot : result) || null;
}
function collectElementsWithShadowDOM(elements, getShadowRoot, filterFn) {
  const allElements = [...elements];
  const toProcess = [...elements];
  const processed = /* @__PURE__ */ new Set();
  const positionMap = /* @__PURE__ */ new Map();
  elements.forEach((el, i) => positionMap.set(el, i));
  let processIndex = 0;
  while (processIndex < toProcess.length) {
    const element = toProcess[processIndex++];
    if (!element || processed.has(element)) continue;
    processed.add(element);
    const shadowRoot = getShadowRootForNode(element, getShadowRoot);
    if (shadowRoot) {
      const shadowElements = Array.from(shadowRoot.querySelectorAll(focusableSelector)).filter(filterFn);
      const hostIndex = positionMap.get(element);
      if (hostIndex !== void 0) {
        const insertPosition = hostIndex + 1;
        allElements.splice(insertPosition, 0, ...shadowElements);
        shadowElements.forEach((el, i) => {
          positionMap.set(el, insertPosition + i);
        });
        for (let i = insertPosition + shadowElements.length; i < allElements.length; i++) {
          positionMap.set(allElements[i], i);
        }
      } else {
        const insertPosition = allElements.length;
        allElements.push(...shadowElements);
        shadowElements.forEach((el, i) => {
          positionMap.set(el, insertPosition + i);
        });
      }
      toProcess.push(...shadowElements);
    }
  }
  return allElements;
}
var focusableSelector = "input:not([type='hidden']):not([disabled]), select:not([disabled]), textarea:not([disabled]), a[href], button:not([disabled]), [tabindex], iframe, object, embed, area[href], audio[controls], video[controls], [contenteditable]:not([contenteditable='false']), details > summary:first-of-type";
function isFocusable(element) {
  if (!isHTMLElement(element) || element.closest("[inert]")) return false;
  return element.matches(focusableSelector) && isElementVisible(element);
}
function getTabbables(container, options = {}) {
  if (!container) return [];
  const { includeContainer, getShadowRoot } = options;
  const elements = Array.from(container.querySelectorAll(focusableSelector));
  if (includeContainer && isTabbable(container)) {
    elements.unshift(container);
  }
  const tabbableElements = [];
  for (const element of elements) {
    if (!isTabbable(element)) continue;
    if (isFrame(element) && element.contentDocument) {
      const frameBody = element.contentDocument.body;
      tabbableElements.push(...getTabbables(frameBody, { getShadowRoot }));
      continue;
    }
    tabbableElements.push(element);
  }
  if (getShadowRoot) {
    const allElements = collectElementsWithShadowDOM(tabbableElements, getShadowRoot, isTabbable);
    if (!allElements.length && includeContainer) {
      return elements;
    }
    return allElements;
  }
  if (!tabbableElements.length && includeContainer) {
    return elements;
  }
  return tabbableElements;
}
function isTabbable(el) {
  if (isHTMLElement(el) && el.tabIndex > 0) return true;
  if (!isFocusable(el) || hasNegativeTabIndex(el)) return false;
  return isTabbableRadio(el);
}
function getTabbableEdges(container, options = {}) {
  const elements = getTabbables(container, options);
  const first = elements[0] || null;
  const last = elements[elements.length - 1] || null;
  return [first, last];
}

// node_modules/@zag-js/dom-query/dist/initial-focus.mjs
function getInitialFocus(options) {
  const { root, getInitialEl, filter, enabled = true } = options;
  if (!enabled) return;
  let node = typeof getInitialEl === "function" ? getInitialEl() : getInitialEl;
  node || (node = root?.querySelector("[data-autofocus],[autofocus]"));
  if (!node) {
    const tabbables = getTabbables(root).filter((el) => filter ? filter(el) : true);
    node = tabbables.find((el) => !el.hasAttribute("data-no-autofocus"));
  }
  return node || root || void 0;
}
function isValidTabEvent(event) {
  const container = event.currentTarget;
  if (!container) return false;
  const [firstTabbable, lastTabbable] = getTabbableEdges(container);
  if (isActiveElement(firstTabbable) && event.shiftKey) return false;
  if (isActiveElement(lastTabbable) && !event.shiftKey) return false;
  if (!firstTabbable && !lastTabbable) return false;
  return true;
}

// node_modules/@zag-js/dom-query/dist/raf.mjs
var AnimationFrame = class _AnimationFrame {
  constructor() {
    __publicField2(this, "id", null);
    __publicField2(this, "fn_cleanup");
    __publicField2(this, "cleanup", () => {
      this.cancel();
    });
  }
  static create() {
    return new _AnimationFrame();
  }
  request(fn) {
    this.cancel();
    this.id = globalThis.requestAnimationFrame(() => {
      this.id = null;
      this.fn_cleanup = fn?.();
    });
  }
  cancel() {
    if (this.id !== null) {
      globalThis.cancelAnimationFrame(this.id);
      this.id = null;
    }
    this.fn_cleanup?.();
    this.fn_cleanup = void 0;
  }
  isActive() {
    return this.id !== null;
  }
};
function raf(fn) {
  const frame = AnimationFrame.create();
  frame.request(fn);
  return frame.cleanup;
}
function nextTick(fn) {
  const set = /* @__PURE__ */ new Set();
  function raf2(fn2) {
    const id = globalThis.requestAnimationFrame(fn2);
    set.add(() => globalThis.cancelAnimationFrame(id));
  }
  raf2(() => raf2(fn));
  return function cleanup() {
    set.forEach((fn2) => fn2());
  };
}

// node_modules/@zag-js/dom-query/dist/mutation-observer.mjs
function observeAttributesImpl(node, options) {
  if (!node) return;
  const { attributes, callback: fn } = options;
  const win = node.ownerDocument.defaultView || window;
  const obs = new win.MutationObserver((changes) => {
    for (const change of changes) {
      if (change.type === "attributes" && change.attributeName && attributes.includes(change.attributeName)) {
        fn(change);
      }
    }
  });
  obs.observe(node, { attributes: true, attributeFilter: attributes });
  return () => obs.disconnect();
}
function observeAttributes(nodeOrFn, options) {
  const { defer } = options;
  const func = defer ? raf : (v) => v();
  const cleanups = [];
  cleanups.push(
    func(() => {
      const node = typeof nodeOrFn === "function" ? nodeOrFn() : nodeOrFn;
      cleanups.push(observeAttributesImpl(node, options));
    })
  );
  return () => {
    cleanups.forEach((fn) => fn?.());
  };
}

// node_modules/@zag-js/dom-query/dist/overflow.mjs
function getNearestOverflowAncestor(el) {
  const parentNode = getParentNode(el);
  if (isRootElement(parentNode)) return getDocument(parentNode).body;
  if (isHTMLElement(parentNode) && isOverflowElement(parentNode)) return parentNode;
  return getNearestOverflowAncestor(parentNode);
}
var OVERFLOW_RE = /auto|scroll|overlay|hidden|clip/;
var nonOverflowValues = /* @__PURE__ */ new Set(["inline", "contents"]);
function isOverflowElement(el) {
  const win = getWindow(el);
  const { overflow, overflowX, overflowY, display } = win.getComputedStyle(el);
  return OVERFLOW_RE.test(overflow + overflowY + overflowX) && !nonOverflowValues.has(display);
}

// node_modules/@zag-js/dom-query/dist/query.mjs
var defaultItemToId = (v) => v.id;
function itemById(v, id, itemToId = defaultItemToId) {
  return v.find((item) => itemToId(item) === id);
}
function indexOfId(v, id, itemToId = defaultItemToId) {
  const item = itemById(v, id, itemToId);
  return item ? v.indexOf(item) : -1;
}

// node_modules/@zag-js/dom-query/dist/scroll.mjs
function isScrollable(el) {
  return el.scrollHeight > el.clientHeight || el.scrollWidth > el.clientWidth;
}
function scrollIntoView(el, options) {
  const { rootEl, ...scrollOptions } = options || {};
  if (!el || !rootEl) return;
  if (!isOverflowElement(rootEl) || !isScrollable(rootEl)) return;
  el.scrollIntoView(scrollOptions);
}

// node_modules/@zag-js/dom-query/dist/searchable.mjs
var sanitize = (str) => str.split("").map((char) => {
  const code = char.charCodeAt(0);
  if (code > 0 && code < 128) return char;
  if (code >= 128 && code <= 255) return `/x${code.toString(16)}`.replace("/", "\\");
  return "";
}).join("").trim();
var getValueText = (el) => {
  return sanitize(el.dataset?.valuetext ?? el.textContent ?? "");
};
var match2 = (valueText, query) => {
  return valueText.trim().toLowerCase().startsWith(query.toLowerCase());
};
function getByText(v, text, currentId, itemToId = defaultItemToId) {
  const index = currentId ? indexOfId(v, currentId, itemToId) : -1;
  let items = currentId ? wrap(v, index) : v;
  const isSingleKey = text.length === 1;
  if (isSingleKey) {
    items = items.filter((item) => itemToId(item) !== currentId);
  }
  return items.find((item) => match2(getValueText(item), text));
}

// node_modules/@zag-js/dom-query/dist/set.mjs
function setStyle(el, style) {
  if (!el) return noop2;
  const prev = Object.keys(style).reduce((acc, key) => {
    acc[key] = el.style.getPropertyValue(key);
    return acc;
  }, {});
  if (isEqual2(prev, style)) return noop2;
  Object.assign(el.style, style);
  return () => {
    Object.assign(el.style, prev);
    if (el.style.length === 0) {
      el.removeAttribute("style");
    }
  };
}
function isEqual2(a, b) {
  return Object.keys(a).every((key) => a[key] === b[key]);
}

// node_modules/@zag-js/dom-query/dist/typeahead.mjs
function getByTypeaheadImpl(baseItems, options) {
  const { state, activeId, key, timeout = 350, itemToId } = options;
  const search = state.keysSoFar + key;
  const isRepeated = search.length > 1 && Array.from(search).every((char) => char === search[0]);
  const query = isRepeated ? search[0] : search;
  let items = baseItems.slice();
  const next = getByText(items, query, activeId, itemToId);
  function cleanup() {
    clearTimeout(state.timer);
    state.timer = -1;
  }
  function update(value) {
    state.keysSoFar = value;
    cleanup();
    if (value !== "") {
      state.timer = +setTimeout(() => {
        update("");
        cleanup();
      }, timeout);
    }
  }
  update(search);
  return next;
}
var getByTypeahead = /* @__PURE__ */ Object.assign(getByTypeaheadImpl, {
  defaultOptions: { keysSoFar: "", timer: -1 },
  isValidEvent: isValidTypeaheadEvent
});
function isValidTypeaheadEvent(event) {
  return event.key.length === 1 && !event.ctrlKey && !event.metaKey;
}

// node_modules/@zag-js/dom-query/dist/visually-hidden.mjs
var visuallyHiddenStyle = {
  border: "0",
  clip: "rect(0 0 0 0)",
  height: "1px",
  margin: "-1px",
  overflow: "hidden",
  padding: "0",
  position: "absolute",
  width: "1px",
  whiteSpace: "nowrap",
  wordWrap: "normal"
};

// node_modules/@zag-js/dom-query/dist/wait-for.mjs
function waitForPromise(promise, controller, timeout) {
  const { signal } = controller;
  const wrappedPromise = new Promise((resolve, reject) => {
    const timeoutId = setTimeout(() => {
      reject(new Error(`Timeout of ${timeout}ms exceeded`));
    }, timeout);
    signal.addEventListener("abort", () => {
      clearTimeout(timeoutId);
      reject(new DOMException("Promise aborted", "AbortError"));
    });
    promise.then((result) => {
      if (!signal.aborted) {
        clearTimeout(timeoutId);
        resolve(result);
      }
    }).catch((error) => {
      if (!signal.aborted) {
        clearTimeout(timeoutId);
        reject(error);
      }
    });
  });
  const abort = () => controller.abort();
  return [wrappedPromise, abort];
}
function waitForElement(target, options) {
  const { timeout, rootNode } = options;
  const win = getWindow(rootNode);
  const doc = getDocument(rootNode);
  const controller = new win.AbortController();
  return waitForPromise(
    new Promise((resolve) => {
      const el = target();
      if (el) {
        resolve(el);
        return;
      }
      const observer = new win.MutationObserver(() => {
        const el2 = target();
        if (el2 && el2.isConnected) {
          observer.disconnect();
          resolve(el2);
        }
      });
      observer.observe(doc.body, {
        childList: true,
        subtree: true
      });
    }),
    controller,
    timeout
  );
}

// node_modules/@zag-js/dom-query/dist/when-node.mjs
function whenNode(nodeOrFn, fn, options = {}) {
  const { defer, onMissing } = options;
  const getNode = () => typeof nodeOrFn === "function" ? nodeOrFn() : nodeOrFn;
  const cleanups = [];
  const setup = (node) => {
    if (!node) return onMissing?.();
    cleanups.push(fn(node));
  };
  if (!defer) {
    setup(getNode());
  } else {
    let cancelled = false;
    cleanups.push(() => {
      cancelled = true;
    });
    queueMicrotask(() => {
      if (cancelled) return;
      const committed = getNode();
      if (committed) {
        setup(committed);
        return;
      }
      cleanups.push(
        raf(() => {
          if (cancelled) return;
          setup(getNode());
        })
      );
    });
  }
  return () => {
    cleanups.forEach((fn2) => fn2?.());
  };
}

// node_modules/@zag-js/focus-visible/dist/index.mjs
function isValidKey(e) {
  return !(e.metaKey || !isMac() && e.altKey || e.ctrlKey || e.key === "Control" || e.key === "Shift" || e.key === "Meta");
}
var nonTextInputTypes = /* @__PURE__ */ new Set(["checkbox", "radio", "range", "color", "file", "image", "button", "submit", "reset"]);
var interactiveContentSelector = [
  "a[href]",
  "audio[controls]",
  "button",
  "details",
  "embed",
  "iframe",
  "img[controls]",
  "img[usemap]",
  "input",
  "select",
  "textarea",
  "video[controls]"
].join(",");
function isKeyboardFocusEvent(isTextInput, modality, e) {
  const eventTarget = e ? getEventTarget(e) : null;
  const doc = getDocument(eventTarget);
  const win = getWindow(eventTarget);
  const activeElement = getActiveElement(doc);
  isTextInput = isTextInput || activeElement instanceof win.HTMLInputElement && !nonTextInputTypes.has(activeElement?.type) || activeElement instanceof win.HTMLTextAreaElement || activeElement instanceof win.HTMLElement && activeElement.isContentEditable;
  return !(isTextInput && modality === "keyboard" && e instanceof win.KeyboardEvent && !Reflect.has(FOCUS_VISIBLE_INPUT_KEYS, e.key));
}
var currentModality = null;
var changeHandlers = /* @__PURE__ */ new Set();
var listenerMap = /* @__PURE__ */ new Map();
var hasEventBeforeFocus = false;
var pendingLabelControl = null;
var hasBlurredWindowRecently = false;
var lastPointerPosition = null;
var ignoreFocusEvent = false;
var FOCUS_VISIBLE_INPUT_KEYS = {
  Tab: true,
  Escape: true
};
function triggerChangeHandlers(modality, e) {
  for (let handler of changeHandlers) {
    handler(modality, e);
  }
}
function handleKeyboardEvent(e) {
  pendingLabelControl = null;
  hasEventBeforeFocus = true;
  if (isValidKey(e)) {
    currentModality = "keyboard";
    triggerChangeHandlers("keyboard", e);
  }
}
function handlePointerEvent(e) {
  const isMove = e.type === "pointermove" || e.type === "mousemove";
  if (isMove && e.isTrusted && lastPointerPosition?.x === e.clientX && lastPointerPosition?.y === e.clientY) return;
  lastPointerPosition = { x: e.clientX, y: e.clientY };
  currentModality = "pointer";
  if (e.type === "mousedown" || e.type === "pointerdown") {
    pendingLabelControl = null;
    hasEventBeforeFocus = true;
    triggerChangeHandlers("pointer", e);
  }
}
function handleClickEvent(e) {
  if (isVirtualClick(e)) {
    pendingLabelControl = null;
    hasEventBeforeFocus = true;
    currentModality = "virtual";
    return;
  }
  pendingLabelControl = null;
  const target = getEventTarget(e);
  const label = target?.closest("label");
  const control = label?.control;
  if (!label || !control || control.matches(":disabled")) return;
  const interactive = target?.closest(interactiveContentSelector);
  if (interactive && label.contains(interactive) && interactive !== control) return;
  if (control !== getActiveElement(label.ownerDocument)) pendingLabelControl = control;
}
function handleFocusEvent(e) {
  const target = getEventTarget(e);
  const isLabelActivationFocus = target === pendingLabelControl;
  if (target === getWindow(target) || target === getDocument(target) || ignoreFocusEvent || !e.isTrusted) {
    return;
  }
  if (!hasEventBeforeFocus && !isLabelActivationFocus && !hasBlurredWindowRecently) {
    currentModality = "virtual";
    triggerChangeHandlers("virtual", e);
  }
  hasEventBeforeFocus = false;
  pendingLabelControl = null;
  hasBlurredWindowRecently = false;
}
function handleWindowBlur() {
  if (ignoreFocusEvent) return;
  hasEventBeforeFocus = false;
  pendingLabelControl = null;
  hasBlurredWindowRecently = true;
}
function setupGlobalFocusEvents(root) {
  if (typeof window === "undefined" || listenerMap.get(getWindow(root))) {
    return;
  }
  const win = getWindow(root);
  const doc = getDocument(root);
  let focus = win.HTMLElement.prototype.focus;
  function patchedFocus() {
    hasEventBeforeFocus = true;
    focus.apply(this, arguments);
  }
  try {
    Object.defineProperty(win.HTMLElement.prototype, "focus", {
      configurable: true,
      value: patchedFocus
    });
  } catch {
  }
  doc.addEventListener("keydown", handleKeyboardEvent, true);
  doc.addEventListener("keyup", handleKeyboardEvent, true);
  doc.addEventListener("click", handleClickEvent, true);
  win.addEventListener("focus", handleFocusEvent, true);
  win.addEventListener("blur", handleWindowBlur, false);
  if (typeof win.PointerEvent !== "undefined") {
    doc.addEventListener("pointerdown", handlePointerEvent, true);
    doc.addEventListener("pointermove", handlePointerEvent, true);
    doc.addEventListener("pointerup", handlePointerEvent, true);
  } else {
    doc.addEventListener("mousedown", handlePointerEvent, true);
    doc.addEventListener("mousemove", handlePointerEvent, true);
    doc.addEventListener("mouseup", handlePointerEvent, true);
  }
  win.addEventListener(
    "beforeunload",
    () => {
      tearDownWindowFocusTracking(root);
    },
    { once: true }
  );
  listenerMap.set(win, { focus });
}
var tearDownWindowFocusTracking = (root, loadListener) => {
  const win = getWindow(root);
  const doc = getDocument(root);
  if (loadListener) {
    doc.removeEventListener("DOMContentLoaded", loadListener);
  }
  const listenerData = listenerMap.get(win);
  if (!listenerData) {
    return;
  }
  try {
    Object.defineProperty(win.HTMLElement.prototype, "focus", {
      configurable: true,
      value: listenerData.focus
    });
  } catch {
  }
  doc.removeEventListener("keydown", handleKeyboardEvent, true);
  doc.removeEventListener("keyup", handleKeyboardEvent, true);
  doc.removeEventListener("click", handleClickEvent, true);
  win.removeEventListener("focus", handleFocusEvent, true);
  win.removeEventListener("blur", handleWindowBlur, false);
  if (typeof win.PointerEvent !== "undefined") {
    doc.removeEventListener("pointerdown", handlePointerEvent, true);
    doc.removeEventListener("pointermove", handlePointerEvent, true);
    doc.removeEventListener("pointerup", handlePointerEvent, true);
  } else {
    doc.removeEventListener("mousedown", handlePointerEvent, true);
    doc.removeEventListener("mousemove", handlePointerEvent, true);
    doc.removeEventListener("mouseup", handlePointerEvent, true);
  }
  listenerMap.delete(win);
};
function getInteractionModality() {
  return currentModality;
}
function setInteractionModality(modality) {
  currentModality = modality;
  triggerChangeHandlers(modality, null);
}
function isFocusVisible() {
  return currentModality === "keyboard" || currentModality === "virtual";
}
function trackFocusVisible(props = {}) {
  const { isTextInput, autoFocus, onChange, root } = props;
  setupGlobalFocusEvents(root);
  onChange?.({ isFocusVisible: autoFocus || isFocusVisible(), modality: currentModality });
  const handler = (modality, e) => {
    if (!isKeyboardFocusEvent(!!isTextInput, modality, e)) return;
    onChange?.({ isFocusVisible: isFocusVisible(), modality });
  };
  changeHandlers.add(handler);
  return () => {
    changeHandlers.delete(handler);
  };
}

// node_modules/@floating-ui/utils/dist/floating-ui.utils.mjs
var sides = ["top", "right", "bottom", "left"];
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
var arrow = (options) => ({
  name: "arrow",
  options,
  async fn(state) {
    const {
      x,
      y,
      placement,
      rects,
      platform: platform2,
      elements,
      middlewareData
    } = state;
    const {
      element,
      padding = 0
    } = evaluate(options, state) || {};
    if (element == null) {
      return {};
    }
    const paddingObject = getPaddingObject(padding);
    const coords = {
      x,
      y
    };
    const axis = getAlignmentAxis(placement);
    const length = getAxisLength(axis);
    const arrowDimensions = await platform2.getDimensions(element);
    const isYAxis = axis === "y";
    const minProp = isYAxis ? "top" : "left";
    const maxProp = isYAxis ? "bottom" : "right";
    const clientProp = isYAxis ? "clientHeight" : "clientWidth";
    const endDiff = rects.reference[length] + rects.reference[axis] - coords[axis] - rects.floating[length];
    const startDiff = coords[axis] - rects.reference[axis];
    const arrowOffsetParent = await (platform2.getOffsetParent == null ? void 0 : platform2.getOffsetParent(element));
    let clientSize = arrowOffsetParent ? arrowOffsetParent[clientProp] : 0;
    if (!clientSize || !await (platform2.isElement == null ? void 0 : platform2.isElement(arrowOffsetParent))) {
      clientSize = elements.floating[clientProp] || rects.floating[length];
    }
    const centerToReference = endDiff / 2 - startDiff / 2;
    const largestPossiblePadding = clientSize / 2 - arrowDimensions[length] / 2 - 1;
    const minPadding = min(paddingObject[minProp], largestPossiblePadding);
    const maxPadding = min(paddingObject[maxProp], largestPossiblePadding);
    const max2 = clientSize - arrowDimensions[length] - maxPadding;
    const center = clientSize / 2 - arrowDimensions[length] / 2 + centerToReference;
    const offset3 = clamp(minPadding, center, max2);
    const shouldAddOffset = !middlewareData.arrow && getAlignment(placement) != null && center !== offset3 && rects.reference[length] / 2 - (center < minPadding ? minPadding : maxPadding) - arrowDimensions[length] / 2 < 0;
    const alignmentOffset = shouldAddOffset ? center < minPadding ? center - minPadding : center - max2 : 0;
    return {
      [axis]: coords[axis] + alignmentOffset,
      data: {
        [axis]: offset3,
        centerOffset: center - offset3 - alignmentOffset,
        ...shouldAddOffset && {
          alignmentOffset
        }
      },
      reset: shouldAddOffset
    };
  }
});
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
function getSideOffsets(overflow, rect) {
  return {
    top: overflow.top - rect.height,
    right: overflow.right - rect.width,
    bottom: overflow.bottom - rect.height,
    left: overflow.left - rect.width
  };
}
function isAnySideFullyClipped(overflow) {
  return sides.some((side) => overflow[side] >= 0);
}
var hide = function(options) {
  if (options === void 0) {
    options = {};
  }
  return {
    name: "hide",
    options,
    async fn(state) {
      const {
        rects,
        platform: platform2
      } = state;
      const {
        strategy = "referenceHidden",
        ...detectOverflowOptions
      } = evaluate(options, state);
      switch (strategy) {
        case "referenceHidden": {
          const overflow = await platform2.detectOverflow(state, {
            ...detectOverflowOptions,
            elementContext: "reference"
          });
          const offsets = getSideOffsets(overflow, rects.reference);
          return {
            data: {
              referenceHiddenOffsets: offsets,
              referenceHidden: isAnySideFullyClipped(offsets)
            }
          };
        }
        case "escaped": {
          const overflow = await platform2.detectOverflow(state, {
            ...detectOverflowOptions,
            altBoundary: true
          });
          const offsets = getSideOffsets(overflow, rects.floating);
          return {
            data: {
              escapedOffsets: offsets,
              escaped: isAnySideFullyClipped(offsets)
            }
          };
        }
        default: {
          return {};
        }
      }
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
var limitShift = function(options) {
  if (options === void 0) {
    options = {};
  }
  return {
    options,
    fn(state) {
      var _rawOffset$mainAxis, _rawOffset$crossAxis;
      const {
        x,
        y,
        placement,
        rects,
        middlewareData
      } = state;
      const {
        offset: offset3 = 0,
        mainAxis: checkMainAxis = true,
        crossAxis: checkCrossAxis = true
      } = evaluate(options, state);
      const coords = {
        x,
        y
      };
      const crossAxis = getSideAxis(placement);
      const mainAxis = getOppositeAxis(crossAxis);
      let mainAxisCoord = coords[mainAxis];
      let crossAxisCoord = coords[crossAxis];
      const rawOffset = evaluate(offset3, state);
      const computedOffset = typeof rawOffset === "number" ? {
        mainAxis: rawOffset,
        crossAxis: 0
      } : {
        mainAxis: (_rawOffset$mainAxis = rawOffset.mainAxis) != null ? _rawOffset$mainAxis : 0,
        crossAxis: (_rawOffset$crossAxis = rawOffset.crossAxis) != null ? _rawOffset$crossAxis : 0
      };
      if (checkMainAxis) {
        const len = mainAxis === "y" ? "height" : "width";
        const limitMin = rects.reference[mainAxis] - rects.floating[len] + computedOffset.mainAxis;
        const limitMax = rects.reference[mainAxis] + rects.reference[len] - computedOffset.mainAxis;
        if (mainAxisCoord < limitMin) {
          mainAxisCoord = limitMin;
        } else if (mainAxisCoord > limitMax) {
          mainAxisCoord = limitMax;
        }
      }
      if (checkCrossAxis) {
        var _middlewareData$offse, _middlewareData$offse2;
        const len = mainAxis === "y" ? "width" : "height";
        const isOriginSide = originSides.has(getSide(placement));
        const limitMin = rects.reference[crossAxis] - rects.floating[len] + (isOriginSide ? ((_middlewareData$offse = middlewareData.offset) == null ? void 0 : _middlewareData$offse[crossAxis]) || 0 : 0) + (isOriginSide ? 0 : computedOffset.crossAxis);
        const limitMax = rects.reference[crossAxis] + rects.reference[len] + (isOriginSide ? 0 : ((_middlewareData$offse2 = middlewareData.offset) == null ? void 0 : _middlewareData$offse2[crossAxis]) || 0) - (isOriginSide ? computedOffset.crossAxis : 0);
        if (crossAxisCoord < limitMin) {
          crossAxisCoord = limitMin;
        } else if (crossAxisCoord > limitMax) {
          crossAxisCoord = limitMax;
        }
      }
      return {
        [mainAxis]: mainAxisCoord,
        [crossAxis]: crossAxisCoord
      };
    }
  };
};
var size = function(options) {
  if (options === void 0) {
    options = {};
  }
  return {
    name: "size",
    options,
    async fn(state) {
      const {
        placement,
        rects,
        platform: platform2,
        elements
      } = state;
      const {
        apply = () => {
        },
        ...detectOverflowOptions
      } = evaluate(options, state);
      const overflow = await platform2.detectOverflow(state, detectOverflowOptions);
      const side = getSide(placement);
      const alignment = getAlignment(placement);
      const isYAxis = getSideAxis(placement) === "y";
      const {
        width,
        height
      } = rects.floating;
      let heightSide;
      let widthSide;
      if (side === "top" || side === "bottom") {
        heightSide = side;
        widthSide = alignment === (await (platform2.isRTL == null ? void 0 : platform2.isRTL(elements.floating)) ? "start" : "end") ? "left" : "right";
      } else {
        widthSide = side;
        heightSide = alignment === "end" ? "top" : "bottom";
      }
      const maximumClippingHeight = height - overflow.top - overflow.bottom;
      const maximumClippingWidth = width - overflow.left - overflow.right;
      const overflowAvailableHeight = min(height - overflow[heightSide], maximumClippingHeight);
      const overflowAvailableWidth = min(width - overflow[widthSide], maximumClippingWidth);
      const shiftData = state.middlewareData.shift;
      const noShift = !shiftData;
      let availableHeight = overflowAvailableHeight;
      let availableWidth = overflowAvailableWidth;
      if (shiftData != null && shiftData.enabled.x) {
        availableWidth = maximumClippingWidth;
      }
      if (shiftData != null && shiftData.enabled.y) {
        availableHeight = maximumClippingHeight;
      }
      if (noShift && !alignment) {
        if (isYAxis) {
          availableWidth = width - 2 * max(overflow.left, overflow.right);
        } else {
          availableHeight = height - 2 * max(overflow.top, overflow.bottom);
        }
      }
      await apply({
        ...state,
        availableWidth,
        availableHeight
      });
      const nextDimensions = await platform2.getDimensions(elements.floating);
      if (width !== nextDimensions.width || height !== nextDimensions.height) {
        return {
          reset: {
            rects: true
          }
        };
      }
      return {};
    }
  };
};

// node_modules/@floating-ui/utils/dist/floating-ui.utils.dom.mjs
function hasWindow() {
  return typeof window !== "undefined";
}
function getNodeName2(node) {
  if (isNode2(node)) {
    return (node.nodeName || "").toLowerCase();
  }
  return "#document";
}
function getWindow2(node) {
  var _node$ownerDocument;
  return (node == null || (_node$ownerDocument = node.ownerDocument) == null ? void 0 : _node$ownerDocument.defaultView) || window;
}
function getDocumentElement2(node) {
  var _ref;
  return (_ref = (isNode2(node) ? node.ownerDocument : node.document) || window.document) == null ? void 0 : _ref.documentElement;
}
function isNode2(value) {
  if (!hasWindow()) {
    return false;
  }
  return value instanceof Node || value instanceof getWindow2(value).Node;
}
function isElement(value) {
  if (!hasWindow()) {
    return false;
  }
  return value instanceof Element || value instanceof getWindow2(value).Element;
}
function isHTMLElement2(value) {
  if (!hasWindow()) {
    return false;
  }
  return value instanceof HTMLElement || value instanceof getWindow2(value).HTMLElement;
}
function isShadowRoot2(value) {
  if (!hasWindow() || typeof ShadowRoot === "undefined") {
    return false;
  }
  return value instanceof ShadowRoot || value instanceof getWindow2(value).ShadowRoot;
}
function isOverflowElement2(element) {
  const {
    overflow,
    overflowX,
    overflowY,
    display
  } = getComputedStyle3(element);
  return /auto|scroll|overlay|hidden|clip/.test(overflow + overflowY + overflowX) && display !== "inline" && display !== "contents";
}
function isTableElement(element) {
  return /^(table|td|th)$/.test(getNodeName2(element));
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
  const css = isElement(elementOrCss) ? getComputedStyle3(elementOrCss) : elementOrCss;
  return isNotNone(css.transform) || isNotNone(css.translate) || isNotNone(css.scale) || isNotNone(css.rotate) || isNotNone(css.perspective) || !isWebKit() && (isNotNone(css.backdropFilter) || isNotNone(css.filter)) || willChangeRe.test(css.willChange || "") || containRe.test(css.contain || "");
}
function getContainingBlock(element) {
  let currentNode = getParentNode2(element);
  while (isHTMLElement2(currentNode) && !isLastTraversableNode(currentNode)) {
    if (isContainingBlock(currentNode)) {
      return currentNode;
    } else if (isTopLayer(currentNode)) {
      return null;
    }
    currentNode = getParentNode2(currentNode);
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
  return /^(html|body|#document)$/.test(getNodeName2(node));
}
function getComputedStyle3(element) {
  return getWindow2(element).getComputedStyle(element);
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
function getParentNode2(node) {
  if (getNodeName2(node) === "html") {
    return node;
  }
  const result = (
    // Step into the shadow DOM of the parent of a slotted node.
    node.assignedSlot || // DOM Element detected.
    node.parentNode || // ShadowRoot detected.
    isShadowRoot2(node) && node.host || // Fallback.
    getDocumentElement2(node)
  );
  return isShadowRoot2(result) ? result.host : result;
}
function getNearestOverflowAncestor2(node) {
  const parentNode = getParentNode2(node);
  if (isLastTraversableNode(parentNode)) {
    return (node.ownerDocument || node).body;
  }
  if (isHTMLElement2(parentNode) && isOverflowElement2(parentNode)) {
    return parentNode;
  }
  return getNearestOverflowAncestor2(parentNode);
}
function getOverflowAncestors(node, list, traverseIframes) {
  var _node$ownerDocument2;
  if (list === void 0) {
    list = [];
  }
  if (traverseIframes === void 0) {
    traverseIframes = true;
  }
  const scrollableAncestor = getNearestOverflowAncestor2(node);
  const isBody = scrollableAncestor === ((_node$ownerDocument2 = node.ownerDocument) == null ? void 0 : _node$ownerDocument2.body);
  const win = getWindow2(scrollableAncestor);
  if (isBody) {
    const frameElement = getFrameElement(win);
    return list.concat(win, win.visualViewport || [], isOverflowElement2(scrollableAncestor) ? scrollableAncestor : [], frameElement && traverseIframes ? getOverflowAncestors(frameElement) : []);
  } else {
    return list.concat(scrollableAncestor, getOverflowAncestors(scrollableAncestor, [], traverseIframes));
  }
}
function getFrameElement(win) {
  return win.parent && Object.getPrototypeOf(win.parent) ? win.frameElement : null;
}

// node_modules/@floating-ui/dom/dist/floating-ui.dom.mjs
function getCssDimensions(element) {
  const css = getComputedStyle3(element);
  let width = parseFloat(css.width) || 0;
  let height = parseFloat(css.height) || 0;
  const hasOffset = isHTMLElement2(element);
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
  if (!isHTMLElement2(domElement)) {
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
  const win = getWindow2(element);
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
  return !!floatingOffsetParent && isFixed && floatingOffsetParent === getWindow2(element);
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
    const win = getWindow2(domElement);
    const offsetWin = isElement(offsetParent) ? getWindow2(offsetParent) : offsetParent;
    let currentWin = win;
    let currentIFrame = getFrameElement(currentWin);
    while (currentIFrame && offsetWin !== currentWin) {
      const iframeScale = getScale(currentIFrame);
      const iframeRect = currentIFrame.getBoundingClientRect();
      const css = getComputedStyle3(currentIFrame);
      const left = iframeRect.left + (currentIFrame.clientLeft + parseFloat(css.paddingLeft)) * iframeScale.x;
      const top = iframeRect.top + (currentIFrame.clientTop + parseFloat(css.paddingTop)) * iframeScale.y;
      x *= iframeScale.x;
      y *= iframeScale.y;
      width *= iframeScale.x;
      height *= iframeScale.y;
      x += left;
      y += top;
      currentWin = getWindow2(currentIFrame);
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
    return getBoundingClientRect(getDocumentElement2(element)).left + leftScroll;
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
  const documentElement = getDocumentElement2(offsetParent);
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
  const isOffsetParentAnElement = isHTMLElement2(offsetParent);
  if (isOffsetParentAnElement || !isFixed) {
    if (getNodeName2(offsetParent) !== "body" || isOverflowElement2(documentElement)) {
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
  if (getComputedStyle3(body).direction === "rtl") {
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
  const win = getWindow2(element);
  const html = getDocumentElement2(element);
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
    rect = getDocumentRect(getDocumentElement2(element));
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
  let result = getOverflowAncestors(element, [], false).filter((el) => isElement(el) && getNodeName2(el) !== "body");
  let lastKeptComputedStyle = null;
  const elementIsFixed = getComputedStyle3(element).position === "fixed";
  let currentNode = elementIsFixed ? getParentNode2(element) : element;
  while (isElement(currentNode) && !isLastTraversableNode(currentNode)) {
    const computedStyle = getComputedStyle3(currentNode);
    const currentNodeIsContaining = isContainingBlock(currentNode);
    const lastPosition = lastKeptComputedStyle ? lastKeptComputedStyle.position : elementIsFixed ? "fixed" : "";
    const shouldDropCurrentNode = !currentNodeIsContaining && (lastPosition === "fixed" || lastPosition === "absolute" && computedStyle.position === "static");
    if (shouldDropCurrentNode) {
      result = result.filter((ancestor) => ancestor !== currentNode);
    } else {
      lastKeptComputedStyle = computedStyle;
    }
    currentNode = getParentNode2(currentNode);
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
  const isOffsetParentAnElement = isHTMLElement2(offsetParent);
  const documentElement = getDocumentElement2(offsetParent);
  const isFixed = strategy === "fixed";
  const rect = getBoundingClientRect(element, true, isFixed, offsetParent);
  let scroll = {
    scrollLeft: 0,
    scrollTop: 0
  };
  const offsets = createCoords(0);
  if (isOffsetParentAnElement || !isFixed) {
    if (getNodeName2(offsetParent) !== "body" || isOverflowElement2(documentElement)) {
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
  return getComputedStyle3(element).position === "static";
}
function getTrueOffsetParent(element, polyfill) {
  if (!isHTMLElement2(element) || getComputedStyle3(element).position === "fixed") {
    return null;
  }
  if (polyfill) {
    return polyfill(element);
  }
  let rawOffsetParent = element.offsetParent;
  if (getDocumentElement2(element) === rawOffsetParent) {
    rawOffsetParent = rawOffsetParent.ownerDocument.body;
  }
  return rawOffsetParent;
}
function getOffsetParent(element, polyfill) {
  const win = getWindow2(element);
  if (isTopLayer(element)) {
    return win;
  }
  if (!isHTMLElement2(element)) {
    let svgOffsetParent = getParentNode2(element);
    while (svgOffsetParent && !isLastTraversableNode(svgOffsetParent)) {
      if (isElement(svgOffsetParent) && !isStaticPositioned(svgOffsetParent)) {
        return svgOffsetParent;
      }
      svgOffsetParent = getParentNode2(svgOffsetParent);
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
  return getComputedStyle3(element).direction === "rtl";
}
var platform = {
  convertOffsetParentRelativeRectToViewportRelativeRect,
  getDocumentElement: getDocumentElement2,
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
  const root = getDocumentElement2(element);
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
  const win = getWindow2(element);
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
var size2 = size;
var hide2 = hide;
var arrow2 = arrow;
var limitShift2 = limitShift;
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

// node_modules/@zag-js/popper/dist/get-anchor.mjs
function createDOMRect(x = 0, y = 0, width = 0, height = 0) {
  if (typeof DOMRect === "function") {
    return new DOMRect(x, y, width, height);
  }
  const rect = {
    x,
    y,
    width,
    height,
    top: y,
    right: x + width,
    bottom: y + height,
    left: x
  };
  return { ...rect, toJSON: () => rect };
}
function getDOMRect(anchorRect) {
  if (!anchorRect) return createDOMRect();
  const { x, y, width, height } = anchorRect;
  return createDOMRect(x, y, width, height);
}
function getAnchorElement(anchorElement, getAnchorRect) {
  return {
    contextElement: isHTMLElement(anchorElement) ? anchorElement : anchorElement?.contextElement,
    getBoundingClientRect: () => {
      const anchor = anchorElement;
      const anchorRect = getAnchorRect?.(anchor);
      if (anchorRect || !anchor) {
        return getDOMRect(anchorRect);
      }
      return anchor.getBoundingClientRect();
    }
  };
}

// node_modules/@zag-js/popper/dist/middleware.mjs
var toVar = (value) => ({ variable: value, reference: `var(${value})` });
var cssVars = {
  arrowSize: toVar("--arrow-size"),
  arrowSizeHalf: toVar("--arrow-size-half"),
  arrowBg: toVar("--arrow-background"),
  transformOrigin: toVar("--transform-origin"),
  arrowOffset: toVar("--arrow-offset")
};
var getSideAxis2 = (side) => side === "top" || side === "bottom" ? "y" : "x";
function createTransformOriginMiddleware(opts, arrowEl) {
  return {
    name: "transformOrigin",
    fn(state) {
      const { elements, middlewareData, placement, rects, y } = state;
      const side = placement.split("-")[0];
      const axis = getSideAxis2(side);
      const arrowX = middlewareData.arrow?.x || 0;
      const arrowY = middlewareData.arrow?.y || 0;
      const arrowWidth = arrowEl?.clientWidth || 0;
      const arrowHeight = arrowEl?.clientHeight || 0;
      const transformX = arrowX + arrowWidth / 2;
      const transformY = arrowY + arrowHeight / 2;
      const shiftY = Math.abs(middlewareData.shift?.y || 0);
      const halfAnchorHeight = rects.reference.height / 2;
      const arrowOffset = arrowHeight / 2;
      const gutter = opts.offset?.mainAxis ?? opts.gutter;
      const sideOffsetValue = typeof gutter === "number" ? gutter + arrowOffset : gutter ?? arrowOffset;
      const isOverlappingAnchor = shiftY > sideOffsetValue;
      const adjacentTransformOrigin = {
        top: `${transformX}px calc(100% + ${sideOffsetValue}px)`,
        bottom: `${transformX}px ${-sideOffsetValue}px`,
        left: `calc(100% + ${sideOffsetValue}px) ${transformY}px`,
        right: `${-sideOffsetValue}px ${transformY}px`
      }[side];
      const overlapTransformOrigin = `${transformX}px ${rects.reference.y + halfAnchorHeight - y}px`;
      const useOverlap = Boolean(opts.overlap) && axis === "y" && isOverlappingAnchor;
      elements.floating.style.setProperty(
        cssVars.transformOrigin.variable,
        useOverlap ? overlapTransformOrigin : adjacentTransformOrigin
      );
      return {
        data: {
          transformOrigin: useOverlap ? overlapTransformOrigin : adjacentTransformOrigin
        }
      };
    }
  };
}
var rectMiddleware = {
  name: "rects",
  fn({ rects }) {
    return {
      data: rects
    };
  }
};
var shiftArrowMiddleware = (arrowEl) => {
  if (!arrowEl) return;
  return {
    name: "shiftArrow",
    fn({ placement, middlewareData }) {
      if (!middlewareData.arrow) return {};
      const { x, y } = middlewareData.arrow;
      const dir = placement.split("-")[0];
      Object.assign(arrowEl.style, {
        left: x != null ? `${x}px` : "",
        top: y != null ? `${y}px` : "",
        [dir]: `calc(100% + ${cssVars.arrowOffset.reference})`
      });
      return {};
    }
  };
};

// node_modules/@zag-js/popper/dist/placement.mjs
function getPlacementDetails(placement) {
  const [side, align] = placement.split("-");
  return { side, align, hasAlign: align != null };
}
function getPlacementSide(placement) {
  return placement.split("-")[0];
}

// node_modules/@zag-js/popper/dist/get-placement.mjs
var defaultOptions = {
  strategy: "absolute",
  placement: "bottom",
  listeners: true,
  restoreStyles: false,
  applyStyles: true,
  gutter: 8,
  flip: true,
  slide: true,
  overlap: false,
  sameWidth: false,
  fitViewport: false,
  overflowPadding: 8,
  arrowPadding: 4
};
function roundByDpr(win, value) {
  const dpr = win.devicePixelRatio || 1;
  return Math.round(value * dpr) / dpr;
}
function isApproximatelyEqual(a, b) {
  return a != null && Math.abs(a - b) < 0.5;
}
function resolveBoundaryOption(boundary) {
  if (typeof boundary === "function") return boundary();
  if (boundary === "clipping-ancestors") return "clippingAncestors";
  return boundary;
}
function getArrowMiddleware(arrowElement, doc, opts) {
  const element = arrowElement || doc.createElement("div");
  return arrow2({ element, padding: opts.arrowPadding });
}
function getOffsetMiddleware(arrowElement, opts) {
  if (isNull(opts.offset ?? opts.gutter)) return;
  return offset2(({ placement }) => {
    const arrowOffset = (arrowElement?.clientHeight || 0) / 2;
    const gutter = opts.offset?.mainAxis ?? opts.gutter;
    const mainAxis = typeof gutter === "number" ? gutter + arrowOffset : gutter ?? arrowOffset;
    const { hasAlign } = getPlacementDetails(placement);
    const shift22 = !hasAlign ? opts.shift : void 0;
    const crossAxis = opts.offset?.crossAxis ?? shift22;
    return compact({
      crossAxis,
      mainAxis,
      alignmentAxis: opts.shift
    });
  });
}
function getFlipMiddleware(opts) {
  if (!opts.flip) return;
  return flip2(() => {
    const boundary = resolveBoundaryOption(opts.boundary);
    return {
      ...boundary ? { boundary } : void 0,
      padding: opts.overflowPadding,
      fallbackPlacements: opts.flip === true ? void 0 : opts.flip
    };
  });
}
function getShiftMiddleware(opts) {
  if (!opts.slide && !opts.overlap) return;
  return shift2(() => {
    const boundary = resolveBoundaryOption(opts.boundary);
    return {
      ...boundary ? { boundary } : void 0,
      mainAxis: opts.slide,
      crossAxis: opts.overlap,
      padding: opts.overflowPadding,
      limiter: limitShift2()
    };
  });
}
function getSizeMiddleware(opts) {
  if (opts.sizeMiddleware === false && !opts.sameWidth && !opts.fitViewport) return;
  let lastReferenceWidth;
  let lastReferenceHeight;
  let lastAvailableWidth;
  let lastAvailableHeight;
  return size2(() => {
    const boundary = resolveBoundaryOption(opts.boundary);
    return {
      padding: opts.overflowPadding,
      ...boundary ? { boundary } : void 0,
      apply({ elements, rects, availableHeight, availableWidth }) {
        const floating = elements.floating;
        const referenceWidth = Math.round(rects.reference.width);
        const referenceHeight = Math.round(rects.reference.height);
        availableWidth = Math.floor(availableWidth);
        availableHeight = Math.floor(availableHeight);
        if (!isApproximatelyEqual(lastReferenceWidth, referenceWidth)) {
          floating.style.setProperty("--reference-width", `${referenceWidth}px`);
          lastReferenceWidth = referenceWidth;
        }
        if (!isApproximatelyEqual(lastReferenceHeight, referenceHeight)) {
          floating.style.setProperty("--reference-height", `${referenceHeight}px`);
          lastReferenceHeight = referenceHeight;
        }
        if (!isApproximatelyEqual(lastAvailableWidth, availableWidth)) {
          floating.style.setProperty("--available-width", `${availableWidth}px`);
          lastAvailableWidth = availableWidth;
        }
        if (!isApproximatelyEqual(lastAvailableHeight, availableHeight)) {
          floating.style.setProperty("--available-height", `${availableHeight}px`);
          lastAvailableHeight = availableHeight;
        }
      }
    };
  });
}
function hideWhenDetachedMiddleware(opts) {
  if (!opts.hideWhenDetached) return;
  return hide2(() => ({
    strategy: "referenceHidden",
    boundary: resolveBoundaryOption(opts.boundary) ?? "clippingAncestors"
  }));
}
function getAutoUpdateOptions(opts) {
  if (!opts) return {};
  if (opts === true) {
    return { ancestorResize: true, ancestorScroll: true, elementResize: true, layoutShift: true };
  }
  return opts;
}
var floatingStyleProps = [
  "transform",
  "visibility",
  "pointer-events",
  "--x",
  "--y",
  "--z-index",
  "--reference-width",
  "--reference-height",
  "--available-width",
  "--available-height",
  "--transform-origin"
];
var arrowStyleProps = ["top", "right", "bottom", "left"];
function createStyleCleanup(el, props) {
  if (!el) return noop;
  const prev = new Map(props.map((prop) => [prop, el.style.getPropertyValue(prop)]));
  return () => {
    prev.forEach((value, prop) => {
      if (value) el.style.setProperty(prop, value);
      else el.style.removeProperty(prop);
    });
    if (el.style.length === 0) {
      el.removeAttribute("style");
    }
  };
}
function anchorIdentity(anchor) {
  if (anchor == null) return null;
  if (isHTMLElement(anchor)) return anchor;
  if (typeof anchor === "object" && anchor && "contextElement" in anchor && anchor.contextElement) {
    return anchor.contextElement;
  }
  return anchor;
}
function getPlacementImpl(referenceOrVirtual, floatingOrVirtual, opts = {}) {
  const resolveFloating = () => {
    const raw = typeof floatingOrVirtual === "function" ? floatingOrVirtual() : floatingOrVirtual;
    return raw ?? null;
  };
  const resolveAnchor = () => {
    const raw = typeof referenceOrVirtual === "function" ? referenceOrVirtual() : referenceOrVirtual;
    return opts.getAnchorElement?.() ?? raw;
  };
  const resolveReference = () => {
    const anchor = resolveAnchor();
    if (!anchor && !opts.getAnchorRect) return null;
    return getAnchorElement(anchor, opts.getAnchorRect);
  };
  const options = Object.assign({}, defaultOptions, opts);
  let middleware = [];
  let cachedMiddlewareFloating = null;
  let restoreFloatingStyles;
  let restoreArrowStyles;
  function rebuildMiddlewareForFloating(floating) {
    restoreFloatingStyles?.();
    restoreArrowStyles?.();
    cachedMiddlewareFloating = floating;
    restoreFloatingStyles = options.restoreStyles ? createStyleCleanup(floating, floatingStyleProps) : void 0;
    const arrowEl = floating.querySelector("[data-part=arrow]");
    restoreArrowStyles = options.restoreStyles ? createStyleCleanup(arrowEl, arrowStyleProps) : void 0;
    middleware = [
      getOffsetMiddleware(arrowEl, options),
      getFlipMiddleware(options),
      getShiftMiddleware(options),
      getArrowMiddleware(arrowEl, floating.ownerDocument, options),
      shiftArrowMiddleware(arrowEl),
      createTransformOriginMiddleware(
        { gutter: options.gutter, offset: options.offset, overlap: options.overlap },
        arrowEl
      ),
      getSizeMiddleware(options),
      hideWhenDetachedMiddleware(options),
      rectMiddleware
    ];
  }
  const { placement, strategy, onComplete, onPositioned } = options;
  let lastX;
  let lastY;
  let zIndexComputed = false;
  let lastAnchorForObserve = void 0;
  let lastFloatingForObserve = void 0;
  let cancelAutoUpdate = noop;
  const autoUpdateOptions = getAutoUpdateOptions(options.listeners);
  function syncAutoUpdateObservers() {
    if (!options.listeners) return;
    const anchor = resolveAnchor();
    const reference = resolveReference();
    const floating = resolveFloating();
    if (!reference || !floating) return;
    const anchorChanged = anchorIdentity(anchor) !== anchorIdentity(lastAnchorForObserve);
    const floatingChanged = floating !== lastFloatingForObserve;
    if (anchorChanged || floatingChanged) {
      cancelAutoUpdate();
      lastAnchorForObserve = anchor;
      lastFloatingForObserve = floating;
      cancelAutoUpdate = autoUpdate(reference, floating, runUpdate, autoUpdateOptions);
    }
  }
  async function updatePosition() {
    syncAutoUpdateObservers();
    const floating = resolveFloating();
    if (!floating) return;
    if (floating !== cachedMiddlewareFloating) {
      rebuildMiddlewareForFloating(floating);
      zIndexComputed = false;
    }
    const reference = resolveReference();
    if (!reference) return;
    const pos = await computePosition2(reference, floating, {
      placement,
      middleware,
      strategy
    });
    const win = getWindow(floating);
    const x = roundByDpr(win, pos.x);
    const y = roundByDpr(win, pos.y);
    onComplete?.({ ...pos, x, y });
    if (options.applyStyles === false) return;
    if (!isApproximatelyEqual(lastX, x)) {
      floating.style.setProperty("--x", `${x}px`);
      lastX = x;
    }
    if (!isApproximatelyEqual(lastY, y)) {
      floating.style.setProperty("--y", `${y}px`);
      lastY = y;
    }
    if (options.hideWhenDetached) {
      const isHidden = pos.middlewareData.hide?.referenceHidden;
      if (isHidden) {
        floating.style.setProperty("visibility", "hidden");
        floating.style.setProperty("pointer-events", "none");
      } else {
        floating.style.removeProperty("visibility");
        floating.style.removeProperty("pointer-events");
      }
    }
    if (!zIndexComputed) {
      const contentEl = floating.firstElementChild;
      if (contentEl) {
        floating.style.setProperty("--z-index", getComputedStyle2(contentEl).zIndex);
        zIndexComputed = true;
      }
    }
  }
  async function runUpdate() {
    if (opts.updatePosition) {
      await opts.updatePosition({ updatePosition, floatingElement: resolveFloating() });
      onPositioned?.({ placed: true });
    } else {
      await updatePosition();
    }
  }
  runUpdate();
  return () => {
    cancelAutoUpdate();
    restoreArrowStyles?.();
    restoreFloatingStyles?.();
    onPositioned?.({ placed: false });
  };
}
function getPlacement(referenceOrFn, floatingOrFn, opts = {}) {
  const { defer, ...options } = opts;
  const func = defer ? raf : (v) => v();
  const cleanups = [];
  cleanups.push(
    func(() => {
      cleanups.push(getPlacementImpl(referenceOrFn, floatingOrFn, options));
    })
  );
  return () => {
    cleanups.forEach((fn) => fn?.());
  };
}

// node_modules/@zag-js/popper/dist/get-styles.mjs
var ARROW_FLOATING_STYLE = {
  bottom: "rotate(45deg)",
  left: "rotate(135deg)",
  top: "rotate(225deg)",
  right: "rotate(315deg)"
};
function getPlacementStyles(options = {}) {
  const { placement, sameWidth, fitViewport, strategy = "absolute" } = options;
  return {
    arrow: {
      position: "absolute",
      width: cssVars.arrowSize.reference,
      height: cssVars.arrowSize.reference,
      [cssVars.arrowSizeHalf.variable]: `calc(${cssVars.arrowSize.reference} / 2)`,
      [cssVars.arrowOffset.variable]: `calc(${cssVars.arrowSizeHalf.reference} * -1)`
    },
    arrowTip: {
      // @ts-expect-error - Fix this
      transform: placement ? ARROW_FLOATING_STYLE[placement.split("-")[0]] : void 0,
      background: cssVars.arrowBg.reference,
      top: "0",
      left: "0",
      width: "100%",
      height: "100%",
      position: "absolute",
      zIndex: "inherit"
    },
    floating: {
      position: strategy,
      isolation: "isolate",
      minWidth: sameWidth ? void 0 : "max-content",
      width: sameWidth ? "var(--reference-width)" : void 0,
      maxWidth: fitViewport ? "var(--available-width)" : void 0,
      maxHeight: fitViewport ? "var(--available-height)" : void 0,
      pointerEvents: !placement ? "none" : void 0,
      top: "0px",
      left: "0px",
      // move off-screen if placement is not defined
      transform: placement ? "translate3d(var(--x), var(--y), 0)" : "translate3d(0, -100vh, 0)",
      zIndex: "var(--z-index)"
    }
  };
}

// node_modules/@zag-js/select/dist/select.dom.mjs
var getRootId = (ctx) => ctx.ids?.root ?? `select:${ctx.id}`;
var getContentId = (ctx) => ctx.ids?.content ?? `select:${ctx.id}:content`;
var getTriggerId = (ctx) => ctx.ids?.trigger ?? `select:${ctx.id}:trigger`;
var getClearTriggerId = (ctx) => ctx.ids?.clearTrigger ?? `select:${ctx.id}:clear-trigger`;
var getLabelId = (ctx) => ctx.ids?.label ?? `select:${ctx.id}:label`;
var getControlId = (ctx) => ctx.ids?.control ?? `select:${ctx.id}:control`;
var getItemId = (ctx, id) => ctx.ids?.item?.(id) ?? `select:${ctx.id}:option:${id}`;
var getHiddenSelectId = (ctx) => ctx.ids?.hiddenSelect ?? `select:${ctx.id}:select`;
var getPositionerId = (ctx) => ctx.ids?.positioner ?? `select:${ctx.id}:positioner`;
var getItemGroupId = (ctx, id) => ctx.ids?.itemGroup?.(id) ?? `select:${ctx.id}:optgroup:${id}`;
var getItemGroupLabelId = (ctx, id) => ctx.ids?.itemGroupLabel?.(id) ?? `select:${ctx.id}:optgroup-label:${id}`;
var getHiddenSelectEl = (ctx) => ctx.getById(getHiddenSelectId(ctx));
var getContentEl = (ctx) => ctx.getById(getContentId(ctx));
var getTriggerEl = (ctx) => ctx.getById(getTriggerId(ctx));
var getClearTriggerEl = (ctx) => ctx.getById(getClearTriggerId(ctx));
var getPositionerEl = (ctx) => ctx.getById(getPositionerId(ctx));
var getItemEl = (ctx, id) => {
  if (id == null) return null;
  return ctx.getById(getItemId(ctx, id));
};

// node_modules/@zag-js/select/dist/select.connect.mjs
var defaultTranslations = {
  clearTriggerLabel: "Clear value"
};
function connect(service, normalize) {
  const { context, prop, scope, state, computed, send } = service;
  const translations = mergeWithDefault(defaultTranslations, prop("translations"));
  const disabled = prop("disabled") || context.get("fieldsetDisabled");
  const invalid = !!prop("invalid");
  const required = !!prop("required");
  const readOnly = !!prop("readOnly");
  const composite = prop("composite");
  const collection2 = prop("collection");
  const open = state.hasTag("open");
  const focused = state.matches("focused");
  const highlightedValue = context.get("highlightedValue");
  const highlightedItem = context.get("highlightedItem");
  const selectedItems = computed("selectedItems");
  const currentPlacement = context.get("currentPlacement");
  const currentPlacementSide = currentPlacement ? getPlacementSide(currentPlacement) : void 0;
  const isTypingAhead = computed("isTypingAhead");
  const interactive = computed("isInteractive");
  const ariaActiveDescendant = highlightedValue ? getItemId(scope, highlightedValue) : void 0;
  function getItemState(props) {
    const _disabled = collection2.getItemDisabled(props.item);
    const value = collection2.getItemValue(props.item);
    ensure(value, () => `[zag-js] No value found for item ${JSON.stringify(props.item)}`);
    return {
      value,
      disabled: Boolean(disabled || _disabled),
      highlighted: highlightedValue === value,
      selected: context.get("value").includes(value)
    };
  }
  const popperStyles = getPlacementStyles({
    ...prop("positioning"),
    placement: currentPlacement
  });
  return {
    open,
    focused,
    empty: context.get("value").length === 0,
    highlightedItem,
    highlightedValue,
    selectedItems,
    hasSelectedItems: computed("hasSelectedItems"),
    value: context.get("value"),
    valueAsString: computed("valueAsString"),
    collection: collection2,
    multiple: !!prop("multiple"),
    disabled: !!disabled,
    reposition(options = {}) {
      send({ type: "POSITIONING.SET", options });
    },
    focus() {
      getTriggerEl(scope)?.focus({ preventScroll: true });
    },
    setOpen(nextOpen) {
      send({ type: nextOpen ? "OPEN" : "CLOSE", replaces: "open" });
    },
    selectValue(value) {
      send({ type: "ITEM.SELECT", value });
    },
    setValue(value) {
      send({ type: "VALUE.SET", value });
    },
    selectAll() {
      send({ type: "VALUE.SET", value: collection2.getValues() });
    },
    setHighlightValue(value) {
      send({ type: "HIGHLIGHTED_VALUE.SET", value });
    },
    clearHighlightValue() {
      send({ type: "HIGHLIGHTED_VALUE.CLEAR" });
    },
    clearValue(value) {
      if (value) {
        send({ type: "ITEM.CLEAR", value });
      } else {
        send({ type: "VALUE.CLEAR" });
      }
    },
    getItemState,
    getRootProps() {
      return normalize.element({
        ...parts.root.attrs,
        dir: prop("dir"),
        id: getRootId(scope),
        "data-invalid": dataAttr(invalid),
        "data-readonly": dataAttr(readOnly)
      });
    },
    getLabelProps() {
      return normalize.label({
        dir: prop("dir"),
        id: getLabelId(scope),
        ...parts.label.attrs,
        "data-disabled": dataAttr(disabled),
        "data-invalid": dataAttr(invalid),
        "data-readonly": dataAttr(readOnly),
        "data-required": dataAttr(required),
        htmlFor: getHiddenSelectId(scope),
        onClick(event) {
          if (event.defaultPrevented) return;
          if (disabled) return;
          getTriggerEl(scope)?.focus({ preventScroll: true });
        }
      });
    },
    getControlProps() {
      return normalize.element({
        ...parts.control.attrs,
        dir: prop("dir"),
        id: getControlId(scope),
        "data-state": open ? "open" : "closed",
        "data-focus": dataAttr(focused),
        "data-disabled": dataAttr(disabled),
        "data-invalid": dataAttr(invalid)
      });
    },
    getValueTextProps() {
      return normalize.element({
        ...parts.valueText.attrs,
        dir: prop("dir"),
        "data-disabled": dataAttr(disabled),
        "data-invalid": dataAttr(invalid),
        "data-focus": dataAttr(focused)
      });
    },
    getTriggerProps() {
      return normalize.button({
        id: getTriggerId(scope),
        disabled,
        dir: prop("dir"),
        type: "button",
        role: "combobox",
        "aria-controls": getContentId(scope),
        "aria-expanded": open,
        "aria-haspopup": "listbox",
        "data-state": open ? "open" : "closed",
        "aria-invalid": invalid,
        "aria-required": required,
        "aria-labelledby": getLabelId(scope),
        ...parts.trigger.attrs,
        "data-disabled": dataAttr(disabled),
        "data-invalid": dataAttr(invalid),
        "data-readonly": dataAttr(readOnly),
        "data-placement": currentPlacement,
        "data-side": currentPlacementSide,
        "data-placeholder-shown": dataAttr(!computed("hasSelectedItems")),
        onClick(event) {
          if (!interactive) return;
          if (event.defaultPrevented) return;
          send({ type: "TRIGGER.CLICK" });
        },
        onFocus() {
          send({ type: "TRIGGER.FOCUS" });
        },
        onBlur() {
          send({ type: "TRIGGER.BLUR" });
        },
        onKeyDown(event) {
          if (event.defaultPrevented) return;
          if (!interactive) return;
          const keyMap2 = {
            ArrowUp() {
              send({ type: "TRIGGER.ARROW_UP" });
            },
            ArrowDown(event2) {
              send({ type: event2.altKey ? "OPEN" : "TRIGGER.ARROW_DOWN" });
            },
            ArrowLeft() {
              send({ type: "TRIGGER.ARROW_LEFT" });
            },
            ArrowRight() {
              send({ type: "TRIGGER.ARROW_RIGHT" });
            },
            Home() {
              send({ type: "TRIGGER.HOME" });
            },
            End() {
              send({ type: "TRIGGER.END" });
            },
            Enter() {
              send({ type: "TRIGGER.ENTER" });
            },
            Space(event2) {
              if (isTypingAhead) {
                send({ type: "TRIGGER.TYPEAHEAD", key: event2.key });
              } else {
                send({ type: "TRIGGER.ENTER" });
              }
            }
          };
          const exec = keyMap2[getEventKey(event, {
            dir: prop("dir"),
            orientation: "vertical"
          })];
          if (exec) {
            exec(event);
            event.preventDefault();
            return;
          }
          if (getByTypeahead.isValidEvent(event)) {
            send({ type: "TRIGGER.TYPEAHEAD", key: event.key });
            event.preventDefault();
          }
        }
      });
    },
    getIndicatorProps() {
      return normalize.element({
        ...parts.indicator.attrs,
        dir: prop("dir"),
        "aria-hidden": true,
        "data-state": open ? "open" : "closed",
        "data-disabled": dataAttr(disabled),
        "data-invalid": dataAttr(invalid),
        "data-readonly": dataAttr(readOnly)
      });
    },
    getItemProps(props) {
      const itemState = getItemState(props);
      return normalize.element({
        id: getItemId(scope, itemState.value),
        role: "option",
        ...parts.item.attrs,
        dir: prop("dir"),
        "data-value": itemState.value,
        "aria-selected": itemState.selected,
        "data-state": itemState.selected ? "checked" : "unchecked",
        "data-highlighted": dataAttr(itemState.highlighted),
        "data-disabled": dataAttr(itemState.disabled),
        "aria-disabled": ariaAttr(itemState.disabled),
        onPointerMove(event) {
          if (itemState.disabled || event.pointerType !== "mouse") return;
          if (getInteractionModality() !== "pointer") return;
          if (itemState.value === highlightedValue) return;
          send({ type: "ITEM.POINTER_MOVE", value: itemState.value });
        },
        onClick(event) {
          if (event.defaultPrevented) return;
          if (itemState.disabled) return;
          send({ type: "ITEM.CLICK", src: "pointerup", value: itemState.value });
        },
        onPointerLeave(event) {
          if (itemState.disabled) return;
          if (props.persistFocus) return;
          if (event.pointerType !== "mouse") return;
          if (getInteractionModality() !== "pointer") return;
          send({ type: "ITEM.POINTER_LEAVE" });
        }
      });
    },
    getItemTextProps(props) {
      const itemState = getItemState(props);
      return normalize.element({
        ...parts.itemText.attrs,
        "data-state": itemState.selected ? "checked" : "unchecked",
        "data-disabled": dataAttr(itemState.disabled),
        "data-highlighted": dataAttr(itemState.highlighted)
      });
    },
    getItemIndicatorProps(props) {
      const itemState = getItemState(props);
      return normalize.element({
        "aria-hidden": true,
        ...parts.itemIndicator.attrs,
        "data-state": itemState.selected ? "checked" : "unchecked",
        hidden: !itemState.selected
      });
    },
    getItemGroupLabelProps(props) {
      const { htmlFor } = props;
      return normalize.element({
        ...parts.itemGroupLabel.attrs,
        id: getItemGroupLabelId(scope, htmlFor),
        dir: prop("dir"),
        role: "presentation"
      });
    },
    getItemGroupProps(props) {
      const { id } = props;
      return normalize.element({
        ...parts.itemGroup.attrs,
        "data-disabled": dataAttr(disabled),
        id: getItemGroupId(scope, id),
        "aria-labelledby": getItemGroupLabelId(scope, id),
        role: "group",
        dir: prop("dir")
      });
    },
    getClearTriggerProps() {
      return normalize.button({
        ...parts.clearTrigger.attrs,
        id: getClearTriggerId(scope),
        type: "button",
        "aria-label": translations.clearTriggerLabel,
        "data-invalid": dataAttr(invalid),
        disabled,
        hidden: !computed("hasSelectedItems"),
        dir: prop("dir"),
        onClick(event) {
          if (event.defaultPrevented) return;
          send({ type: "CLEAR.CLICK" });
        }
      });
    },
    getHiddenSelectProps() {
      const value = context.get("value");
      const defaultValue = prop("multiple") ? value : value?.[0];
      const handleChange = (e) => {
        const evt = getNativeEvent(e);
        if (isInternalChangeEvent(evt)) return;
        send({ type: "VALUE.SET", value: getSelectedValues(e.currentTarget) });
      };
      return normalize.select({
        name: prop("name"),
        form: prop("form"),
        disabled,
        multiple: prop("multiple"),
        required: prop("required"),
        "aria-hidden": true,
        id: getHiddenSelectId(scope),
        defaultValue,
        style: visuallyHiddenStyle,
        tabIndex: -1,
        autoComplete: prop("autoComplete"),
        onChange: handleChange,
        onInput: handleChange,
        // Some browser extensions will focus the hidden select.
        // Let's forward the focus to the trigger.
        onFocus() {
          getTriggerEl(scope)?.focus({ preventScroll: true });
        },
        "aria-labelledby": getLabelId(scope)
      });
    },
    getPositionerProps() {
      return normalize.element({
        ...parts.positioner.attrs,
        dir: prop("dir"),
        id: getPositionerId(scope),
        style: popperStyles.floating
      });
    },
    getContentProps() {
      return normalize.element({
        hidden: !open,
        dir: prop("dir"),
        id: getContentId(scope),
        role: composite ? "listbox" : "dialog",
        ...parts.content.attrs,
        "data-state": open ? "open" : "closed",
        "data-placement": currentPlacement,
        "data-side": currentPlacementSide,
        "data-activedescendant": ariaActiveDescendant,
        "aria-activedescendant": composite ? ariaActiveDescendant : void 0,
        "aria-multiselectable": prop("multiple") && composite ? true : void 0,
        "aria-labelledby": getLabelId(scope),
        tabIndex: 0,
        onKeyDown(event) {
          if (!interactive) return;
          if (!contains(event.currentTarget, getEventTarget(event))) return;
          if (event.key === "Tab") {
            const valid = isValidTabEvent(event);
            if (!valid) {
              event.preventDefault();
              return;
            }
          }
          const keyMap2 = {
            ArrowUp() {
              send({ type: "CONTENT.ARROW_UP" });
            },
            ArrowDown() {
              send({ type: "CONTENT.ARROW_DOWN" });
            },
            Home() {
              send({ type: "CONTENT.HOME" });
            },
            End() {
              send({ type: "CONTENT.END" });
            },
            Enter() {
              send({ type: "ITEM.CLICK", src: "keydown.enter" });
            },
            Space(event2) {
              if (isTypingAhead) {
                send({ type: "CONTENT.TYPEAHEAD", key: event2.key });
              } else {
                keyMap2.Enter?.(event2);
              }
            }
          };
          const exec = keyMap2[getEventKey(event)];
          if (exec) {
            exec(event);
            event.preventDefault();
            return;
          }
          const target = getEventTarget(event);
          if (isEditableElement(target)) {
            return;
          }
          if (getByTypeahead.isValidEvent(event)) {
            send({ type: "CONTENT.TYPEAHEAD", key: event.key });
            event.preventDefault();
          }
        }
      });
    },
    getListProps() {
      return normalize.element({
        ...parts.list.attrs,
        tabIndex: 0,
        role: !composite ? "listbox" : void 0,
        "aria-labelledby": getTriggerId(scope),
        "aria-activedescendant": !composite ? ariaActiveDescendant : void 0,
        "aria-multiselectable": !composite && prop("multiple") ? true : void 0
      });
    }
  };
}
var getSelectedValues = (el) => {
  return el.multiple ? Array.from(el.selectedOptions, (o) => o.value) : el.value ? [el.value] : [];
};

// node_modules/@zag-js/core/dist/replace-tracker.mjs
function createReplaceTracker() {
  const newest = /* @__PURE__ */ new Map();
  return {
    claim(key) {
      const token = Symbol(key);
      newest.set(key, token);
      return token;
    },
    isReplaced(key, token) {
      return newest.get(key) !== token;
    }
  };
}

// node_modules/@zag-js/core/dist/state.mjs
var STATE_DELIMITER = ".";
var ABSOLUTE_PREFIX = "#";
var stateIndexCache = /* @__PURE__ */ new WeakMap();
var stateIdIndexCache = /* @__PURE__ */ new WeakMap();
function joinStatePath(parts2) {
  return parts2.join(STATE_DELIMITER);
}
function isAbsoluteStatePath(value) {
  return value.includes(STATE_DELIMITER);
}
function isExplicitAbsoluteStatePath(value) {
  return value.startsWith(ABSOLUTE_PREFIX);
}
function isChildTarget(value) {
  return value.startsWith(STATE_DELIMITER);
}
function stripAbsolutePrefix(value) {
  return isExplicitAbsoluteStatePath(value) ? value.slice(ABSOLUTE_PREFIX.length) : value;
}
function appendStatePath(base, segment) {
  return base ? `${base}${STATE_DELIMITER}${segment}` : segment;
}
function buildStateIndex(machine2) {
  const index = /* @__PURE__ */ new Map();
  const idIndex = /* @__PURE__ */ new Map();
  const visit = (basePath, state) => {
    index.set(basePath, state);
    const stateId = state.id;
    if (stateId) {
      if (idIndex.has(stateId)) {
        invariant(`[zag-js] Duplicate state id: "${stateId}"`);
      }
      idIndex.set(stateId, basePath);
    }
    const childStates = state.states;
    if (!childStates) return;
    ensure(state.initial, () => `[zag-js] Compound state "${basePath}" has child states but no "initial" property`);
    if (!(state.initial in childStates)) {
      invariant(
        `[zag-js] Compound state "${basePath}" has initial "${String(state.initial)}" which is not a child state`
      );
    }
    for (const [childKey, childState] of Object.entries(childStates)) {
      if (!childState) continue;
      const childPath = appendStatePath(basePath, childKey);
      visit(childPath, childState);
    }
  };
  for (const [topKey, topState] of Object.entries(machine2.states)) {
    if (!topState) continue;
    visit(topKey, topState);
  }
  return { index, idIndex };
}
function ensureStateIndex(machine2) {
  const cached = stateIndexCache.get(machine2);
  if (cached) return cached;
  const { index, idIndex } = buildStateIndex(machine2);
  stateIndexCache.set(machine2, index);
  stateIdIndexCache.set(machine2, idIndex);
  return index;
}
function getStatePathById(machine2, stateId) {
  ensureStateIndex(machine2);
  return stateIdIndexCache.get(machine2)?.get(stateId);
}
function toSegments(value) {
  if (!value) return [];
  return String(value).split(STATE_DELIMITER).filter(Boolean);
}
function getStateChain(machine2, state) {
  if (!state) return [];
  const stateIndex = ensureStateIndex(machine2);
  const segments = toSegments(state);
  const chain = [];
  const statePath = [];
  for (const segment of segments) {
    statePath.push(segment);
    const path = joinStatePath(statePath);
    const current = stateIndex.get(path);
    if (!current) break;
    chain.push({ path, state: current });
  }
  return chain;
}
function resolveAbsoluteStateValue(machine2, value) {
  const stateIndex = ensureStateIndex(machine2);
  const segments = toSegments(value);
  if (!segments.length) return value;
  const resolved = [];
  for (const segment of segments) {
    resolved.push(segment);
    const path = joinStatePath(resolved);
    if (!stateIndex.has(path)) return value;
  }
  let resolvedPath = joinStatePath(resolved);
  let current = stateIndex.get(resolvedPath);
  while (current?.initial) {
    const nextPath = `${resolvedPath}${STATE_DELIMITER}${current.initial}`;
    const nextState = stateIndex.get(nextPath);
    if (!nextState) break;
    resolvedPath = nextPath;
    current = nextState;
  }
  return resolvedPath;
}
function hasStatePath(machine2, value) {
  const stateIndex = ensureStateIndex(machine2);
  return stateIndex.has(value);
}
function resolveStateValue(machine2, value, source) {
  const stateValue = String(value);
  if (isExplicitAbsoluteStatePath(stateValue)) {
    const stateId = stripAbsolutePrefix(stateValue);
    const statePath = getStatePathById(machine2, stateId);
    ensure(statePath, () => `[zag-js] Unknown state id: "${stateId}"`);
    return resolveAbsoluteStateValue(machine2, statePath);
  }
  if (isChildTarget(stateValue) && source) {
    const childPath = appendStatePath(source, stateValue.slice(1));
    return resolveAbsoluteStateValue(machine2, childPath);
  }
  if (!isAbsoluteStatePath(stateValue) && source) {
    const sourceSegments = toSegments(source);
    for (let index = sourceSegments.length - 1; index >= 1; index--) {
      const base = sourceSegments.slice(0, index).join(STATE_DELIMITER);
      const candidate = appendStatePath(base, stateValue);
      if (hasStatePath(machine2, candidate)) return resolveAbsoluteStateValue(machine2, candidate);
    }
    if (hasStatePath(machine2, stateValue)) return resolveAbsoluteStateValue(machine2, stateValue);
  }
  return resolveAbsoluteStateValue(machine2, stateValue);
}
function findTransition(machine2, state, eventType) {
  const chain = getStateChain(machine2, state);
  for (let index = chain.length - 1; index >= 0; index--) {
    const transitionMap = chain[index]?.state.on;
    const transition = transitionMap?.[eventType];
    if (transition) return { transitions: transition, source: chain[index]?.path };
  }
  const rootTransitionMap = machine2.on;
  return { transitions: rootTransitionMap?.[eventType], source: void 0 };
}
function getExitEnterStates(machine2, prevState, nextState, reenter) {
  const prevChain = prevState ? getStateChain(machine2, prevState) : [];
  const nextChain = getStateChain(machine2, nextState);
  let commonIndex = 0;
  while (commonIndex < prevChain.length && commonIndex < nextChain.length && prevChain[commonIndex]?.path === nextChain[commonIndex]?.path) {
    commonIndex += 1;
  }
  let exiting = prevChain.slice(commonIndex).reverse();
  let entering = nextChain.slice(commonIndex);
  const sameLeaf = prevChain[prevChain.length - 1]?.path === nextChain[nextChain.length - 1]?.path;
  if (reenter && sameLeaf) {
    exiting = prevChain.slice().reverse();
    entering = nextChain;
  }
  return { exiting, entering };
}
function matchesState(current, value) {
  if (!current) return false;
  return current === value || current.startsWith(`${value}${STATE_DELIMITER}`);
}
function hasTag(machine2, state, tag) {
  return getStateChain(machine2, state).some((item) => item.state.tags?.includes(tag));
}

// node_modules/@zag-js/core/dist/create-machine.mjs
function createGuards() {
  return {
    and: (...guards) => {
      return function andGuard(params) {
        return guards.every((str) => params.guard(str));
      };
    },
    or: (...guards) => {
      return function orGuard(params) {
        return guards.some((str) => params.guard(str));
      };
    },
    not: (guard) => {
      return function notGuard(params) {
        return !params.guard(guard);
      };
    }
  };
}
function createMachine(config) {
  ensureStateIndex(config);
  return config;
}

// node_modules/@zag-js/core/dist/types.mjs
var MachineStatus = /* @__PURE__ */ ((MachineStatus2) => {
  MachineStatus2["NotStarted"] = "Not Started";
  MachineStatus2["Started"] = "Started";
  MachineStatus2["Stopped"] = "Stopped";
  return MachineStatus2;
})(MachineStatus || {});
var INIT_STATE = "__init__";

// node_modules/@zag-js/core/dist/scope.mjs
function createScope(props) {
  const getRootNode2 = () => props.getRootNode?.() ?? document;
  const getDoc = () => getDocument(getRootNode2());
  const getWin = () => getDoc().defaultView ?? window;
  const getActiveElementFn = () => getActiveElement(getRootNode2());
  const getById = (id) => getRootNode2().getElementById(id);
  return {
    ...props,
    getRootNode: getRootNode2,
    getDoc,
    getWin,
    getActiveElement: getActiveElementFn,
    isActiveElement,
    getById
  };
}

// node_modules/@zag-js/interact-outside/dist/frame-utils.mjs
function getWindowFrames(win) {
  const frames = {
    each(cb) {
      for (let i = 0; i < win.frames?.length; i += 1) {
        const frame = win.frames[i];
        if (frame) cb(frame);
      }
    },
    addEventListener(event, listener, options) {
      frames.each((frame) => {
        try {
          frame.document.addEventListener(event, listener, options);
        } catch {
        }
      });
      return () => {
        try {
          frames.removeEventListener(event, listener, options);
        } catch {
        }
      };
    },
    removeEventListener(event, listener, options) {
      frames.each((frame) => {
        try {
          frame.document.removeEventListener(event, listener, options);
        } catch {
        }
      });
    }
  };
  return frames;
}
function getParentWindow(win) {
  const parent = win.frameElement != null ? win.parent : null;
  return {
    addEventListener: (event, listener, options) => {
      try {
        parent?.addEventListener(event, listener, options);
      } catch {
      }
      return () => {
        try {
          parent?.removeEventListener(event, listener, options);
        } catch {
        }
      };
    },
    removeEventListener: (event, listener, options) => {
      try {
        parent?.removeEventListener(event, listener, options);
      } catch {
      }
    }
  };
}

// node_modules/@zag-js/interact-outside/dist/index.mjs
var POINTER_OUTSIDE_EVENT = "pointerdown.outside";
var FOCUS_OUTSIDE_EVENT = "focus.outside";
function isComposedPathFocusable(composedPath) {
  for (const node of composedPath) {
    if (isHTMLElement(node) && isFocusable(node)) return true;
  }
  return false;
}
var isPointerEvent = (event) => "clientY" in event;
function isEventPointWithin(node, event) {
  if (!isPointerEvent(event) || !node) return false;
  const rect = node.getBoundingClientRect();
  if (rect.width === 0 || rect.height === 0) return false;
  return rect.top <= event.clientY && event.clientY <= rect.top + rect.height && rect.left <= event.clientX && event.clientX <= rect.left + rect.width;
}
function isPointInRect(rect, point) {
  return rect.y <= point.y && point.y <= rect.y + rect.height && rect.x <= point.x && point.x <= rect.x + rect.width;
}
function isEventWithinScrollbar(event, ancestor) {
  if (!ancestor || !isPointerEvent(event)) return false;
  const isScrollableY = ancestor.scrollHeight > ancestor.clientHeight;
  const onScrollbarY = isScrollableY && event.clientX > ancestor.offsetLeft + ancestor.clientWidth;
  const isScrollableX = ancestor.scrollWidth > ancestor.clientWidth;
  const onScrollbarX = isScrollableX && event.clientY > ancestor.offsetTop + ancestor.clientHeight;
  const rect = {
    x: ancestor.offsetLeft,
    y: ancestor.offsetTop,
    width: ancestor.clientWidth + (isScrollableY ? 16 : 0),
    height: ancestor.clientHeight + (isScrollableX ? 16 : 0)
  };
  const point = {
    x: event.clientX,
    y: event.clientY
  };
  if (!isPointInRect(rect, point)) return false;
  return onScrollbarY || onScrollbarX;
}
function trackInteractOutsideImpl(node, options) {
  const {
    exclude,
    onFocusOutside,
    onPointerDownOutside,
    onInteractOutside,
    defer,
    followControlledElements = true
  } = options;
  if (!node) return;
  const doc = getDocument(node);
  const win = getWindow(node);
  const frames = getWindowFrames(win);
  const parentWin = getParentWindow(win);
  function isEventOutside(event, target) {
    if (!isHTMLElement(target)) return false;
    if (!target.isConnected) return false;
    if (contains(node, target)) return false;
    if (isEventPointWithin(node, event)) return false;
    if (followControlledElements && isControlledElement(node, target)) return false;
    const triggerEl = doc.querySelector(`[aria-controls="${node.id}"]`);
    if (triggerEl) {
      const triggerAncestor = getNearestOverflowAncestor(triggerEl);
      if (isEventWithinScrollbar(event, triggerAncestor)) return false;
    }
    const nodeAncestor = getNearestOverflowAncestor(node);
    if (isEventWithinScrollbar(event, nodeAncestor)) return false;
    return !exclude?.(target);
  }
  const pointerdownCleanups = /* @__PURE__ */ new Set();
  const isInShadowRoot = isShadowRoot(node?.getRootNode());
  let isPointerDown = false;
  function onPointerDown(event) {
    isPointerDown = true;
    const onPointerUp = () => {
      isPointerDown = false;
    };
    doc.addEventListener("pointerup", onPointerUp, { once: true });
    win.addEventListener("pointerup", onPointerUp, { once: true });
    function handler(clickEvent) {
      const func = defer && !isTouchDevice() ? raf : (v) => v();
      const evt = clickEvent ?? event;
      const composedPath = evt?.composedPath?.() ?? [evt?.target];
      func(() => {
        const target = isInShadowRoot ? composedPath[0] : getEventTarget(event);
        if (!node || !isEventOutside(event, target)) return;
        if (onPointerDownOutside || onInteractOutside) {
          const handler2 = callAll(onPointerDownOutside, onInteractOutside);
          node.addEventListener(POINTER_OUTSIDE_EVENT, handler2, { once: true });
        }
        fireCustomEvent(node, POINTER_OUTSIDE_EVENT, {
          bubbles: false,
          cancelable: true,
          detail: {
            originalEvent: evt,
            contextmenu: isContextMenuEvent(evt),
            focusable: isComposedPathFocusable(composedPath),
            target
          }
        });
      });
    }
    if (event.pointerType === "touch") {
      pointerdownCleanups.forEach((fn) => fn());
      pointerdownCleanups.add(addDomEvent(doc, "click", handler, { once: true }));
      pointerdownCleanups.add(parentWin.addEventListener("click", handler, { once: true }));
      pointerdownCleanups.add(frames.addEventListener("click", handler, { once: true }));
    } else {
      handler();
    }
  }
  const cleanups = /* @__PURE__ */ new Set();
  const timer = setTimeout(() => {
    cleanups.add(addDomEvent(doc, "pointerdown", onPointerDown, true));
    cleanups.add(parentWin.addEventListener("pointerdown", onPointerDown, true));
    cleanups.add(frames.addEventListener("pointerdown", onPointerDown, true));
  }, 0);
  function onFocusin(event) {
    if (isPointerDown) return;
    const func = defer ? raf : (v) => v();
    func(() => {
      const composedPath = event?.composedPath?.() ?? [event?.target];
      const target = isInShadowRoot ? composedPath[0] : getEventTarget(event);
      if (!node || !isEventOutside(event, target)) return;
      if (onFocusOutside || onInteractOutside) {
        const handler = callAll(onFocusOutside, onInteractOutside);
        node.addEventListener(FOCUS_OUTSIDE_EVENT, handler, { once: true });
      }
      fireCustomEvent(node, FOCUS_OUTSIDE_EVENT, {
        bubbles: false,
        cancelable: true,
        detail: {
          originalEvent: event,
          contextmenu: false,
          focusable: isFocusable(target),
          target
        }
      });
    });
  }
  if (!isTouchDevice()) {
    cleanups.add(addDomEvent(doc, "focusin", onFocusin, true));
    cleanups.add(parentWin.addEventListener("focusin", onFocusin, true));
    cleanups.add(frames.addEventListener("focusin", onFocusin, true));
  }
  return () => {
    clearTimeout(timer);
    pointerdownCleanups.forEach((fn) => fn());
    cleanups.forEach((fn) => fn());
  };
}
function trackInteractOutside(nodeOrFn, options) {
  const { defer } = options;
  const func = defer ? raf : (v) => v();
  const cleanups = [];
  cleanups.push(
    func(() => {
      const node = typeof nodeOrFn === "function" ? nodeOrFn() : nodeOrFn;
      cleanups.push(trackInteractOutsideImpl(node, options));
    })
  );
  return () => {
    cleanups.forEach((fn) => fn?.());
  };
}
function fireCustomEvent(el, type, init) {
  const win = el.ownerDocument.defaultView || window;
  const event = new win.CustomEvent(type, init);
  return el.dispatchEvent(event);
}

// node_modules/@zag-js/dismissable/dist/escape-keydown.mjs
function trackEscapeKeydown(node, fn) {
  const handleKeyDown = (event) => {
    if (event.key !== "Escape") return;
    if (event.isComposing) return;
    fn?.(event);
  };
  return addDomEvent(getDocument(node), "keydown", handleKeyDown, { capture: true });
}

// node_modules/@zag-js/dismissable/dist/layer-stack.mjs
var LAYER_REQUEST_DISMISS_EVENT = "layer:request-dismiss";
var layerStack = {
  layers: [],
  branches: [],
  recentlyRemoved: /* @__PURE__ */ new Set(),
  count() {
    return this.layers.length;
  },
  pointerBlockingLayers() {
    return this.layers.filter((layer) => layer.pointerBlocking);
  },
  topMostPointerBlockingLayer() {
    return [...this.pointerBlockingLayers()].slice(-1)[0];
  },
  hasPointerBlockingLayer() {
    return this.pointerBlockingLayers().length > 0;
  },
  isBelowPointerBlockingLayer(node) {
    const index = this.indexOf(node);
    const highestBlockingIndex = this.topMostPointerBlockingLayer() ? this.indexOf(this.topMostPointerBlockingLayer()?.node) : -1;
    return index < highestBlockingIndex;
  },
  isTopMost(node) {
    const layer = this.layers[this.count() - 1];
    return layer?.node === node;
  },
  getNestedLayers(node) {
    return Array.from(this.layers).slice(this.indexOf(node) + 1);
  },
  getLayersByType(type) {
    return this.layers.filter((layer) => layer.type === type);
  },
  getNestedLayersByType(node, type) {
    const index = this.indexOf(node);
    if (index === -1) return [];
    return this.layers.slice(index + 1).filter((layer) => layer.type === type);
  },
  getParentLayerOfType(node, type) {
    const index = this.indexOf(node);
    if (index <= 0) return void 0;
    return this.layers.slice(0, index).reverse().find((layer) => layer.type === type);
  },
  countNestedLayersOfType(node, type) {
    return this.getNestedLayersByType(node, type).length;
  },
  isInNestedLayer(node, target) {
    const inNested = this.getNestedLayers(node).some((layer) => contains(layer.node, target));
    if (inNested) return true;
    if (this.recentlyRemoved.size > 0) return true;
    return false;
  },
  isInBranch(target) {
    return Array.from(this.branches).some((branch) => contains(branch, target));
  },
  add(layer) {
    const existingIndex = this.indexOf(layer.node);
    if (existingIndex !== -1) {
      this.layers.splice(existingIndex, 1);
    }
    this.layers.push(layer);
    this.syncLayers();
  },
  addBranch(node) {
    this.branches.push(node);
  },
  remove(node) {
    const index = this.indexOf(node);
    if (index < 0) return;
    const layer = this.layers[index];
    layer.styleTargets?.forEach((getTarget) => {
      const target = getTarget();
      if (target) {
        clearLayerStyleMirror(target);
      }
    });
    this.recentlyRemoved.add(node);
    nextTick(() => this.recentlyRemoved.delete(node));
    if (index < this.count() - 1) {
      const _layers = this.getNestedLayers(node);
      _layers.forEach((layer2) => layerStack.dismiss(layer2.node, node));
    }
    this.layers.splice(index, 1);
    this.syncLayers();
  },
  removeBranch(node) {
    const index = this.branches.indexOf(node);
    if (index >= 0) this.branches.splice(index, 1);
  },
  syncLayers() {
    this.layers.forEach((layer, index) => {
      applyLayerStackMetadata(layer, index, layer.node);
      layer.styleTargets?.forEach((getTarget) => {
        const target = getTarget();
        if (!target || target === layer.node) return;
        applyLayerStackMetadata(layer, index, target);
        const { zIndex } = getComputedStyle2(layer.node);
        target.style.setProperty("--z-index", zIndex);
      });
    });
  },
  indexOf(node) {
    return this.layers.findIndex((layer) => layer.node === node);
  },
  dismiss(node, parent) {
    const index = this.indexOf(node);
    if (index === -1) return;
    const layer = this.layers[index];
    addListenerOnce(node, LAYER_REQUEST_DISMISS_EVENT, (event) => {
      layer.requestDismiss?.(event);
      if (!event.defaultPrevented) {
        layer?.dismiss();
      }
    });
    fireCustomEvent2(node, LAYER_REQUEST_DISMISS_EVENT, {
      originalLayer: node,
      targetLayer: parent,
      originalIndex: index,
      targetIndex: parent ? this.indexOf(parent) : -1
    });
    this.syncLayers();
  },
  clear() {
    this.remove(this.layers[0].node);
  }
};
function applyLayerStackMetadata(layer, index, el) {
  el.style.setProperty("--layer-index", `${index}`);
  el.removeAttribute("data-nested");
  el.removeAttribute("data-has-nested");
  const parentOfSameType = layerStack.getParentLayerOfType(layer.node, layer.type);
  if (parentOfSameType) {
    el.setAttribute("data-nested", layer.type);
  }
  const nestedCount = layerStack.countNestedLayersOfType(layer.node, layer.type);
  if (nestedCount > 0) {
    el.setAttribute("data-has-nested", layer.type);
  }
  el.style.setProperty("--nested-layer-count", `${nestedCount}`);
}
function clearLayerStyleMirror(el) {
  el.style.removeProperty("--layer-index");
  el.style.removeProperty("--nested-layer-count");
  el.style.removeProperty("--z-index");
  el.removeAttribute("data-nested");
  el.removeAttribute("data-has-nested");
}
function fireCustomEvent2(el, type, detail) {
  const win = el.ownerDocument.defaultView || window;
  const event = new win.CustomEvent(type, { cancelable: true, bubbles: true, detail });
  return el.dispatchEvent(event);
}
function addListenerOnce(el, type, callback) {
  el.addEventListener(type, callback, { once: true });
}

// node_modules/@zag-js/dismissable/dist/pointer-event-outside.mjs
var originalBodyPointerEvents = /* @__PURE__ */ new WeakMap();
var layerObservers = /* @__PURE__ */ new WeakMap();
function getDesiredPointerEvents(node) {
  return layerStack.isBelowPointerBlockingLayer(node) ? "none" : "auto";
}
function applyPointerEvents(node) {
  const desired = getDesiredPointerEvents(node);
  if (node.style.pointerEvents !== desired) {
    node.style.pointerEvents = desired;
  }
}
function ensurePointerEventsObserver(node) {
  if (layerObservers.has(node)) return;
  const win = getWindow(node);
  if (typeof win.MutationObserver === "undefined") return;
  const observer = new win.MutationObserver(() => {
    if (!layerObservers.has(node)) return;
    applyPointerEvents(node);
  });
  observer.observe(node, { attributes: true, attributeFilter: ["style"] });
  layerObservers.set(node, observer);
}
function assignPointerEventToLayers() {
  layerStack.layers.forEach(({ node }) => {
    applyPointerEvents(node);
    ensurePointerEventsObserver(node);
  });
}
function clearPointerEvent(node) {
  const observer = layerObservers.get(node);
  if (observer) {
    observer.disconnect();
    layerObservers.delete(node);
  }
  node.style.pointerEvents = "";
}
function disablePointerEventsOutside(node, persistentElements) {
  const doc = getDocument(node);
  const cleanups = [];
  if (layerStack.hasPointerBlockingLayer() && !doc.body.hasAttribute("data-inert")) {
    originalBodyPointerEvents.set(doc.body, doc.body.style.pointerEvents);
    queueMicrotask(() => {
      const body = doc.body;
      if (!body) return;
      body.style.pointerEvents = "none";
      body.setAttribute("data-inert", "");
    });
  }
  persistentElements?.forEach((el) => {
    const [promise, abort] = waitForElement(
      () => {
        const node2 = el();
        return isHTMLElement(node2) ? node2 : null;
      },
      { timeout: 1e3 }
    );
    promise.then((el2) => cleanups.push(setStyle(el2, { pointerEvents: "auto" })));
    cleanups.push(abort);
  });
  return () => {
    if (layerStack.hasPointerBlockingLayer()) return;
    queueMicrotask(() => {
      const body = doc.body;
      if (!body) return;
      const original = originalBodyPointerEvents.get(body);
      if (original !== void 0) {
        body.style.pointerEvents = original;
        originalBodyPointerEvents.delete(body);
      }
      body.removeAttribute("data-inert");
      if (body.style.length === 0) body.removeAttribute("style");
    });
    cleanups.forEach((fn) => fn());
  };
}

// node_modules/@zag-js/dismissable/dist/dismissable-layer.mjs
function trackDismissableElementImpl(node, options) {
  const {
    onDismiss,
    onRequestDismiss,
    pointerBlocking,
    exclude: excludeContainers,
    debug,
    type = "dialog",
    layerStyleTargets
  } = options;
  const layer = {
    dismiss: onDismiss,
    node,
    type,
    pointerBlocking,
    requestDismiss: onRequestDismiss,
    styleTargets: layerStyleTargets
  };
  layerStack.add(layer);
  assignPointerEventToLayers();
  function onPointerDownOutside(event) {
    const target = getEventTarget(event.detail.originalEvent);
    if (layerStack.isBelowPointerBlockingLayer(node) || layerStack.isInBranch(target)) return;
    options.onPointerDownOutside?.(event);
    options.onInteractOutside?.(event);
    if (event.defaultPrevented) return;
    if (debug) {
      console.log("onPointerDownOutside:", event.detail.originalEvent);
    }
    onDismiss?.();
  }
  function onFocusOutside(event) {
    const target = getEventTarget(event.detail.originalEvent);
    if (layerStack.isInBranch(target)) return;
    options.onFocusOutside?.(event);
    options.onInteractOutside?.(event);
    if (event.defaultPrevented) return;
    if (debug) {
      console.log("onFocusOutside:", event.detail.originalEvent);
    }
    onDismiss?.();
  }
  function onEscapeKeyDown(event) {
    if (!layerStack.isTopMost(node)) return;
    options.onEscapeKeyDown?.(event);
    if (!event.defaultPrevented && onDismiss) {
      event.preventDefault();
      onDismiss();
    }
  }
  function exclude(target) {
    const containers = typeof excludeContainers === "function" ? excludeContainers() : excludeContainers;
    const _containers = Array.isArray(containers) ? containers : [containers];
    const persistentElements = options.persistentElements?.map((fn) => fn()).filter(isHTMLElement);
    if (persistentElements) _containers.push(...persistentElements);
    return _containers.some((node2) => contains(node2, target)) || layerStack.isInNestedLayer(node, target);
  }
  const cleanups = [
    pointerBlocking ? disablePointerEventsOutside(node, options.persistentElements) : void 0,
    trackEscapeKeydown(node, onEscapeKeyDown),
    trackInteractOutside(node, { exclude, onFocusOutside, onPointerDownOutside, defer: options.defer })
  ];
  return () => {
    layerStack.remove(node);
    assignPointerEventToLayers();
    clearPointerEvent(node);
    cleanups.forEach((fn) => fn?.());
  };
}
function trackDismissableElement(nodeOrFn, options) {
  const { warnOnMissingNode = true } = options;
  return whenNode(nodeOrFn, (node) => trackDismissableElementImpl(node, options), {
    defer: options.defer,
    onMissing: warnOnMissingNode ? () => warn("[@zag-js/dismissable] node is `null` or `undefined`") : void 0
  });
}

// node_modules/@zag-js/select/dist/select.machine.mjs
var { and, not, or } = createGuards();
var machine = createMachine({
  props({ props }) {
    return {
      loopFocus: false,
      closeOnSelect: !props.multiple,
      composite: true,
      defaultValue: [],
      ...props,
      collection: props.collection ?? collection.empty(),
      positioning: {
        placement: "bottom-start",
        gutter: 8,
        ...props.positioning
      }
    };
  },
  context({ prop, bindable: bindable2, getContext }) {
    const initialValue = prop("value") ?? prop("defaultValue") ?? [];
    const initialSelectedItems = prop("collection").findMany(initialValue);
    return {
      value: bindable2(() => ({
        defaultValue: prop("defaultValue"),
        value: prop("value"),
        isEqual,
        onChange(value) {
          const context = getContext();
          const collection2 = prop("collection");
          const selectedItemMap = context.get("selectedItemMap");
          const proposed = deriveSelectionState({
            values: value,
            collection: collection2,
            selectedItemMap
          });
          const effectiveValue = prop("value") ?? value;
          const effective = effectiveValue === value ? proposed : deriveSelectionState({
            values: effectiveValue,
            collection: collection2,
            selectedItemMap: proposed.nextSelectedItemMap
          });
          context.set("selectedItemMap", effective.nextSelectedItemMap);
          return prop("onValueChange")?.({ value, items: proposed.selectedItems });
        }
      })),
      highlightedValue: bindable2(() => ({
        defaultValue: prop("defaultHighlightedValue") || null,
        value: prop("highlightedValue"),
        onChange(value) {
          prop("onHighlightChange")?.({
            highlightedValue: value,
            highlightedItem: prop("collection").find(value),
            highlightedIndex: prop("collection").indexOf(value)
          });
        }
      })),
      currentPlacement: bindable2(() => ({
        defaultValue: void 0
      })),
      fieldsetDisabled: bindable2(() => ({
        defaultValue: false
      })),
      highlightedItem: bindable2(() => ({
        defaultValue: null
      })),
      selectedItemMap: bindable2(() => {
        return {
          defaultValue: createSelectedItemMap({
            selectedItems: initialSelectedItems,
            collection: prop("collection")
          })
        };
      })
    };
  },
  refs() {
    return {
      typeahead: { ...getByTypeahead.defaultOptions }
    };
  },
  computed: {
    hasSelectedItems: ({ context }) => context.get("value").length > 0,
    isTypingAhead: ({ refs }) => refs.get("typeahead").keysSoFar !== "",
    isDisabled: ({ prop, context }) => !!prop("disabled") || !!context.get("fieldsetDisabled"),
    isInteractive: ({ prop }) => !(prop("disabled") || prop("readOnly")),
    selectedItems: ({ context, prop }) => resolveSelectedItems({
      values: context.get("value"),
      collection: prop("collection"),
      selectedItemMap: context.get("selectedItemMap")
    }),
    valueAsString: ({ computed, prop }) => prop("collection").stringifyItems(computed("selectedItems"))
  },
  initialState({ prop }) {
    const open = prop("open") || prop("defaultOpen");
    return open ? "open" : "idle";
  },
  entry: ["syncSelectElement"],
  watch({ context, prop, track, action }) {
    track([() => context.get("value").toString()], () => {
      action(["syncSelectedItems", "syncSelectElement", "dispatchChangeEvent"]);
    });
    track([() => prop("open")], () => {
      action(["toggleVisibility"]);
    });
    track([() => context.get("highlightedValue")], () => {
      action(["syncHighlightedItem"]);
    });
    track([() => prop("collection").toString()], () => {
      action(["syncCollection"]);
    });
  },
  on: {
    "HIGHLIGHTED_VALUE.SET": {
      actions: ["setHighlightedItem"]
    },
    "HIGHLIGHTED_VALUE.CLEAR": {
      actions: ["clearHighlightedItem"]
    },
    "ITEM.SELECT": {
      actions: ["selectItem"]
    },
    "ITEM.CLEAR": {
      actions: ["clearItem"]
    },
    "VALUE.SET": {
      actions: ["setSelectedItems"]
    },
    "VALUE.CLEAR": {
      actions: ["clearSelectedItems"]
    },
    "CLEAR.CLICK": {
      actions: ["clearSelectedItems", "focusTriggerEl"]
    }
  },
  effects: ["trackFormControlState"],
  states: {
    idle: {
      tags: ["closed"],
      on: {
        "CONTROLLED.OPEN": [
          {
            guard: "isTriggerClickEvent",
            target: "open",
            actions: ["setInitialFocus", "highlightFirstSelectedItem"]
          },
          {
            target: "open",
            actions: ["setInitialFocus"]
          }
        ],
        "TRIGGER.CLICK": [
          {
            guard: "isOpenControlled",
            actions: ["invokeOnOpen"]
          },
          {
            target: "open",
            actions: ["invokeOnOpen", "setInitialFocus", "highlightFirstSelectedItem"]
          }
        ],
        "TRIGGER.FOCUS": {
          target: "focused"
        },
        OPEN: [
          {
            guard: "isOpenControlled",
            actions: ["invokeOnOpen"]
          },
          {
            target: "open",
            actions: ["setInitialFocus", "invokeOnOpen"]
          }
        ]
      }
    },
    focused: {
      tags: ["closed"],
      on: {
        "CONTROLLED.OPEN": [
          {
            guard: "isTriggerClickEvent",
            target: "open",
            actions: ["setInitialFocus", "highlightFirstSelectedItem"]
          },
          {
            guard: "isTriggerArrowUpEvent",
            target: "open",
            actions: ["setInitialFocus", "highlightComputedLastItem"]
          },
          {
            guard: or("isTriggerArrowDownEvent", "isTriggerEnterEvent"),
            target: "open",
            actions: ["setInitialFocus", "highlightComputedFirstItem"]
          },
          {
            target: "open",
            actions: ["setInitialFocus"]
          }
        ],
        OPEN: [
          {
            guard: "isOpenControlled",
            actions: ["invokeOnOpen"]
          },
          {
            target: "open",
            actions: ["setInitialFocus", "invokeOnOpen"]
          }
        ],
        "TRIGGER.BLUR": {
          target: "idle"
        },
        "TRIGGER.CLICK": [
          {
            guard: "isOpenControlled",
            actions: ["invokeOnOpen"]
          },
          {
            target: "open",
            actions: ["setInitialFocus", "invokeOnOpen", "highlightFirstSelectedItem"]
          }
        ],
        "TRIGGER.ENTER": [
          {
            guard: "isOpenControlled",
            actions: ["invokeOnOpen"]
          },
          {
            target: "open",
            actions: ["setInitialFocus", "invokeOnOpen", "highlightComputedFirstItem"]
          }
        ],
        "TRIGGER.ARROW_UP": [
          {
            guard: "isOpenControlled",
            actions: ["invokeOnOpen"]
          },
          {
            target: "open",
            actions: ["setInitialFocus", "invokeOnOpen", "highlightComputedLastItem"]
          }
        ],
        "TRIGGER.ARROW_DOWN": [
          {
            guard: "isOpenControlled",
            actions: ["invokeOnOpen"]
          },
          {
            target: "open",
            actions: ["setInitialFocus", "invokeOnOpen", "highlightComputedFirstItem"]
          }
        ],
        "TRIGGER.ARROW_LEFT": [
          {
            guard: and(not("multiple"), "hasSelectedItems"),
            actions: ["selectPreviousItem"]
          },
          {
            guard: not("multiple"),
            actions: ["selectLastItem"]
          }
        ],
        "TRIGGER.ARROW_RIGHT": [
          {
            guard: and(not("multiple"), "hasSelectedItems"),
            actions: ["selectNextItem"]
          },
          {
            guard: not("multiple"),
            actions: ["selectFirstItem"]
          }
        ],
        "TRIGGER.HOME": {
          guard: not("multiple"),
          actions: ["selectFirstItem"]
        },
        "TRIGGER.END": {
          guard: not("multiple"),
          actions: ["selectLastItem"]
        },
        "TRIGGER.TYPEAHEAD": {
          guard: not("multiple"),
          actions: ["selectMatchingItem"]
        }
      }
    },
    open: {
      tags: ["open"],
      exit: ["scrollContentToTop"],
      effects: ["trackDismissableElement", "trackFocusVisible", "computePlacement", "scrollToHighlightedItem"],
      on: {
        "CONTROLLED.CLOSE": [
          {
            guard: "restoreFocus",
            target: "focused",
            actions: ["focusTriggerEl", "clearHighlightedItem"]
          },
          {
            target: "idle",
            actions: ["clearHighlightedItem"]
          }
        ],
        CLOSE: [
          {
            guard: "isOpenControlled",
            actions: ["invokeOnClose"]
          },
          {
            guard: "restoreFocus",
            target: "focused",
            actions: ["invokeOnClose", "focusTriggerEl", "clearHighlightedItem"]
          },
          {
            target: "idle",
            actions: ["invokeOnClose", "clearHighlightedItem"]
          }
        ],
        "TRIGGER.CLICK": [
          {
            guard: "isOpenControlled",
            actions: ["invokeOnClose"]
          },
          {
            target: "focused",
            actions: ["invokeOnClose", "clearHighlightedItem"]
          }
        ],
        "ITEM.CLICK": [
          {
            guard: and("closeOnSelect", "isOpenControlled"),
            actions: ["selectHighlightedItem", "invokeOnClose"]
          },
          {
            guard: "closeOnSelect",
            target: "focused",
            actions: ["selectHighlightedItem", "invokeOnClose", "focusTriggerEl", "clearHighlightedItem"]
          },
          {
            actions: ["selectHighlightedItem"]
          }
        ],
        "CONTENT.HOME": {
          actions: ["highlightFirstItem"]
        },
        "CONTENT.END": {
          actions: ["highlightLastItem"]
        },
        "CONTENT.ARROW_DOWN": [
          {
            guard: and("hasHighlightedItem", "loop", "isLastItemHighlighted"),
            actions: ["highlightFirstItem"]
          },
          {
            guard: "hasHighlightedItem",
            actions: ["highlightNextItem"]
          },
          {
            actions: ["highlightFirstItem"]
          }
        ],
        "CONTENT.ARROW_UP": [
          {
            guard: and("hasHighlightedItem", "loop", "isFirstItemHighlighted"),
            actions: ["highlightLastItem"]
          },
          {
            guard: "hasHighlightedItem",
            actions: ["highlightPreviousItem"]
          },
          {
            actions: ["highlightLastItem"]
          }
        ],
        "CONTENT.TYPEAHEAD": {
          actions: ["highlightMatchingItem"]
        },
        "ITEM.POINTER_MOVE": {
          actions: ["highlightItem"]
        },
        "ITEM.POINTER_LEAVE": {
          actions: ["clearHighlightedItem"]
        },
        "POSITIONING.SET": {
          actions: ["reposition"]
        }
      }
    }
  },
  implementations: {
    guards: {
      loop: ({ prop }) => !!prop("loopFocus"),
      multiple: ({ prop }) => !!prop("multiple"),
      hasSelectedItems: ({ computed }) => !!computed("hasSelectedItems"),
      hasHighlightedItem: ({ context }) => context.get("highlightedValue") != null,
      isFirstItemHighlighted: ({ context, prop }) => context.get("highlightedValue") === prop("collection").firstValue,
      isLastItemHighlighted: ({ context, prop }) => context.get("highlightedValue") === prop("collection").lastValue,
      closeOnSelect: ({ prop, event }) => !!(event.closeOnSelect ?? prop("closeOnSelect")),
      restoreFocus: ({ event }) => restoreFocusFn(event),
      // guard assertions (for controlled mode)
      isOpenControlled: ({ prop }) => prop("open") !== void 0,
      isTriggerClickEvent: ({ event }) => event.previousEvent?.type === "TRIGGER.CLICK",
      isTriggerEnterEvent: ({ event }) => event.previousEvent?.type === "TRIGGER.ENTER",
      isTriggerArrowUpEvent: ({ event }) => event.previousEvent?.type === "TRIGGER.ARROW_UP",
      isTriggerArrowDownEvent: ({ event }) => event.previousEvent?.type === "TRIGGER.ARROW_DOWN"
    },
    effects: {
      trackFocusVisible({ scope }) {
        return trackFocusVisible({ root: scope.getRootNode?.() });
      },
      trackFormControlState({ context, scope }) {
        return trackFormControl(getHiddenSelectEl(scope), {
          onFieldsetDisabledChange(disabled) {
            context.set("fieldsetDisabled", disabled);
          },
          onFormReset() {
            const value = context.initial("value");
            context.set("value", value);
          }
        });
      },
      trackDismissableElement({ scope, send, prop }) {
        const contentEl = () => getContentEl(scope);
        let restoreFocus = true;
        return trackDismissableElement(contentEl, {
          type: "listbox",
          defer: true,
          exclude: [getTriggerEl(scope), getClearTriggerEl(scope)],
          onFocusOutside: prop("onFocusOutside"),
          onPointerDownOutside: prop("onPointerDownOutside"),
          onInteractOutside(event) {
            prop("onInteractOutside")?.(event);
            restoreFocus = !(event.detail.focusable || event.detail.contextmenu);
          },
          onDismiss() {
            send({ type: "CLOSE", src: "interact-outside", restoreFocus });
          }
        });
      },
      computePlacement({ context, prop, scope }) {
        const positioning = prop("positioning");
        context.set("currentPlacement", positioning.placement);
        const triggerEl = () => getTriggerEl(scope);
        const positionerEl = () => getPositionerEl(scope);
        return getPlacement(triggerEl, positionerEl, {
          defer: true,
          ...positioning,
          onComplete(data) {
            context.set("currentPlacement", data.placement);
          }
        });
      },
      scrollToHighlightedItem({ context, prop, scope }) {
        const exec = (immediate) => {
          const highlightedValue = context.get("highlightedValue");
          if (highlightedValue == null) return;
          const modality = getInteractionModality();
          if (modality === "pointer") return;
          const contentEl2 = getContentEl(scope);
          const scrollToIndexFn = prop("scrollToIndexFn");
          if (scrollToIndexFn) {
            const highlightedIndex = prop("collection").indexOf(highlightedValue);
            scrollToIndexFn?.({
              index: highlightedIndex,
              immediate,
              getElement: () => getItemEl(scope, highlightedValue)
            });
            return;
          }
          const itemEl = getItemEl(scope, highlightedValue);
          scrollIntoView(itemEl, { rootEl: contentEl2, block: "nearest" });
        };
        raf(() => {
          setInteractionModality("virtual");
          exec(true);
        });
        const contentEl = () => getContentEl(scope);
        return observeAttributes(contentEl, {
          defer: true,
          attributes: ["data-activedescendant"],
          callback() {
            exec(false);
          }
        });
      }
    },
    actions: {
      reposition({ context, prop, scope, event }) {
        const positionerEl = () => getPositionerEl(scope);
        getPlacement(getTriggerEl(scope), positionerEl, {
          ...prop("positioning"),
          ...event.options,
          defer: true,
          listeners: false,
          onComplete(data) {
            context.set("currentPlacement", data.placement);
          }
        });
      },
      toggleVisibility({ send, prop, event }) {
        send({ type: prop("open") ? "CONTROLLED.OPEN" : "CONTROLLED.CLOSE", previousEvent: event });
      },
      highlightPreviousItem({ context, prop }) {
        const highlightedValue = context.get("highlightedValue");
        if (highlightedValue == null) return;
        const value = prop("collection").getPreviousValue(highlightedValue, 1, prop("loopFocus"));
        if (value == null) return;
        context.set("highlightedValue", value);
      },
      highlightNextItem({ context, prop }) {
        const highlightedValue = context.get("highlightedValue");
        if (highlightedValue == null) return;
        const value = prop("collection").getNextValue(highlightedValue, 1, prop("loopFocus"));
        if (value == null) return;
        context.set("highlightedValue", value);
      },
      highlightFirstItem({ context, prop }) {
        const value = prop("collection").firstValue;
        context.set("highlightedValue", value);
      },
      highlightLastItem({ context, prop }) {
        const value = prop("collection").lastValue;
        context.set("highlightedValue", value);
      },
      setInitialFocus({ scope }) {
        raf(() => {
          const element = getInitialFocus({
            root: getContentEl(scope)
          });
          element?.focus({ preventScroll: true });
        });
      },
      focusTriggerEl({ event, scope }) {
        if (!restoreFocusFn(event)) return;
        raf(() => {
          const element = getTriggerEl(scope);
          element?.focus({ preventScroll: true });
        });
      },
      selectHighlightedItem({ context, prop, event }) {
        let value = event.value ?? context.get("highlightedValue");
        if (value == null || !prop("collection").has(value)) return;
        prop("onSelect")?.({ value });
        const nullable = prop("deselectable") && !prop("multiple") && context.get("value").includes(value);
        value = nullable ? null : value;
        context.set("value", (prev) => {
          if (value == null) return [];
          if (prop("multiple")) return addOrRemove(prev, value);
          return [value];
        });
      },
      highlightComputedFirstItem({ context, prop, computed }) {
        const collection2 = prop("collection");
        const value = computed("hasSelectedItems") ? collection2.sort(context.get("value"))[0] : collection2.firstValue;
        context.set("highlightedValue", value);
      },
      highlightComputedLastItem({ context, prop, computed }) {
        const collection2 = prop("collection");
        const value = computed("hasSelectedItems") ? collection2.sort(context.get("value"))[0] : collection2.lastValue;
        context.set("highlightedValue", value);
      },
      highlightFirstSelectedItem({ context, prop, computed }) {
        if (!computed("hasSelectedItems")) return;
        const value = prop("collection").sort(context.get("value"))[0];
        context.set("highlightedValue", value);
      },
      highlightItem({ context, event }) {
        context.set("highlightedValue", event.value);
      },
      highlightMatchingItem({ context, prop, event, refs }) {
        const value = prop("collection").search(event.key, {
          state: refs.get("typeahead"),
          currentValue: context.get("highlightedValue")
        });
        if (value == null) return;
        context.set("highlightedValue", value);
      },
      setHighlightedItem({ context, event }) {
        context.set("highlightedValue", event.value);
      },
      clearHighlightedItem({ context }) {
        context.set("highlightedValue", null);
      },
      selectItem({ context, prop, event }) {
        prop("onSelect")?.({ value: event.value });
        const nullable = prop("deselectable") && !prop("multiple") && context.get("value").includes(event.value);
        const value = nullable ? null : event.value;
        context.set("value", (prev) => {
          if (value == null) return [];
          if (prop("multiple")) return addOrRemove(prev, value);
          return [value];
        });
      },
      clearItem({ context, event }) {
        context.set("value", (prev) => prev.filter((v) => v !== event.value));
      },
      setSelectedItems({ context, event }) {
        context.set("value", event.value);
      },
      clearSelectedItems({ context }) {
        context.set("value", []);
      },
      selectPreviousItem({ context, prop }) {
        const [firstItem] = context.get("value");
        const value = prop("collection").getPreviousValue(firstItem);
        if (value) context.set("value", [value]);
      },
      selectNextItem({ context, prop }) {
        const [firstItem] = context.get("value");
        const value = prop("collection").getNextValue(firstItem);
        if (value) context.set("value", [value]);
      },
      selectFirstItem({ context, prop }) {
        const value = prop("collection").firstValue;
        if (value) context.set("value", [value]);
      },
      selectLastItem({ context, prop }) {
        const value = prop("collection").lastValue;
        if (value) context.set("value", [value]);
      },
      selectMatchingItem({ context, prop, event, refs }) {
        const value = prop("collection").search(event.key, {
          state: refs.get("typeahead"),
          currentValue: context.get("value")[0]
        });
        if (value == null) return;
        context.set("value", [value]);
      },
      scrollContentToTop({ prop, scope }) {
        if (prop("scrollToIndexFn")) {
          const firstValue = prop("collection").firstValue;
          prop("scrollToIndexFn")?.({
            index: 0,
            immediate: true,
            getElement: () => getItemEl(scope, firstValue)
          });
        } else {
          getContentEl(scope)?.scrollTo(0, 0);
        }
      },
      invokeOnOpen({ prop, context }) {
        prop("onOpenChange")?.({ open: true, value: context.get("value") });
      },
      invokeOnClose({ prop, context }) {
        prop("onOpenChange")?.({ open: false, value: context.get("value") });
      },
      syncSelectElement({ context, prop, scope }) {
        const selectEl = getHiddenSelectEl(scope);
        if (!selectEl) return;
        if (context.get("value").length === 0 && !prop("multiple")) {
          selectEl.selectedIndex = -1;
          return;
        }
        for (const option of selectEl.options) {
          option.selected = context.get("value").includes(option.value);
        }
      },
      syncCollection({ context, prop }) {
        const collection2 = prop("collection");
        const highlightedItem = collection2.find(context.get("highlightedValue"));
        if (highlightedItem) context.set("highlightedItem", highlightedItem);
        const next = deriveSelectionState({
          values: context.get("value"),
          collection: collection2,
          selectedItemMap: context.get("selectedItemMap")
        });
        context.set("selectedItemMap", next.nextSelectedItemMap);
      },
      syncSelectedItems({ context, prop }) {
        const next = deriveSelectionState({
          values: context.get("value"),
          collection: prop("collection"),
          selectedItemMap: context.get("selectedItemMap")
        });
        context.set("selectedItemMap", next.nextSelectedItemMap);
      },
      syncHighlightedItem({ context, prop }) {
        const collection2 = prop("collection");
        const highlightedValue = context.get("highlightedValue");
        const highlightedItem = highlightedValue ? collection2.find(highlightedValue) : null;
        context.set("highlightedItem", highlightedItem);
      },
      dispatchChangeEvent({ scope }) {
        queueMicrotask(() => {
          const node = getHiddenSelectEl(scope);
          if (!node) return;
          const win = scope.getWin();
          const evt = new win.Event("change", { bubbles: true, composed: true });
          node.dispatchEvent(markAsInternalChangeEvent(evt));
        });
      }
    }
  }
});
function restoreFocusFn(event) {
  const v = event.restoreFocus ?? event.previousEvent?.restoreFocus;
  return v == null || !!v;
}

// node_modules/@zag-js/types/dist/prop-types.mjs
function createNormalizer(fn) {
  return new Proxy({}, {
    get(_target, key) {
      if (key === "style")
        return (props) => {
          return fn({ style: props }).style;
        };
      return fn;
    }
  });
}

// node_modules/@zag-js/vanilla/dist/chunk-QZ7TP4HQ.mjs
var __defProp3 = Object.defineProperty;
var __defNormalProp3 = (obj, key, value) => key in obj ? __defProp3(obj, key, { enumerable: true, configurable: true, writable: true, value }) : obj[key] = value;
var __publicField3 = (obj, key, value) => __defNormalProp3(obj, typeof key !== "symbol" ? key + "" : key, value);

// node_modules/@zag-js/vanilla/dist/normalize-props.mjs
var propMap = {
  onFocus: "onFocusin",
  onBlur: "onFocusout",
  onChange: "onInput",
  onDoubleClick: "onDblclick",
  htmlFor: "for",
  className: "class",
  defaultValue: "value",
  defaultChecked: "checked"
};
var caseSensitiveSvgAttrs = /* @__PURE__ */ new Set(["viewBox", "preserveAspectRatio"]);
var normalizeProps = createNormalizer((props) => {
  return Object.entries(props).reduce((acc, [key, value]) => {
    if (value === void 0) return acc;
    if (key in propMap) {
      key = propMap[key];
    }
    const normalizedKey = caseSensitiveSvgAttrs.has(key) ? key : key.toLowerCase();
    acc[normalizedKey] = value;
    return acc;
  }, {});
});

// node_modules/@zag-js/vanilla/dist/spread-props.mjs
var prevAttrsMap = /* @__PURE__ */ new WeakMap();
var assignableProps = /* @__PURE__ */ new Set(["value", "checked", "selected"]);
var caseSensitiveSvgAttrs2 = /* @__PURE__ */ new Set([
  "viewBox",
  "preserveAspectRatio",
  "clipPath",
  "clipRule",
  "fillRule",
  "strokeWidth",
  "strokeLinecap",
  "strokeLinejoin",
  "strokeDasharray",
  "strokeDashoffset",
  "strokeMiterlimit"
]);
var isSvgElement = (node) => {
  return node.tagName === "svg" || node.namespaceURI === "http://www.w3.org/2000/svg";
};
var getAttributeName = (node, attrName) => {
  const shouldPreserveCase = isSvgElement(node) && caseSensitiveSvgAttrs2.has(attrName);
  return shouldPreserveCase ? attrName : attrName.toLowerCase();
};
var toCssProperty = (key) => key.startsWith("--") ? key : key.replace(/[A-Z]/g, (match3) => `-${match3.toLowerCase()}`);
var applyStyle = (node, prevStyle, nextStyle) => {
  if (typeof nextStyle === "string") {
    node.setAttribute("style", nextStyle);
    return;
  }
  if (nextStyle == null && typeof prevStyle === "string") {
    node.removeAttribute("style");
    return;
  }
  const style = node.style;
  if (style == null) return;
  for (const key in prevStyle) {
    if (nextStyle?.[key] == null) style.removeProperty(toCssProperty(key));
  }
  for (const key in nextStyle) {
    const value = nextStyle[key];
    if (value == null) style.removeProperty(toCssProperty(key));
    else style.setProperty(toCssProperty(key), String(value));
  }
};
function spreadProps(node, attrs, machineId) {
  const scopeKey = machineId || "default";
  let machineMap = prevAttrsMap.get(node);
  if (!machineMap) {
    machineMap = /* @__PURE__ */ new Map();
    prevAttrsMap.set(node, machineMap);
  }
  const oldAttrs = machineMap.get(scopeKey) || {};
  const attrKeys = Object.keys(attrs);
  const addEvt = (e, f) => {
    node.addEventListener(e.toLowerCase(), f);
  };
  const remEvt = (e, f) => {
    node.removeEventListener(e.toLowerCase(), f);
  };
  const onEvents = (attr) => attr.startsWith("on");
  const others = (attr) => !attr.startsWith("on");
  const setup = (attr) => addEvt(attr.substring(2), attrs[attr]);
  const teardown = (attr) => remEvt(attr.substring(2), attrs[attr]);
  const apply = (attrName) => {
    const value = attrs[attrName];
    const oldValue = oldAttrs[attrName];
    if (value === oldValue) return;
    if (attrName === "class") {
      ;
      node.className = value ?? "";
      return;
    }
    if (attrName === "style") {
      applyStyle(node, oldValue, value);
      return;
    }
    if (assignableProps.has(attrName)) {
      ;
      node[attrName] = value ?? "";
      return;
    }
    if (typeof value === "boolean" && !attrName.includes("aria-")) {
      ;
      node.toggleAttribute(getAttributeName(node, attrName), value);
      return;
    }
    if (attrName === "children") {
      node.innerHTML = value;
      return;
    }
    if (value != null) {
      node.setAttribute(getAttributeName(node, attrName), value);
      return;
    }
    node.removeAttribute(getAttributeName(node, attrName));
  };
  for (const key in oldAttrs) {
    if (attrs[key] == null) {
      if (key === "class") {
        ;
        node.className = "";
      } else if (key === "style") {
        applyStyle(node, oldAttrs[key], void 0);
      } else if (assignableProps.has(key)) {
        ;
        node[key] = "";
      } else {
        node.removeAttribute(getAttributeName(node, key));
      }
    }
  }
  const oldEvents = Object.keys(oldAttrs).filter(onEvents);
  oldEvents.forEach((evt) => {
    remEvt(evt.substring(2), oldAttrs[evt]);
  });
  attrKeys.filter(onEvents).forEach(setup);
  attrKeys.filter(others).forEach(apply);
  machineMap.set(scopeKey, attrs);
  return function cleanup() {
    attrKeys.filter(onEvents).forEach(teardown);
    const currentMachineMap = prevAttrsMap.get(node);
    if (currentMachineMap) {
      currentMachineMap.delete(scopeKey);
      if (currentMachineMap.size === 0) {
        prevAttrsMap.delete(node);
      }
    }
  };
}

// node_modules/@zag-js/store/dist/global.mjs
function glob() {
  if (typeof globalThis !== "undefined") return globalThis;
  if (typeof self !== "undefined") return self;
  if (typeof window !== "undefined") return window;
  if (typeof global !== "undefined") return global;
}
function globalRef(key, value) {
  const g = glob();
  if (!g) return value();
  g[key] || (g[key] = value());
  return g[key];
}
var refSet = globalRef("__zag__refSet", () => /* @__PURE__ */ new WeakSet());

// node_modules/@zag-js/store/dist/utils.mjs
var isReactElement2 = (x) => typeof x === "object" && x !== null && "$$typeof" in x && "props" in x;
var isVueElement2 = (x) => typeof x === "object" && x !== null && "__v_isVNode" in x;
var isDOMElement = (x) => typeof x === "object" && x !== null && "nodeType" in x && typeof x.nodeName === "string";
var isElement2 = (x) => isReactElement2(x) || isVueElement2(x) || isDOMElement(x);
var isObject3 = (x) => x !== null && typeof x === "object";
var canProxy = (x) => isObject3(x) && !refSet.has(x) && (Array.isArray(x) || !(Symbol.iterator in x)) && !isElement2(x) && !(x instanceof WeakMap) && !(x instanceof WeakSet) && !(x instanceof Error) && !(x instanceof Number) && !(x instanceof Date) && !(x instanceof String) && !(x instanceof RegExp) && !(x instanceof ArrayBuffer) && !(x instanceof Promise) && !(x instanceof File) && !(x instanceof Blob) && !(x instanceof AbortController);
var isDev = () => true;

// node_modules/proxy-compare/dist/index.js
var TRACK_MEMO_SYMBOL = Symbol();
var GET_ORIGINAL_SYMBOL = Symbol();
var getProto = Object.getPrototypeOf;
var objectsToTrack = /* @__PURE__ */ new WeakMap();
var isObjectToTrack = (obj) => obj && (objectsToTrack.has(obj) ? objectsToTrack.get(obj) : getProto(obj) === Object.prototype || getProto(obj) === Array.prototype);
var getUntracked = (obj) => {
  if (isObjectToTrack(obj)) {
    return obj[GET_ORIGINAL_SYMBOL] || null;
  }
  return null;
};
var markToTrack = (obj, mark = true) => {
  objectsToTrack.set(obj, mark);
};

// node_modules/@zag-js/store/dist/proxy.mjs
var proxyStateMap = globalRef("__zag__proxyStateMap", () => /* @__PURE__ */ new WeakMap());
var buildProxyFunction = (objectIs = Object.is, newProxy = (target, handler) => new Proxy(target, handler), snapCache = /* @__PURE__ */ new WeakMap(), createSnapshot = (target, version) => {
  const cache = snapCache.get(target);
  if (cache?.[0] === version) {
    return cache[1];
  }
  const snap = Array.isArray(target) ? [] : Object.create(Object.getPrototypeOf(target));
  markToTrack(snap, true);
  snapCache.set(target, [version, snap]);
  Reflect.ownKeys(target).forEach((key) => {
    const value = Reflect.get(target, key);
    if (refSet.has(value)) {
      markToTrack(value, false);
      snap[key] = value;
    } else if (proxyStateMap.has(value)) {
      snap[key] = snapshot(value);
    } else {
      snap[key] = value;
    }
  });
  return Object.freeze(snap);
}, proxyCache = /* @__PURE__ */ new WeakMap(), versionHolder = [1, 1], proxyFunction2 = (initialObject) => {
  if (!isObject3(initialObject)) {
    throw new Error("object required");
  }
  const found = proxyCache.get(initialObject);
  if (found) {
    return found;
  }
  let version = versionHolder[0];
  const listeners = /* @__PURE__ */ new Set();
  const notifyUpdate = (op, nextVersion = ++versionHolder[0]) => {
    if (version !== nextVersion) {
      version = nextVersion;
      listeners.forEach((listener) => listener(op, nextVersion));
    }
  };
  let checkVersion = versionHolder[1];
  const ensureVersion = (nextCheckVersion = ++versionHolder[1]) => {
    if (checkVersion !== nextCheckVersion && !listeners.size) {
      checkVersion = nextCheckVersion;
      propProxyStates.forEach(([propProxyState]) => {
        const propVersion = propProxyState[1](nextCheckVersion);
        if (propVersion > version) {
          version = propVersion;
        }
      });
    }
    return version;
  };
  const createPropListener = (prop) => (op, nextVersion) => {
    const newOp = [...op];
    newOp[1] = [prop, ...newOp[1]];
    notifyUpdate(newOp, nextVersion);
  };
  const propProxyStates = /* @__PURE__ */ new Map();
  const addPropListener = (prop, propProxyState) => {
    if (isDev() && propProxyStates.has(prop)) {
      throw new Error("prop listener already exists");
    }
    if (listeners.size) {
      const remove2 = propProxyState[3](createPropListener(prop));
      propProxyStates.set(prop, [propProxyState, remove2]);
    } else {
      propProxyStates.set(prop, [propProxyState]);
    }
  };
  const removePropListener = (prop) => {
    const entry = propProxyStates.get(prop);
    if (entry) {
      propProxyStates.delete(prop);
      entry[1]?.();
    }
  };
  const addListener = (listener) => {
    listeners.add(listener);
    if (listeners.size === 1) {
      propProxyStates.forEach(([propProxyState, prevRemove], prop) => {
        if (isDev() && prevRemove) {
          throw new Error("remove already exists");
        }
        const remove2 = propProxyState[3](createPropListener(prop));
        propProxyStates.set(prop, [propProxyState, remove2]);
      });
    }
    const removeListener = () => {
      listeners.delete(listener);
      if (listeners.size === 0) {
        propProxyStates.forEach(([propProxyState, remove2], prop) => {
          if (remove2) {
            remove2();
            propProxyStates.set(prop, [propProxyState]);
          }
        });
      }
    };
    return removeListener;
  };
  const baseObject = Array.isArray(initialObject) ? [] : Object.create(Object.getPrototypeOf(initialObject));
  const handler = {
    deleteProperty(target, prop) {
      const prevValue = Reflect.get(target, prop);
      removePropListener(prop);
      const deleted = Reflect.deleteProperty(target, prop);
      if (deleted) {
        notifyUpdate(["delete", [prop], prevValue]);
      }
      return deleted;
    },
    set(target, prop, value, receiver) {
      const hasPrevValue = Reflect.has(target, prop);
      const prevValue = Reflect.get(target, prop, receiver);
      if (hasPrevValue && (objectIs(prevValue, value) || proxyCache.has(value) && objectIs(prevValue, proxyCache.get(value)))) {
        return true;
      }
      removePropListener(prop);
      if (isObject3(value)) {
        value = getUntracked(value) || value;
      }
      let nextValue = value;
      if (Object.getOwnPropertyDescriptor(target, prop)?.set) {
      } else {
        if (!proxyStateMap.has(value) && canProxy(value)) {
          nextValue = proxy(value);
        }
        const childProxyState = !refSet.has(nextValue) && proxyStateMap.get(nextValue);
        if (childProxyState) {
          addPropListener(prop, childProxyState);
        }
      }
      Reflect.set(target, prop, nextValue, receiver);
      notifyUpdate(["set", [prop], value, prevValue]);
      return true;
    }
  };
  const proxyObject = newProxy(baseObject, handler);
  proxyCache.set(initialObject, proxyObject);
  const proxyState = [baseObject, ensureVersion, createSnapshot, addListener];
  proxyStateMap.set(proxyObject, proxyState);
  Reflect.ownKeys(initialObject).forEach((key) => {
    const desc = Object.getOwnPropertyDescriptor(initialObject, key);
    if (desc.get || desc.set) {
      Object.defineProperty(baseObject, key, desc);
    } else {
      proxyObject[key] = initialObject[key];
    }
  });
  return proxyObject;
}) => [
  // public functions
  proxyFunction2,
  // shared state
  proxyStateMap,
  refSet,
  // internal things
  objectIs,
  newProxy,
  canProxy,
  snapCache,
  createSnapshot,
  proxyCache,
  versionHolder
];
var [proxyFunction] = buildProxyFunction();
function proxy(initialObject = {}) {
  return proxyFunction(initialObject);
}
function subscribe(proxyObject, callback, notifyInSync) {
  const proxyState = proxyStateMap.get(proxyObject);
  if (isDev() && !proxyState) {
    console.warn("Please use proxy object");
  }
  let promise;
  const ops = [];
  const addListener = proxyState[3];
  let isListenerActive = false;
  const listener = (op) => {
    ops.push(op);
    if (notifyInSync) {
      callback(ops.splice(0));
      return;
    }
    if (!promise) {
      promise = Promise.resolve().then(() => {
        promise = void 0;
        if (isListenerActive) {
          callback(ops.splice(0));
        }
      });
    }
  };
  const removeListener = addListener(listener);
  isListenerActive = true;
  return () => {
    isListenerActive = false;
    removeListener();
  };
}
function snapshot(proxyObject) {
  const proxyState = proxyStateMap.get(proxyObject);
  if (isDev() && !proxyState) {
    console.warn("Please use proxy object");
  }
  const [target, ensureVersion, createSnapshot] = proxyState;
  return createSnapshot(target, ensureVersion());
}

// node_modules/@zag-js/vanilla/dist/bindable.mjs
function bindable(props) {
  const initial = props().value ?? props().defaultValue;
  if (props().debug) {
    console.log(`[bindable > ${props().debug}] initial`, initial);
  }
  const eq = props().isEqual ?? Object.is;
  const store = proxy({ value: initial });
  const controlled = () => props().value !== void 0;
  return {
    initial,
    ref: store,
    get() {
      return controlled() ? props().value : store.value;
    },
    set(nextValue) {
      const prev = controlled() ? props().value : store.value;
      const next = isFunction(nextValue) ? nextValue(prev) : nextValue;
      if (props().debug) {
        console.log(`[bindable > ${props().debug}] setValue`, { next, prev });
      }
      if (!controlled()) store.value = next;
      if (!eq(next, prev)) {
        props().onChange?.(next, prev);
      }
    },
    invoke(nextValue, prevValue) {
      props().onChange?.(nextValue, prevValue);
    },
    hash(value) {
      return props().hash?.(value) ?? String(value);
    }
  };
}
bindable.cleanup = (_fn) => {
};
bindable.ref = (defaultValue) => {
  let value = defaultValue;
  return {
    get: () => value,
    set: (next) => {
      value = next;
    }
  };
};

// node_modules/@zag-js/vanilla/dist/refs.mjs
function createRefs(refs) {
  const ref2 = { current: refs };
  return {
    get(key) {
      return ref2.current[key];
    },
    set(key, value) {
      ref2.current[key] = value;
    }
  };
}

// node_modules/@zag-js/vanilla/dist/merge-machine-props.mjs
function mergeMachineProps(prev, next) {
  if (!isPlainObject(prev) || !isPlainObject(next)) {
    return next === void 0 ? prev : next;
  }
  const result = { ...prev };
  for (const key of Object.keys(next)) {
    const nextValue = next[key];
    const prevValue = prev[key];
    if (nextValue === void 0) {
      continue;
    }
    if (isPlainObject(prevValue) && isPlainObject(nextValue)) {
      result[key] = mergeMachineProps(prevValue, nextValue);
    } else {
      result[key] = nextValue;
    }
  }
  return result;
}

// node_modules/@zag-js/vanilla/dist/machine.mjs
var VanillaMachine = class {
  constructor(machine2, userProps = {}) {
    __publicField3(this, "machine", machine2);
    __publicField3(this, "scope");
    __publicField3(this, "context");
    __publicField3(this, "prop");
    __publicField3(this, "state");
    __publicField3(this, "refs");
    __publicField3(this, "computed");
    __publicField3(this, "event", { type: "" });
    __publicField3(this, "previousEvent", { type: "" });
    __publicField3(this, "effects", /* @__PURE__ */ new Map());
    __publicField3(this, "replaceTracker", createReplaceTracker());
    __publicField3(this, "transition", null);
    __publicField3(this, "cleanups", []);
    __publicField3(this, "subscriptions", []);
    __publicField3(this, "userPropsRef");
    __publicField3(this, "getEvent", () => ({
      ...this.event,
      current: () => this.event,
      previous: () => this.previousEvent
    }));
    __publicField3(this, "getState", () => ({
      ...this.state,
      matches: (...values) => values.some((value) => matchesState(this.state.get(), value)),
      hasTag: (tag) => hasTag(this.machine, this.state.get(), tag)
    }));
    __publicField3(this, "debug", (...args) => {
      if (this.machine.debug) console.log(...args);
    });
    __publicField3(this, "notify", () => {
      this.publish();
    });
    __publicField3(this, "send", (event) => {
      if (this.status !== MachineStatus.Started) return;
      const key = event?.replaces;
      const token = key ? this.replaceTracker.claim(key) : void 0;
      queueMicrotask(() => {
        if (!event) return;
        if (key && token && this.replaceTracker.isReplaced(key, token)) return;
        this.previousEvent = this.event;
        this.event = event;
        this.debug("send", event);
        let currentState = this.state.get();
        const eventType = event.type;
        const { transitions, source } = findTransition(this.machine, currentState, eventType);
        const transition = this.choose(transitions);
        if (!transition) return;
        this.transition = transition;
        const target = resolveStateValue(this.machine, transition.target ?? currentState, source);
        this.debug("transition", transition);
        const changed = target !== currentState;
        if (changed) {
          this.state.set(target);
        } else if (transition.reenter) {
          this.state.invoke(currentState, currentState);
        } else {
          this.action(transition.actions);
        }
      });
    });
    __publicField3(this, "action", (keys) => {
      const strs = isFunction(keys) ? keys(this.getParams()) : keys;
      if (!strs) return;
      const fns = strs.map((s) => {
        const fn = this.machine.implementations?.actions?.[s];
        if (!fn) warn(`[zag-js] No implementation found for action "${JSON.stringify(s)}"`);
        return fn;
      });
      for (const fn of fns) {
        fn?.(this.getParams());
      }
    });
    __publicField3(this, "guard", (str) => {
      if (isFunction(str)) return str(this.getParams());
      const fn = this.machine.implementations?.guards?.[str];
      if (!fn) warn(`[zag-js] No implementation found for guard "${JSON.stringify(str)}"`);
      return fn?.(this.getParams());
    });
    __publicField3(this, "effect", (keys) => {
      const strs = isFunction(keys) ? keys(this.getParams()) : keys;
      if (!strs) return;
      const fns = strs.map((s) => {
        const fn = this.machine.implementations?.effects?.[s];
        if (!fn) warn(`[zag-js] No implementation found for effect "${JSON.stringify(s)}"`);
        return fn;
      });
      const cleanups = [];
      for (const fn of fns) {
        const cleanup = fn?.(this.getParams());
        if (cleanup) cleanups.push(cleanup);
      }
      return () => cleanups.forEach((fn) => fn?.());
    });
    __publicField3(this, "choose", (transitions) => {
      return toArray(transitions).find((t) => {
        let result = !t.guard;
        if (isString(t.guard)) result = !!this.guard(t.guard);
        else if (isFunction(t.guard)) result = t.guard(this.getParams());
        return result;
      });
    });
    __publicField3(this, "subscribe", (fn) => {
      this.subscriptions.push(fn);
      return () => {
        const index = this.subscriptions.indexOf(fn);
        if (index > -1) this.subscriptions.splice(index, 1);
      };
    });
    __publicField3(this, "status", MachineStatus.NotStarted);
    __publicField3(this, "publish", () => {
      this.callTrackers();
      this.subscriptions.forEach((fn) => fn(this.service));
    });
    __publicField3(this, "trackers", []);
    __publicField3(this, "setupTrackers", () => {
      this.machine.watch?.(this.getParams());
    });
    __publicField3(this, "callTrackers", () => {
      this.trackers.forEach(({ deps, fn }) => {
        const next = deps.map((dep) => dep());
        if (!isEqual(fn.prev, next)) {
          fn();
          fn.prev = next;
        }
      });
    });
    __publicField3(this, "getParams", () => ({
      state: this.getState(),
      context: this.context,
      event: this.getEvent(),
      prop: this.prop,
      send: this.send,
      action: this.action,
      guard: this.guard,
      track: (deps, fn) => {
        fn.prev = deps.map((dep) => dep());
        this.trackers.push({ deps, fn });
      },
      refs: this.refs,
      computed: this.computed,
      flush: identity,
      scope: this.scope,
      choose: this.choose
    }));
    this.userPropsRef = { current: userProps };
    const { id, ids, getRootNode: getRootNode2 } = runIfFn(userProps);
    this.scope = createScope({ id, ids, getRootNode: getRootNode2 });
    const prop = (key) => {
      const __props = runIfFn(this.userPropsRef.current);
      const props = machine2.props?.({ props: compact(__props), scope: this.scope }) ?? __props;
      return props[key];
    };
    this.prop = prop;
    const context = machine2.context?.({
      prop,
      bindable,
      scope: this.scope,
      flush(fn) {
        queueMicrotask(fn);
      },
      getContext() {
        return ctx;
      },
      getComputed() {
        return computed;
      },
      getRefs() {
        return refs;
      },
      getEvent: this.getEvent.bind(this)
    });
    if (context) {
      Object.values(context).forEach((item) => {
        const unsub = subscribe(item.ref, () => this.notify());
        this.cleanups.push(unsub);
      });
    }
    const ctx = {
      get(key) {
        return context?.[key].get();
      },
      set(key, value) {
        context?.[key].set(value);
      },
      initial(key) {
        return context?.[key].initial;
      },
      hash(key) {
        const current = context?.[key].get();
        return context?.[key].hash(current);
      }
    };
    this.context = ctx;
    const computed = (key) => {
      ensure(machine2.computed, () => `[zag-js] No computed object found on machine`);
      return machine2.computed[key]({
        context: ctx,
        event: this.getEvent(),
        prop,
        refs: this.refs,
        scope: this.scope,
        computed
      });
    };
    this.computed = computed;
    const refs = createRefs(machine2.refs?.({ prop, context: ctx }) ?? {});
    this.refs = refs;
    const state = bindable(() => ({
      defaultValue: resolveStateValue(machine2, machine2.initialState({ prop })),
      onChange: (nextState, prevState) => {
        const { exiting, entering } = getExitEnterStates(this.machine, prevState, nextState, this.transition?.reenter);
        exiting.forEach((item) => {
          const exitEffects = this.effects.get(item.path);
          exitEffects?.();
          this.effects.delete(item.path);
        });
        exiting.forEach((item) => {
          this.action(item.state?.exit);
        });
        this.action(this.transition?.actions);
        entering.forEach((item) => {
          const cleanup = this.effect(item.state?.effects);
          if (cleanup) {
            const existing = this.effects.get(item.path);
            this.effects.set(item.path, existing ? callAll(existing, cleanup) : cleanup);
          }
        });
        if (prevState === INIT_STATE) {
          this.action(machine2.entry);
          const cleanup = this.effect(machine2.effects);
          if (cleanup) {
            const existing = this.effects.get(INIT_STATE);
            this.effects.set(INIT_STATE, existing ? callAll(existing, cleanup) : cleanup);
          }
        }
        entering.forEach((item) => {
          this.action(item.state?.entry);
        });
      }
    }));
    this.state = state;
    this.cleanups.push(subscribe(this.state.ref, () => this.notify()));
  }
  updateProps(newProps) {
    const prevSource = this.userPropsRef.current;
    this.userPropsRef.current = () => {
      const prev = runIfFn(prevSource);
      const next = runIfFn(newProps);
      return mergeMachineProps(prev, next);
    };
    this.notify();
  }
  start() {
    this.status = MachineStatus.Started;
    this.debug("initializing...");
    this.state.invoke(this.state.initial, INIT_STATE);
    this.setupTrackers();
  }
  stop() {
    this.effects.forEach((fn) => fn?.());
    this.effects.clear();
    this.transition = null;
    this.action(this.machine.exit);
    this.cleanups.forEach((unsub) => unsub());
    this.cleanups = [];
    this.subscriptions = [];
    this.status = MachineStatus.Stopped;
    this.debug("unmounting...");
  }
  get service() {
    return {
      state: this.getState(),
      send: this.send,
      context: this.context,
      prop: this.prop,
      scope: this.scope,
      refs: this.refs,
      computed: this.computed,
      event: this.getEvent(),
      getStatus: () => this.status
    };
  }
};

// assets/js/zag/bridge.js
var REGISTRIES = Symbol("lantern:zag-hook-registries");
function createDomEventRegistry(target) {
  const entries = [];
  return {
    add(eventName, listener) {
      target.addEventListener(eventName, listener);
      entries.push({ eventName, listener });
    },
    teardown() {
      for (const { eventName, listener } of entries) {
        target.removeEventListener(eventName, listener);
      }
      entries.length = 0;
    }
  };
}
function createHookHandleEventRegistry(hook) {
  const refs = [];
  return {
    add(eventName, fn) {
      refs.push(hook.handleEvent(eventName, fn));
    },
    teardown() {
      if (typeof hook.removeHandleEvent !== "function") return;
      for (const ref2 of refs) hook.removeHandleEvent(ref2);
      refs.length = 0;
    }
  };
}
function createZagLiveHook(config) {
  const componentOf = (hook) => hook[config.key];
  return {
    mounted() {
      const registries = {
        dom: createDomEventRegistry(this.el),
        server: createHookHandleEventRegistry(this)
      };
      this[REGISTRIES] = registries;
      const component = config.mount(this, registries) || void 0;
      if (!component) return;
      component.init();
      this[config.key] = component;
      config.afterInit?.(this, component);
    },
    beforeUpdate() {
      if (config.controlledKeys) this.beforeAttrs = snapshotDataset(this.el, config.controlledKeys);
      config.beforeUpdate?.(this);
    },
    updated() {
      const component = componentOf(this);
      if (!component) return;
      try {
        config.update?.(this, component);
      } finally {
        this.beforeAttrs = void 0;
      }
    },
    disconnected() {
      const component = componentOf(this);
      if (component) config.disconnected?.(this, component);
    },
    reconnected() {
      const component = componentOf(this);
      if (component) config.reconnected?.(this, component);
    },
    destroyed() {
      this[REGISTRIES]?.dom.teardown();
      this[REGISTRIES]?.server.teardown();
      this[REGISTRIES] = void 0;
      const component = componentOf(this);
      if (component) config.destroy?.(this, component);
      component?.destroy();
      this[config.key] = void 0;
      this.beforeAttrs = void 0;
    }
  };
}
function snapshotDataset(el, keys) {
  const snap = {};
  for (const key of keys) snap[key] = el.dataset[key];
  return snap;
}
function datasetKeyChanged(before, el, key) {
  if (before === void 0) return true;
  return before[key] !== el.dataset[key];
}
function getString(el, attrName, validValues) {
  const value = el.dataset[attrName];
  if (value !== void 0 && (!validValues || validValues.includes(value))) return value;
  return void 0;
}
function getBoolean(el, attrName) {
  const dashName = attrName.replace(/([A-Z])/g, "-$1").toLowerCase();
  const key = `data-${dashName}`;
  if (!el.hasAttribute(key)) return false;
  const raw = el.getAttribute(key);
  if (raw === "false" || raw === "0") return false;
  return true;
}
function getDir(el) {
  const fromEl = el.dataset.dir;
  if (fromEl === "ltr" || fromEl === "rtl") return fromEl;
  const fromDoc = document.documentElement.getAttribute("dir");
  if (fromDoc === "ltr" || fromDoc === "rtl") return fromDoc;
  return "ltr";
}
function partPropsMethod(part2) {
  const camel = part2.split("-").map((segment) => segment.charAt(0).toUpperCase() + segment.slice(1)).join("");
  return `get${camel}Props`;
}
function safeParseJson(raw, fallback2) {
  if (raw == null || raw === "") return fallback2;
  try {
    return JSON.parse(raw);
  } catch (error) {
    console.error("Failed to parse JSON", error);
    return fallback2;
  }
}
function canPushEvent(liveSocket) {
  try {
    return liveSocket?.getSocket?.()?.isConnected?.() ?? true;
  } catch {
    return true;
  }
}
function syncInputFormAssociation(input, hookEl) {
  if (!input) return;
  const formId = getString(hookEl, "form");
  if (hookEl.closest("form") !== null) {
    input.removeAttribute("form");
  } else if (formId) {
    input.setAttribute("form", formId);
  }
}
function parseDatasetValueList(raw) {
  if (raw === void 0) return [];
  const trimmed = raw.trim();
  if (trimmed === "") return [];
  if (trimmed.startsWith("[")) {
    const parsed = safeParseJson(trimmed, []);
    if (Array.isArray(parsed) && parsed.every((item) => typeof item === "string")) return parsed;
    return [];
  }
  return trimmed.split(",").map((v) => v.trim()).filter((v) => v.length > 0);
}
function isZagValueControlled(el) {
  return getBoolean(el, "controlled");
}
function mountStringListBinding(el) {
  if (isZagValueControlled(el)) return { value: parseDatasetValueList(el.dataset.value) };
  return { defaultValue: parseDatasetValueList(el.dataset.defaultValue) };
}
function readStringListControlledZagProps(el) {
  return mountStringListBinding(el);
}
function readUpdatedServerStringList(el, before) {
  if (!isZagValueControlled(el)) return {};
  if (!datasetKeyChanged(before, el, "value")) return {};
  return { value: parseDatasetValueList(el.dataset.value) };
}
function idMatches(elId, payloadId, opts) {
  if (payloadId === void 0 || payloadId === null || payloadId === "") {
    return opts?.broadcast === true;
  }
  return elId === payloadId;
}
function readPayloadId(payload) {
  if (!payload || typeof payload !== "object") return void 0;
  let generic;
  for (const k of Object.keys(payload)) {
    const v = payload[k];
    if (typeof v !== "string" || v === "") continue;
    if (k === "id" || k === "Id") {
      generic = v;
    } else if (k.includes("_id") || k.length > 2 && k.endsWith("Id")) {
      return v;
    }
  }
  return generic;
}
function notifyChange({ el, canPushServer, pushEvent, payload, serverEventName, clientEventName }) {
  if (serverEventName && canPushServer) pushEvent(serverEventName, { ...payload });
  if (clientEventName) {
    el.dispatchEvent(new CustomEvent(clientEventName, { bubbles: true, detail: payload }));
  }
}
var HEAVY_PROP_KEYS = /* @__PURE__ */ new Set(["collection"]);
function stableValueKey(value) {
  if (value === null) return "null";
  const type = typeof value;
  if (type === "string") return JSON.stringify(value);
  if (type === "number" || type === "boolean") return String(value);
  if (type === "undefined") return "undefined";
  if (type === "function" || type === "symbol" || type === "bigint") return "";
  if (typeof value !== "object") return String(value);
  if (Array.isArray(value)) return `[${value.map(stableValueKey).join(",")}]`;
  try {
    return JSON.stringify(
      value,
      (_key, nested) => typeof nested === "function" ? void 0 : nested
    );
  } catch {
    return String(value);
  }
}
function stableUpdatePropsKey(props) {
  const keys = Object.keys(props).sort();
  let out = "";
  for (const key of keys) {
    if (HEAVY_PROP_KEYS.has(key)) continue;
    const value = props[key];
    if (typeof value === "function") continue;
    out += `${key}:${stableValueKey(value)};`;
  }
  return out;
}
var Component = class {
  constructor(el, props, beforeInitMachine) {
    if (!el) throw new Error("Root element not found");
    this.el = el;
    this.doc = document;
    beforeInitMachine?.(this);
    this.machine = this.initMachine(props);
    this.api = this.initApi();
    this.unsubscribe = void 0;
    this.lastUpdatePropsKey = void 0;
    this.spreadCleanups = /* @__PURE__ */ new Map();
  }
  initMachine(_props) {
    throw new Error("initMachine must be implemented");
  }
  initApi() {
    throw new Error("initApi must be implemented");
  }
  render() {
    throw new Error("render must be implemented");
  }
  init = () => {
    try {
      this.machine.start();
      this.api = this.initApi();
      this.render();
      this.unsubscribe = this.machine.subscribe(() => {
        this.api = this.initApi();
        this.render();
      });
    } finally {
      this.el.removeAttribute("data-loading");
    }
  };
  clearSpreadPropsCleanups = () => {
    for (const cleanup of this.spreadCleanups.values()) cleanup();
    this.spreadCleanups.clear();
  };
  destroy = () => {
    this.el.removeAttribute("data-loading");
    this.unsubscribe?.();
    this.unsubscribe = void 0;
    this.clearSpreadPropsCleanups();
    this.machine.stop();
  };
  spreadProps = (el, props) => {
    const cleanup = spreadProps(el, props, this.machine.scope.id);
    this.spreadCleanups.set(el, cleanup);
  };
  updateProps(props, opts) {
    const key = stableUpdatePropsKey(props);
    if (!opts?.force && key === this.lastUpdatePropsKey) return false;
    this.lastUpdatePropsKey = key;
    this.machine.updateProps(props);
    return true;
  }
  zagConnect(connectFn) {
    return connectFn(this.machine.service, normalizeProps);
  }
};

// assets/js/zag/select.js
var SCOPE = "select";
var part = (name) => `[data-scope="${SCOPE}"][data-part="${name}"]`;
function readItems(el) {
  const raw = el.getAttribute("data-items") ?? "[]";
  const parsed = safeParseJson(raw, []);
  return Array.isArray(parsed) ? parsed : [];
}
function collectionConfig(items) {
  return {
    items,
    itemToValue: (item) => String(item.value ?? ""),
    itemToString: (item) => item.label,
    isItemDisabled: (item) => !!item.disabled
  };
}
function findItem(options, value) {
  return options.find((item) => String(item.value ?? "") === String(value));
}
var LanternSelect = class extends Component {
  constructor(el, props) {
    super(el, props);
    this._options = props.collection?.items ?? [];
    this.placeholder = getString(this.el, "placeholder") || "";
  }
  get options() {
    return Array.isArray(this._options) ? this._options : [];
  }
  setOptions(options) {
    this._options = Array.isArray(options) ? options : [];
  }
  getCollection() {
    return collection(collectionConfig(this.options));
  }
  initMachine(props) {
    const getCollection = this.getCollection.bind(this);
    return new VanillaMachine(machine, {
      ...props,
      get collection() {
        return getCollection();
      }
    });
  }
  initApi() {
    return this.zagConnect(connect);
  }
  applyItemProps() {
    const contentEl = this.el.querySelector(part("content"));
    if (!contentEl) return;
    const isOwnedByContent = (el) => el.closest(part("content")) === contentEl;
    contentEl.querySelectorAll(part("item")).forEach((itemEl) => {
      if (!isOwnedByContent(itemEl)) return;
      const value = itemEl.dataset.value ?? "";
      if (!value) return;
      const item = findItem(this.options, value);
      if (!item) return;
      this.spreadProps(itemEl, this.api.getItemProps({ item }));
      const textEl = itemEl.querySelector(part("item-text"));
      if (textEl) this.spreadProps(textEl, this.api.getItemTextProps({ item }));
      const indicatorEl = itemEl.querySelector(part("item-indicator"));
      if (indicatorEl) this.spreadProps(indicatorEl, this.api.getItemIndicatorProps({ item }));
    });
  }
  /** Lantern toggle contract: placeholder / single label / "N selected". */
  updateTriggerText() {
    const valueText = this.el.querySelector(`${part("trigger")} ${part("item-text")}`);
    if (!valueText) return;
    const values = this.api.value ?? [];
    if (values.length === 0) {
      valueText.textContent = this.placeholder;
      valueText.setAttribute("data-empty", "");
    } else if (values.length === 1) {
      valueText.textContent = findItem(this.options, values[0])?.label ?? this.placeholder;
      valueText.removeAttribute("data-empty");
    } else {
      valueText.textContent = `${values.length} selected`;
      valueText.removeAttribute("data-empty");
    }
  }
  syncHiddenSelect() {
    const hiddenSelect = this.el.querySelector(part("hidden-select"));
    if (!hiddenSelect || !hiddenSelect.name) return false;
    const valueSet = new Set((this.api.value ?? []).map(String));
    let changed = false;
    for (const option of hiddenSelect.options) {
      if (option.value === "") {
        if (option.selected) {
          option.selected = false;
          changed = true;
        }
        continue;
      }
      const selected = valueSet.has(option.value);
      if (option.selected !== selected) {
        option.selected = selected;
        changed = true;
      }
    }
    if (changed) {
      hiddenSelect.dispatchEvent(new Event("input", { bubbles: true }));
      hiddenSelect.dispatchEvent(new Event("change", { bubbles: true }));
    }
    return changed;
  }
  render() {
    const root = this.el.querySelector(part("root")) ?? this.el;
    this.spreadProps(root, this.api.getRootProps());
    const hiddenSelect = this.el.querySelector(part("hidden-select"));
    if (hiddenSelect) {
      this.spreadProps(hiddenSelect, this.api.getHiddenSelectProps());
      syncInputFormAssociation(hiddenSelect, this.el);
      const valueSet = new Set((this.api.value ?? []).map(String));
      for (const option of hiddenSelect.options) {
        if (option.value === "") {
          option.selected = false;
          continue;
        }
        option.selected = valueSet.has(option.value);
      }
      syncInputFormAssociation(hiddenSelect, this.el);
    }
    for (const name of ["control", "trigger", "clear-trigger", "positioner"]) {
      const el = this.el.querySelector(part(name));
      if (!el) continue;
      this.spreadProps(el, this.api[partPropsMethod(name)]());
    }
    const contentEl = this.el.querySelector(part("content"));
    if (contentEl) {
      this.spreadProps(contentEl, this.api.getContentProps());
      const labelledBy = getString(this.el, "labelledBy");
      if (labelledBy) contentEl.setAttribute("aria-labelledby", labelledBy);
      this.applyItemProps();
    }
    this.placeholder = getString(this.el, "placeholder") || "";
    this.updateTriggerText();
  }
};
function serverValueKey(el) {
  return JSON.stringify(parseDatasetValueList(el.dataset.value).map(String).sort());
}
function selectLayoutProps(el) {
  const props = {
    id: el.id,
    disabled: getBoolean(el, "disabled"),
    multiple: getBoolean(el, "multiple"),
    invalid: getBoolean(el, "invalid"),
    dir: getDir(el),
    name: getString(el, "name"),
    form: getString(el, "form"),
    positioning: { placement: "bottom-start", sameWidth: true }
  };
  const triggerId = getString(el, "triggerId");
  if (triggerId) props.ids = { trigger: triggerId };
  return props;
}
function createOnValueChange(getEl, pushEvent, canPush, getLastValue, setLastValue) {
  return (details) => {
    const el = getEl();
    const next = (details.value ?? []).map(String);
    const max2 = Number.parseInt(el.dataset.max || "", 10);
    if (el.hasAttribute("data-multiple") && Number.isFinite(max2) && max2 > 0 && next.length > max2) {
      const component2 = getEl().__lanternSelect;
      component2?.api.setValue(getLastValue());
      return;
    }
    setLastValue(next);
    if (getBoolean(el, "controlled")) {
      const echo = JSON.stringify([...next].sort()) === serverValueKey(el);
      if (echo) return;
    }
    const component = getEl().__lanternSelect;
    component?.syncHiddenSelect();
    notifyChange({
      el,
      canPushServer: canPush(),
      pushEvent,
      payload: { id: el.id, value: next },
      serverEventName: getString(el, "onChange"),
      clientEventName: getString(el, "onChangeClient")
    });
  };
}
var LanternZagSelect = createZagLiveHook({
  key: "select",
  controlledKeys: ["value"],
  mount(hook, { dom, server }) {
    const el = hook.el;
    const pushEvent = hook.pushEvent.bind(hook);
    const canPush = () => canPushEvent(hook.liveSocket);
    let lastValue = null;
    const onValueChange = createOnValueChange(
      () => hook.el,
      pushEvent,
      canPush,
      () => lastValue ?? [],
      (next) => {
        lastValue = next;
      }
    );
    const items = readItems(el);
    const component = new LanternSelect(el, {
      ...selectLayoutProps(el),
      collection: collection(collectionConfig(items)),
      onValueChange,
      ...readStringListControlledZagProps(el)
    });
    component.setOptions(items);
    lastValue = [...component.api.value ?? []].map(String);
    el.__lanternSelect = component;
    hook.lastItemsJson = el.getAttribute("data-items") ?? "[]";
    dom.add("lantern:select:set-value", (event) => {
      const value = event.detail?.value;
      if (value !== void 0) component.api.setValue(value.map(String));
    });
    dom.add("lantern:select:set-open", (event) => {
      if (typeof event.detail?.open === "boolean") component.api.setOpen(event.detail.open);
    });
    server.add("lantern:select:set-value", (payload) => {
      if (!idMatches(el.id, readPayloadId(payload))) return;
      const value = payload?.value;
      if (Array.isArray(value)) component.api.setValue(value.map(String));
    });
    server.add("lantern:select:set-open", (payload) => {
      if (!idMatches(el.id, readPayloadId(payload))) return;
      if (typeof payload?.open === "boolean") component.api.setOpen(payload.open);
    });
    return component;
  },
  update(hook, select) {
    const json = hook.el.getAttribute("data-items") ?? "[]";
    let itemsChanged = false;
    if (json !== hook.lastItemsJson) {
      hook.lastItemsJson = json;
      select.setOptions(readItems(hook.el));
      itemsChanged = true;
    }
    const valuePatch = readUpdatedServerStringList(hook.el, hook.beforeAttrs);
    if (itemsChanged && valuePatch.value === void 0) {
      const available = new Set(select.options.map((item) => String(item.value ?? "")));
      const current = (select.api.value ?? []).map(String);
      const next = current.filter((v) => available.has(v));
      if (next.length !== current.length) select.api.setValue(next);
    }
    select.updateProps(
      {
        ...selectLayoutProps(hook.el),
        collection: select.getCollection(),
        ...valuePatch.value !== void 0 ? { value: valuePatch.value } : {}
      },
      { force: itemsChanged }
    );
    select.render();
    hook.el.removeAttribute("data-loading");
    if (getBoolean(hook.el, "disabled")) return;
    const trigger = hook.el.querySelector(part("trigger"));
    if (trigger && !trigger.hasAttribute("disabled")) {
      trigger.disabled = false;
      trigger.removeAttribute("disabled");
    }
  }
});
function mountZagSelect(hook) {
  const context = Object.create(LanternZagSelect);
  Object.assign(context, {
    el: hook.el,
    pushEvent: hook.pushEvent.bind(hook),
    handleEvent: hook.handleEvent.bind(hook),
    removeHandleEvent: hook.removeHandleEvent?.bind(hook),
    liveSocket: hook.liveSocket
  });
  context.mounted();
  if (hook._zagPendingUpdate) {
    hook._zagPendingUpdate = false;
    context.beforeUpdate();
    context.updated();
  }
  return {
    beforeUpdate: () => context.beforeUpdate(),
    updated: () => context.updated(),
    destroyed: () => context.destroyed()
  };
}
export {
  LanternSelect,
  LanternZagSelect,
  mountZagSelect
};
//! LanternUI Zag bridge — adapts Corex v0.2.2 (MIT, © 2025 Netoum.com).
//! Full attribution: assets/js/zag/NOTICE_COREX.
