WITH promo_not_used AS (
       SELECT p_promo_sk
       FROM promotion
       WHERE p_discount_active = 'Y'
       EXCEPT
       SELECT cs_promo_sk
       FROM catalog_sales
     ),
     avg_net AS (
       SELECT avg(cs_net_paid) AS avg_net_paid
       FROM catalog_sales
     )
SELECT
  ca_bill.ca_state,
  sm.sm_ship_mode_id,
  SUM(cs.cs_ext_sales_price) AS total_sales,
  SUM(cs.cs_net_profit) AS total_net_profit,
  avg_net.avg_net_paid,
  CASE
    WHEN cs.cs_promo_sk IN (SELECT p_promo_sk FROM promo_not_used) THEN 'UNUSED'
    ELSE 'USED'
  END AS promo_usage_flag,
  RANK() OVER (PARTITION BY ca_bill.ca_state ORDER BY SUM(cs.cs_net_profit) DESC) AS ship_mode_rank
FROM catalog_sales cs
JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
JOIN customer_address ca_bill ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
LEFT JOIN store_returns sr ON sr.sr_return_time_sk = td.t_time_sk
LEFT JOIN web_returns wr ON wr.wr_returned_time_sk = td.t_time_sk
LEFT JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
CROSS JOIN avg_net
WHERE cs.cs_list_price > 100
  AND sm.sm_type = 'AIR'
  AND td.t_hour BETWEEN 9 AND 17
  AND ca_bill.ca_state IN ('CA', 'TX', 'NY')
  AND p.p_discount_active = 'Y'
  AND cs.cs_promo_sk IN (
        SELECT p_promo_sk
        FROM promotion
        WHERE p.p_promo_name LIKE '%Clearance%'
      )
  AND EXISTS (
        SELECT 1
        FROM promotion pa
        WHERE pa.p_promo_sk = cs.cs_promo_sk
          AND pa.p_discount_active = 'Y'
      )
GROUP BY
  ca_bill.ca_state,
  sm.sm_ship_mode_id,
  avg_net.avg_net_paid,
  cs.cs_promo_sk
ORDER BY
  ca_bill.ca_state,
  ship_mode_rank
LIMIT 100
