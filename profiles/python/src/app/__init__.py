"""アプリケーションパッケージ。層構成は api → services → models(依存は一方向のみ)。

層契約は pyproject.toml の [tool.importlinter] が正本。make arch で検証される。
"""
