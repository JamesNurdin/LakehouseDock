WITH base AS (
    SELECT
        d.d_fy_year,
        d.d_quarter_seq,
        ss.ss_quantity,
        ss.ss_list_price,
        ss.ss_sales_price,
        ss.ss_ext_sales_price,
        ss.ss_net_profit
    FROM store_sales ss
    JOIN date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE ss.ss_quantity > 1
      AND ss.ss_list_price >= 10
      AND ss.ss_sales_price > 0
      AND d.d_fy_year BETWEEN 1905 AND 1910
      AND d.d_quarter_seq IN (12, 13, 14, 15, 16)
),
agg_by_fy_quarter AS (
    SELECT
        d_fy_year,
        d_quarter_seq,
        SUM(ss_net_profit) AS total_net_profit,
        SUM(ss_ext_sales_price) AS total_sales,
        COUNT(*) AS txn_count
    FROM base
    GROUP BY d_fy_year, d_quarter_seq
),
yearly_agg AS (
    SELECT
        d_fy_year,
        SUM(total_net_profit) AS year_total_net_profit,
        SUM(total_sales) AS year_total_sales,
        SUM(txn_count) AS year_txn_count
    FROM agg_by_fy_quarter
    GROUP BY d_fy_year
)
SELECT
    a.d_fy_year,
    a.d_quarter_seq,
    a.total_net_profit,
    a.total_sales,
    a.txn_count,
    (SELECT MAX(a2.total_net_profit)
     FROM agg_by_fy_quarter a2
     WHERE a2.d_fy_year = a.d_fy_year) AS max_profit_in_year,
    SUM(a.total_net_profit) OVER (PARTITION BY a.d_fy_year ORDER BY a.d_quarter_seq) AS cum_net_profit,
    RANK() OVER (PARTITION BY a.d_fy_year ORDER BY a.total_net_profit DESC) AS profit_rank
FROM agg_by_fy_quarter a
WHERE a.total_sales > (
    SELECT AVG(b.total_sales)
    FROM agg_by_fy_quarter b
    WHERE b.d_fy_year = a.d_fy_year
)

UNION DISTINCT

SELECT
    y.d_fy_year,
    NULL AS d_quarter_seq,
    y.year_total_net_profit AS total_net_profit,
    y.year_total_sales AS total_sales,
    y.year_txn_count AS txn_count,
    y.year_total_net_profit AS max_profit_in_year,
    SUM(y.year_total_net_profit) OVER (PARTITION BY y.d_fy_year) AS cum_net_profit,
    RANK() OVER (PARTITION BY y.d_fy_year ORDER BY y.year_total_net_profit DESC) AS profit_rank
FROM yearly_agg y

ORDER BY d_fy_year, d_quarter_seq
LIMIT 100
