WITH sales_filtered AS (
    SELECT
        cs_sold_date_sk,
        cs_catalog_page_sk,
        cs_quantity,
        cs_sales_price,
        cs_net_paid,
        cs_net_profit,
        cs_ship_cdemo_sk
    FROM catalog_sales
    WHERE cs_quantity BETWEEN 40 AND 60
      AND cs_sales_price > 20.00
      AND cs_ship_cdemo_sk IN (410407, 349259, 1728779)
      AND cs_net_paid IS NOT NULL
      AND cs_net_profit > 0
      AND cs_sold_date_sk >= 2450000
)
SELECT
    cp.cp_department,
    cp.cp_type,
    COUNT(*) AS orders_cnt,
    SUM(s.cs_quantity) AS total_quantity,
    AVG(s.cs_sales_price) AS avg_sales_price,
    SUM(s.cs_net_paid) AS total_net_paid,
    MAX(s.cs_net_profit) AS max_net_profit,
    ROW_NUMBER() OVER (PARTITION BY cp.cp_department ORDER BY SUM(s.cs_net_paid) DESC) AS dept_rank
FROM sales_filtered s
JOIN catalog_page cp
    ON s.cs_catalog_page_sk = cp.cp_catalog_page_sk
WHERE cp.cp_type IN ('monthly', 'quarterly')
  AND cp.cp_end_date_sk BETWEEN 2451100 AND 2451200
  AND EXISTS (
        SELECT 1
        FROM catalog_page cp2
        WHERE cp2.cp_catalog_page_id = cp.cp_catalog_page_id
          AND cp2.cp_department = 'Electronics'
    )
GROUP BY cp.cp_department, cp.cp_type
HAVING COUNT(*) > 10
ORDER BY total_net_paid DESC
LIMIT 20
