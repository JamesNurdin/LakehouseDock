WITH filtered_time AS (
    SELECT
        t_time_sk,
        t_hour,
        t_minute,
        t_second
    FROM time_dim
    WHERE t_second IN (4, 15, 16)
      AND t_minute BETWEEN 13 AND 19
)
SELECT *
FROM (
    SELECT
        cs.cs_sold_date_sk AS date_sk,
        ft.t_hour AS hour,
        SUM(cs.cs_ext_sales_price) AS metric,
        COUNT(*) AS cnt,
        'sale' AS source,
        (
            SELECT AVG(cs2.cs_ext_sales_price)
            FROM catalog_sales cs2
            WHERE cs2.cs_sold_date_sk = cs.cs_sold_date_sk
        ) AS overall_avg
    FROM catalog_sales cs
    JOIN filtered_time ft
        ON cs.cs_sold_time_sk = ft.t_time_sk
    WHERE cs.cs_ship_date_sk BETWEEN 2450830 AND 2450906
      AND cs.cs_ext_ship_cost > 500
    GROUP BY cs.cs_sold_date_sk, ft.t_hour

    UNION ALL

    SELECT
        sr.sr_returned_date_sk AS date_sk,
        ft.t_hour AS hour,
        SUM(sr.sr_return_amt) AS metric,
        COUNT(*) AS cnt,
        'return' AS source,
        (
            SELECT AVG(sr2.sr_return_amt)
            FROM store_returns sr2
            WHERE sr2.sr_returned_date_sk = sr.sr_returned_date_sk
        ) AS overall_avg
    FROM store_returns sr
    JOIN filtered_time ft
        ON sr.sr_return_time_sk = ft.t_time_sk
    WHERE sr.sr_fee > 30
      AND sr.sr_return_quantity >= 20
    GROUP BY sr.sr_returned_date_sk, ft.t_hour
) combined
ORDER BY date_sk DESC, hour, source
LIMIT 100
