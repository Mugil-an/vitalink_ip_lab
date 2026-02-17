import type { Config } from "jest";

const config: Config = {
    testEnvironment: "node",
    roots: ["<rootDir>/tests"],
    moduleFileExtensions: ["ts", "tsx", "js", "jsx", "json"],
    extensionsToTreatAsEsm: [".ts"],
    transform: {
        "^.+\\.(ts|tsx)$": [
            "ts-jest",
            {
                tsconfig: "<rootDir>/tsconfig.json",
                useESM: true
            }
        ]
    },
    moduleNameMapper: {
        "^@alias/(.*)$": "<rootDir>/src/$1"
    },
    collectCoverageFrom: ["src/**/*.ts", "!src/**/index.ts", "!src/**/types/**"],
    coverageDirectory: "coverage",
    reporters: ["default"],
    forceExit: true,
    clearMocks: true,
};

export default config;