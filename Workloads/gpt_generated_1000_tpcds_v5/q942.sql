WITH sales_filtered AS (
    SELECT
        cs.cs_order_number,
        cs.cs_call_center_sk,
        cs.cs_catalog_page_sk,
        cs.cs_net_paid,
        cs.cs_quantity,
        cs.cs_ext_wholesale_cost
    FROM catalog_sales cs
    WHERE cs.cs_ext_wholesale_cost > 500
      AND cs.cs_ext_wholesale_cost < 4000
      AND cs.cs_quantity BETWEEN 1 AND 10
      AND cs.cs_net_paid > 0
)
SELECT
    cc.cc_name,
    cp.cp_department,
    SUM(sf.cs_net_paid) AS total_net_paid,
    SUM(cr.cr_net_loss) AS total_net_loss,
    COUNT(DISTINCT sf.cs_order_number) AS orders_cnt,
    ROW_NUMBER() OVER (PARTITION BY cc.cc_market_manager ORDER BY SUM(sf.cs_net_paid) DESC) AS market_rownum
FROM sales_filtered sf
JOIN call_center cc
    ON sf.cs_call_center_sk = cc.cc_call_center_sk
JOIN catalog_page cp
    ON sf.cs_catalog_page_sk = cp.cp_catalog_page_sk
LEFT JOIN catalog_returns cr
    ON cr.cr_order_number = sf.cs_order_number
WHERE EXISTS (
    SELECT 1
    FROM catalog_returns cr2
    WHERE cr2.cr_order_number = sf.cs_order_number
      AND cr2.cr_reason_sk IN (4, 9, 19)
      AND cr2.cr_net_loss > 100
)
  AND cc.cc_state = 'CA'
  AND cp.cp_type = 'Electronic'
  AND cc.cc_market_manager LIKE '%Manager%'
GROUP BY cc.cc_name, cp.cp_department, cc.cc_market_manager
ORDER BY total_net_paid DESC
LIMIT 100
