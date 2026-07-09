// このファイルの目的: テストの置き方サンプル。実装ファイルの隣に *.test.ts として置く。
import { describe, expect, it } from "vitest";
import { applyDiscount } from "./discount";

describe("applyDiscount", () => {
  it("割引率を適用し、端数は四捨五入する", () => {
    expect(applyDiscount({ amountJpy: 999 }, 0.1)).toEqual({ amountJpy: 899 });
  });

  it("範囲外の割引率は即座に失敗する", () => {
    expect(() => applyDiscount({ amountJpy: 1000 }, 1.5)).toThrow(RangeError);
  });
});
