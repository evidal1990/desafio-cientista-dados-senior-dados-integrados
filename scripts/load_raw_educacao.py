#!/usr/bin/env python3
from __future__ import annotations

import io
import os
import sys
from pathlib import Path
import polars as pl
import psycopg2
from psycopg2 import sql

TABLES = (
    "aluno",
    "escola",
    "turma",
    "frequencia",
    "avaliacao",
)


def _load_dotenv(repo_root: Path) -> None:
    env_path = repo_root / ".env"
    if not env_path.is_file():
        return
    for line in env_path.read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, _, val = line.partition("=")
        key = key.strip()
        val = val.strip().strip("'").strip('"')
        if key and key not in os.environ:
            os.environ[key] = val


def _binary_to_hex_utf8(df: pl.DataFrame) -> pl.DataFrame:
    out = df
    for name, dtype in df.schema.items():
        if dtype == pl.Binary:
            out = out.with_columns(pl.col(name).bin.encode("hex").alias(name))
    return out


def _bimestre_to_int(df: pl.DataFrame, table: str) -> pl.DataFrame:
    if table != "avaliacao" or "bimestre" not in df.columns:
        return df
    return df.with_columns(pl.col("bimestre").cast(pl.Int64, strict=False))


def _pg_type(dtype: pl.DataType) -> str:
    if dtype in (
        pl.Int8,
        pl.Int16,
        pl.Int32,
        pl.Int64,
        pl.UInt8,
        pl.UInt16,
        pl.UInt32,
        pl.UInt64,
    ):
        return "BIGINT"
    if dtype in (pl.Float32, pl.Float64):
        return "DOUBLE PRECISION"
    if dtype in (pl.Utf8, pl.String):
        return "TEXT"
    if dtype == pl.Boolean:
        return "BOOLEAN"
    if dtype == pl.Date:
        return "DATE"
    if dtype == pl.Datetime:
        return "TIMESTAMP"
    raise TypeError(f"Tipo Polars não mapeado: {dtype}")


def _connect():
    return psycopg2.connect(
        host=os.environ["POSTGRES_HOST"],
        port=int(os.environ.get("POSTGRES_PORT", "5432")),
        user=os.environ["POSTGRES_USER"],
        password=os.environ["POSTGRES_PASSWORD"],
        dbname=os.environ["POSTGRES_DB"],
    )


def _write_table(conn, schema: str, table: str, df: pl.DataFrame) -> None:
    col_defs = [
        (sql.Identifier(c), sql.SQL(_pg_type(df.schema[c]))) for c in df.columns
    ]
    create_stmt = sql.SQL("CREATE TABLE {}.{} ({})").format(
        sql.Identifier(schema),
        sql.Identifier(table),
        sql.SQL(", ").join(
            sql.SQL("{} {}").format(ident, typ) for ident, typ in col_defs
        ),
    )
    buf = io.StringIO()
    df.write_csv(buf)
    buf.seek(0)
    copy_stmt = sql.SQL(
        "COPY {}.{} FROM STDIN WITH (FORMAT csv, HEADER true, NULL '')"
    ).format(
        sql.Identifier(schema),
        sql.Identifier(table),
    )
    with conn.cursor() as cur:
        cur.execute(
            sql.SQL("DROP TABLE IF EXISTS {}.{} CASCADE").format(
                sql.Identifier(schema),
                sql.Identifier(table),
            )
        )
        cur.execute(create_stmt)
        cur.copy_expert(copy_stmt, buf)
    conn.commit()


def main() -> int:
    repo_root = Path(__file__).resolve().parents[1]
    _load_dotenv(repo_root)

    for key in (
        "POSTGRES_HOST",
        "POSTGRES_USER",
        "POSTGRES_PASSWORD",
        "POSTGRES_DB",
    ):
        if key not in os.environ:
            print(f"Variável de ambiente ausente: {key}", file=sys.stderr)
            return 1

    raw_schema = os.environ.get("RAW_SCHEMA", "raw_educacao")
    data_dir = Path(os.environ.get("DATA_DIR", repo_root / "data")).resolve()

    missing = [t for t in TABLES if not (data_dir / t).is_file()]
    if missing:
        print(
            f"Arquivos Parquet ausentes em {data_dir}: {missing}. "
            "Baixe de gs://case_vagas/rmi/ (gsutil ou console) antes de carregar.",
            file=sys.stderr,
        )
        return 1

    conn = _connect()
    try:
        with conn.cursor() as cur:
            cur.execute(
                sql.SQL("CREATE SCHEMA IF NOT EXISTS {}").format(
                    sql.Identifier(raw_schema)
                )
            )
        conn.commit()

        for name in TABLES:
            path = data_dir / name
            df = pl.read_parquet(path)
            df = _binary_to_hex_utf8(df)
            df = _bimestre_to_int(df, name)
            _write_table(conn, raw_schema, name, df)
            print(f"OK  {raw_schema}.{name}  ({len(df):,} linhas)")
    finally:
        conn.close()

    print("Carga concluída. Rode: dbt debug && dbt run")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
