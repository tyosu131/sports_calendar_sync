"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.presentationNameKey = presentationNameKey;
exports.clubPresentation = clubPresentation;
const teamPresentationCatalog_json_1 = __importDefault(require("./teamPresentationCatalog.json"));
function presentationNameKey(value) {
    return value.replace(/[！-～]/g, c => String.fromCharCode(c.charCodeAt(0) - 0xfee0))
        .toLowerCase().replace(/[\s.\-・&]/g, '');
}
/** Exact unique display evidence only; never assigns a canonical/provider ID. */
function clubPresentation(names, competitionKey) {
    const keys = new Set(names.map(presentationNameKey).filter(Boolean));
    const matches = teamPresentationCatalog_json_1.default.filter(entry => entry.aliases.some(alias => keys.has(presentationNameKey(alias))) ||
        (entry.competitionKeys.includes(competitionKey ?? '') &&
            entry.scopedAliases.some(alias => keys.has(presentationNameKey(alias)))));
    return matches.length === 1 ? matches[0] : undefined;
}
//# sourceMappingURL=clubPresentation.js.map