WITH RECURSIVE date_keys(dk) AS (
    SELECT 2450837
    UNION ALL
    SELECT dk + 1 FROM date_keys WHERE dk < 2450840
)
SELECT
    state,
    city,
    price_category,
    total_net_paid,
    order_cnt
FROM (
    SELECT
        w.w_state AS state,
        w.w_city AS city,
        'LowPrice' AS price_category,
        SUM(cs.cs_net_paid) AS total_net_paid,
        COUNT(*) AS order_cnt
    FROM catalog_sales cs
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN date_keys dk ON cs.cs_ship_date_sk = dk.dk
    WHERE cs.cs_ext_list_price <= 2000
      AND cs.cs_ship_cdemo_sk IN (189998, 90299)
    GROUP BY GROUPING SETS ((w.w_state, w.w_city), (w.w_state), ())
    
    UNION ALL
    
    SELECT
        w.w_state AS state,
        w.w_city AS city,
        'HighPrice' AS price_category,
        SUM(cs.cs_net_paid) AS total_net_paid,
        COUNT(*) AS order_cnt
    FROM catalog_sales cs
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN date_keys dk ON cs.cs_ship_date_sk = dk.dk
    WHERE cs.cs_ext_list_price > 4000
      AND EXISTS (
          SELECT 1
          FROM catalog_sales cs2
          WHERE cs2.cs_warehouse_sk = cs.cs_warehouse_sk
            AND cs2.cs_ext_list_price > 5000
      )
    GROUP BY GROUPING SETS ((w.w_state, w.w_city), (w.w_state), ())
) AS combined
ORDER BY state, city, price_category
