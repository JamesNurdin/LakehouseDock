WITH filtered_sales AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_ship_mode_sk,
        cs.cs_catalog_page_sk,
        cs.cs_ship_customer_sk,
        cs.cs_net_paid_inc_tax,
        cs.cs_quantity,
        cs.cs_order_number
    FROM catalog_sales cs
    WHERE cs.cs_net_paid_inc_tax > 200
      AND cs.cs_ship_mode_sk IN (3, 6)
)
SELECT
    sm.sm_code AS ship_mode_code,
    cp.cp_catalog_page_number,
    COALESCE(c.c_customer_id, 'UNKNOWN') AS ship_customer_id,
    COUNT(DISTINCT fs.cs_order_number) AS orders_cnt,
    SUM(fs.cs_net_paid_inc_tax) AS total_net_paid_inc_tax,
    AVG(fs.cs_quantity) AS avg_quantity,
    MIN(fs.cs_net_paid_inc_tax) AS min_net_paid,
    MAX(fs.cs_net_paid_inc_tax) AS max_net_paid
FROM filtered_sales fs
JOIN catalog_page cp
    ON fs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN ship_mode sm
    ON fs.cs_ship_mode_sk = sm.sm_ship_mode_sk
LEFT JOIN customer c
    ON fs.cs_ship_customer_sk = c.c_customer_sk
WHERE sm.sm_code = 'AIR'
  AND sm.sm_contract = 'HVDFCcQ'
  AND cp.cp_catalog_page_number BETWEEN 5 AND 15
GROUP BY sm.sm_code, cp.cp_catalog_page_number, COALESCE(c.c_customer_id, 'UNKNOWN')
ORDER BY total_net_paid_inc_tax DESC
LIMIT 100
