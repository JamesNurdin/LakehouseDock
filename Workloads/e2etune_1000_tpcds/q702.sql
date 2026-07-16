WITH sales_union AS (
    SELECT cs.cs_ship_mode_sk AS ship_mode_sk,
           cs.cs_ship_cdemo_sk AS demo_sk,
           cs.cs_net_profit AS net_profit,
           cs.cs_ext_discount_amt AS discount_amt
    FROM catalog_sales cs
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    WHERE cp.cp_department = 'DEPARTMENT'
      AND cp.cp_catalog_page_number IN (1, 2, 3)
    UNION ALL
    SELECT ws.ws_ship_mode_sk AS ship_mode_sk,
           ws.ws_ship_cdemo_sk AS demo_sk,
           ws.ws_net_profit AS net_profit,
           ws.ws_ext_discount_amt AS discount_amt
    FROM web_sales ws
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE wp.wp_type = 'content'
      AND ws.ws_quantity > 0
)
SELECT sm.sm_type AS ship_mode_type,
       cd.cd_gender,
       cd.cd_marital_status,
       COUNT(*) AS sales_transactions,
       SUM(su.net_profit) AS total_net_profit,
       AVG(su.discount_amt) AS avg_discount_amount,
       RANK() OVER (ORDER BY SUM(su.net_profit) DESC) AS profit_rank
FROM sales_union su
JOIN ship_mode sm ON su.ship_mode_sk = sm.sm_ship_mode_sk
JOIN customer_demographics cd ON su.demo_sk = cd.cd_demo_sk
WHERE cd.cd_education_status = 'College'
GROUP BY sm.sm_type, cd.cd_gender, cd.cd_marital_status
HAVING SUM(su.net_profit) > 10000
ORDER BY total_net_profit DESC
LIMIT 20
