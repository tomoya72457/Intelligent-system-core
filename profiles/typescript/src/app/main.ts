// このファイルの目的: 層境界サンプル(最上層 app)。features / core を組み立てる合成ルート。
// 副作用(CLI・HTTP・環境変数の読み取り等)はこの層にだけ置く。

import { formatJpy } from "../core/money";
import { applyDiscount } from "../features/pricing/discount";

export function buildPriceReport(baseAmountJpy: number, discountRate: number): string {
  const discounted = applyDiscount({ amountJpy: baseAmountJpy }, discountRate);
  return `割引後価格: ${formatJpy(discounted)}`;
}
