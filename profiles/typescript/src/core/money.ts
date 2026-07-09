// このファイルの目的: 層境界サンプル(最下層 core)。上位層に依存しない純粋なドメインロジックだけを置く。
// 最初の実装に置き換えてよいが、「core は app / features に依存しない」契約は維持する。

export interface Money {
  readonly amountJpy: number;
}

export function addMoney(a: Money, b: Money): Money {
  return { amountJpy: a.amountJpy + b.amountJpy };
}

export function formatJpy(money: Money): string {
  if (!Number.isInteger(money.amountJpy)) {
    // フェイルファスト: 円は整数のみ。丸めは呼び出し側の責務(暗黙の丸めは事故のもと)
    throw new RangeError(`金額は整数で指定する: ${money.amountJpy}`);
  }
  return `¥${money.amountJpy.toLocaleString("ja-JP")}`;
}
