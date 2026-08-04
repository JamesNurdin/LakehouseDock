/* goal: Identify stores with strong sales performance in the early 2000s, calculate total sales, profit and returns, filter by store name patterns and city, and keep only stores that had no matching return records for the same year (anti‑join). */
WITH sales_agg AS (
    SELECT
        s.s_store_sk,
        s.s_store_name,
        s.s_city,
        d.d_year,
        SUM(ss.ss_ext_sales_price)          AS total_sales,
        SUM(ss.ss_net_profit)               AS total_profit,
        COUNT(*)                            AS sales_cnt
    FROM store_sales ss
    JOIN store      s ON ss.ss_store_sk = s.s_store_sk
    JOIN date_dim   d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
      AND regexp_like(s.s_store_name, '(?i)Mart|Store')      -- name contains “Mart” or “Store” (case‑insensitive)
      AND s.s_city LIKE '%York%'
    GROUP BY s.s_store_sk, s.s_store_name, s.s_city, d.d_year
)
SELECT
    sa.s_store_name,
    sa.s_city,
    sa.d_year,
    sa.total_sales,
    sa.total_profit,
    COALESCE(ret.return_total, 0)                     AS return_total,
    substr(sa.s_store_name, 1, 5)                     AS store_name_prefix,
    concat('Store-', cast(sa.s_store_sk AS varchar)) AS store_key,
    regexp_extract(sa.s_city, '(\\w+)', 1)          AS city_first_word
FROM sales_agg sa
LEFT JOIN LATERAL (
    SELECT SUM(sr.sr_return_amt_inc_tax) AS return_total
    FROM store_returns sr
    JOIN date_dim d_ret ON sr.sr_returned_date_sk = d_ret.d_date_sk
    WHERE sr.sr_store_sk = sa.s_store_sk
      AND d_ret.d_year = sa.d_year
) ret ON true
WHERE NOT EXISTS (
    SELECT 1
    FROM store_returns sr2
    JOIN date_dim d2 ON sr2.sr_returned_date_sk = d2.d_date_sk
    WHERE sr2.sr_store_sk = sa.s_store_sk
      AND d2.d_year = sa.d_year
)
ORDER BY sa.total_sales DESC
LIMIT 100
