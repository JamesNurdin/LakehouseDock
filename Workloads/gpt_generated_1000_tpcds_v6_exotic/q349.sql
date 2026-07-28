WITH raw AS (
   SELECT
       i.i_category,
       s.s_state,
       cs.cs_net_paid,
       ws.ws_net_paid,
       cr.cr_return_amt_inc_tax,
       sr.sr_return_amt_inc_tax,
       i.i_item_sk
   FROM catalog_sales cs
   JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
   JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
   JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
   JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
   JOIN item i ON cs.cs_item_sk = i.i_item_sk
   JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
   JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
   LEFT JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
        AND cr.cr_item_sk = cs.cs_item_sk
   LEFT JOIN store_returns sr ON sr.sr_item_sk = i.i_item_sk
        AND sr.sr_customer_sk = c.c_customer_sk
   LEFT JOIN store s ON sr.sr_store_sk = s.s_store_sk
   LEFT JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
        AND ws.ws_bill_customer_sk = c.c_customer_sk
   LEFT JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
   WHERE c.c_birth_day IN (27, 23, 18, 7)
     AND hd.hd_vehicle_count >= 0
     AND i.i_current_price BETWEEN 10 AND 500
     AND p.p_discount_active = 'Y'
     AND s.s_state IN ('CA', 'TX', 'NY')
     AND td.t_hour BETWEEN 8 AND 20
),
agg1 AS (
   SELECT
       i_category,
       s_state,
       SUM(cs_net_paid + ws_net_paid) AS total_sales,
       SUM(COALESCE(cr_return_amt_inc_tax, 0) + COALESCE(sr_return_amt_inc_tax, 0)) AS total_returns,
       SUM((cs_net_paid + ws_net_paid) - (COALESCE(cr_return_amt_inc_tax, 0) + COALESCE(sr_return_amt_inc_tax, 0))) AS net_profit
   FROM raw
   GROUP BY GROUPING SETS ((i_category, s_state), (i_category), (s_state), ())
)
SELECT
   i_category,
   s_state,
   total_sales,
   total_returns,
   net_profit,
   AVG(total_sales) OVER (PARTITION BY i_category) AS avg_sales_by_category,
   (SELECT COUNT(DISTINCT p2.p_promo_id)
      FROM promotion p2
      JOIN item i2 ON p2.p_item_sk = i2.i_item_sk
     WHERE i2.i_category = agg1.i_category
       AND p2.p_discount_active = 'Y') AS active_promo_cnt
FROM agg1
WHERE total_sales > 10000
ORDER BY total_sales DESC
LIMIT 100
