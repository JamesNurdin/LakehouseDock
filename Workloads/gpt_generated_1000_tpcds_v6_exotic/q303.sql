WITH sales_agg AS (
    SELECT
        cs_ship_mode_sk,
        cs_ship_cdemo_sk,
        SUM(cs_ext_sales_price) AS total_ext_sales,
        SUM(cs_quantity) AS total_qty,
        AVG(cs_sales_price) AS avg_sales_price,
        COUNT(DISTINCT cs_order_number) AS order_cnt
    FROM catalog_sales
    WHERE cs_sales_price > 30
      AND cs_quantity >= 2
      AND cs_ship_mode_sk IN (4, 12, 20)
    GROUP BY cs_ship_mode_sk, cs_ship_cdemo_sk
)
SELECT
    sm.sm_type,
    sm.sm_code,
    sm.sm_carrier,
    sales_agg.cs_ship_cdemo_sk,
    SUM(sales_agg.total_ext_sales) AS total_ext_sales,
    SUM(sales_agg.total_qty) AS total_qty,
    AVG(sales_agg.avg_sales_price) AS avg_sales_price,
    SUM(sales_agg.order_cnt) AS total_orders
FROM sales_agg
JOIN ship_mode sm
    ON sales_agg.cs_ship_mode_sk = sm.sm_ship_mode_sk
WHERE sm.sm_code = 'AIR'
  AND sm.sm_carrier = 'FEDEX'
GROUP BY GROUPING SETS (
    (sm.sm_type, sm.sm_code, sm.sm_carrier, sales_agg.cs_ship_cdemo_sk),
    (sm.sm_type, sm.sm_code, sm.sm_carrier),
    (sm.sm_type, sm.sm_code),
    (sm.sm_type),
    ()
)
ORDER BY total_ext_sales DESC
LIMIT 100
