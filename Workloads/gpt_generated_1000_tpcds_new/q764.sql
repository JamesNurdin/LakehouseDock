-- Goal: Compare yearly profit from store sales with yearly loss from web returns, broken down by store or return reason, using advanced analytics features.
WITH sales_agg AS (
    SELECT
        d.d_year AS year,
        CASE WHEN GROUPING(ss.ss_store_sk) = 0 THEN CAST(ss.ss_store_sk AS VARCHAR) END AS entity,
        'store_sales' AS source,
        SUM(ss.ss_net_profit) AS amount
    FROM (
        SELECT *
        FROM store_sales
        TABLESAMPLE BERNOULLI (10)
    ) ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE ss.ss_customer_sk NOT IN (
        SELECT DISTINCT c.c_customer_sk
        FROM customer c
        WHERE c.c_preferred_cust_flag = 'N'
    )
    GROUP BY GROUPING SETS (
        (d.d_year),
        (ss.ss_store_sk),
        (d.d_year, ss.ss_store_sk)
    )
),
returns_agg AS (
    SELECT
        d.d_year AS year,
        CASE WHEN GROUPING(r.r_reason_desc) = 0 THEN r.r_reason_desc END AS entity,
        'web_returns' AS source,
        SUM(wr.wr_net_loss) AS amount
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    WHERE r.r_reason_id IS NOT NULL
    GROUP BY GROUPING SETS (
        (d.d_year),
        (r.r_reason_desc),
        (d.d_year, r.r_reason_desc)
    )
)
SELECT *
FROM (
    SELECT year, entity, source, amount FROM sales_agg
    UNION
    SELECT year, entity, source, amount FROM returns_agg
) combined
ORDER BY year DESC NULLS LAST, amount DESC
LIMIT 100
