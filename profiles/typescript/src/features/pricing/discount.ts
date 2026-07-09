// このファイルの目的: 層境界サンプル(中間層 features)。core にのみ依存できる。
// app や他の feature への import は .dependency-cruiser.cjs が遮断する(make arch で検証)。

import type { Money } from "../../core/money";

export function applyDiscount(price: Money, rate: number): Money {
  if (rate < 0 || rate > 1) {
    throw new RangeError(`割引率は 0〜1 で指定する: ${rate}`);
  }
  return { amountJpy: Math.round(price.amountJpy * (1 - rate)) };
}
