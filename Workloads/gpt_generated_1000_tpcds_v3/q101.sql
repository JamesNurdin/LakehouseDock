WITH filtered_sales AS (
    SELECT
        cs.cs_ship_mode_sk,
        cs.cs_sold_date_sk,
        cs.cs_quantity,
        cs.cs_ext_tax,
        cs.cs_net_paid_inc_tax,
        cs.cs_bill_cdemo_sk
    FROM tpcds.catalog_sales cs
    WHERE cs.cs_ext_tax > 50.00
      AND cs.cs_net_paid_inc_tax >= 1000.00
      AND cs.cs_quantity BETWEEN 1 AND 5
      AND cs.cs_bill_cdemo_sk IN (23666, 90299, 1235795)
      AND cs.cs_sold_date_sk BETWEEN 2450000 AND 2453650
)
SELECT
    sm.sm_ship_mode_id,
    sm.sm_code,
    sm.sm_carrier,
    COUNT(*) AS order_count,
    SUM(cs.cs_net_paid_inc_tax) AS total_net_paid_inc_tax,
    AVG(cs.cs_ext_tax) AS avg_ext_tax,
    MIN(cs.cs_sold_date_sk) AS min_sold_date_sk,
    MAX(cs.cs_sold_date_sk) AS max_sold_date_sk
FROM filtered_sales cs
JOIN tpcds.ship_mode sm
    ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
WHERE sm.sm_contract IN ('Ek', 'YvxVaJI10')
  AND sm.sm_code = 'AIR'
GROUP BY sm.sm_ship_mode_id, sm.sm_code, sm.sm_carrier
HAVING SUM(cs.cs_net_paid_inc_tax) > 50000
   AND COUNT(*) > 10
ORDER BY total_net_paid_inc_tax DESC
LIMIT 100
