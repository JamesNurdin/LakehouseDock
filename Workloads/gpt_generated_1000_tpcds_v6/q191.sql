WITH filtered AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_ext_ship_cost,
        cs.cs_ext_wholesale_cost,
        cs.cs_net_paid,
        cs.cs_warehouse_sk,
        inv.inv_date_sk,
        wh.w_city,
        wh.w_warehouse_name,
        wh.w_warehouse_sq_ft,
        wh.w_county
    FROM catalog_sales cs
    JOIN warehouse wh
        ON cs.cs_warehouse_sk = wh.w_warehouse_sk
    JOIN inventory inv
        ON inv.inv_warehouse_sk = wh.w_warehouse_sk
    WHERE cs.cs_ext_ship_cost > 1000
      AND cs.cs_ext_wholesale_cost BETWEEN 400 AND 2000
      AND wh.w_warehouse_sq_ft > 500000
      AND wh.w_county IN ('Franklin Parish', 'Walker County')
      AND inv.inv_date_sk = 2451067
)
SELECT
    w_city,
    cs_sold_date_sk,
    SUM(cs_net_paid) AS total_net_paid,
    AVG(cs_ext_ship_cost) AS avg_ship_cost,
    COUNT(*) AS sales_cnt,
    MIN(cs_ext_wholesale_cost) AS min_wholesale,
    MAX(cs_ext_wholesale_cost) AS max_wholesale
FROM filtered
GROUP BY ROLLUP (w_city, cs_sold_date_sk)
ORDER BY w_city, cs_sold_date_sk
LIMIT 100
