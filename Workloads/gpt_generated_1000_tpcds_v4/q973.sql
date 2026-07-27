WITH cs_agg AS (
   SELECT
       cs.cs_item_sk,
       cs.cs_sold_date_sk,
       SUM(cs.cs_net_profit) AS sum_net_profit,
       SUM(cs.cs_quantity)   AS sum_quantity
   FROM catalog_sales cs
   JOIN date_dim d_sold ON cs.cs_sold_date_sk = d_sold.d_date_sk
   JOIN ship_mode sm   ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
   JOIN item i         ON cs.cs_item_sk = i.i_item_sk
   JOIN promotion p    ON cs.cs_promo_sk = p.p_promo_sk
   WHERE d_sold.d_year = 2001
     AND i.i_category_id IN (1, 3, 4)
     AND sm.sm_type = 'AIR'
     AND p.p_discount_active = 'Y'
     AND i.i_color = 'BLUE'
     AND i.i_size = 'M'
   GROUP BY cs.cs_item_sk, cs.cs_sold_date_sk
)
SELECT
   d_sold.d_year,
   i.i_category,
   i.i_brand,
   SUM(cs_agg.sum_net_profit) AS total_net_profit,
   COUNT(DISTINCT cr.cr_order_number) AS return_orders,
   SUM(ws.ws_net_profit) AS web_total_profit
FROM cs_agg
JOIN catalog_sales cs
     ON cs.cs_item_sk = cs_agg.cs_item_sk
    AND cs.cs_sold_date_sk = cs_agg.cs_sold_date_sk
JOIN catalog_returns cr
     ON cr.cr_order_number = cs.cs_order_number
JOIN customer c
     ON cs.cs_bill_customer_sk = c.c_customer_sk
JOIN customer_address ca
     ON c.c_current_addr_sk = ca.ca_address_sk
JOIN customer_demographics cd
     ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN date_dim d_sold
     ON cs.cs_sold_date_sk = d_sold.d_date_sk
JOIN item i
     ON cs.cs_item_sk = i.i_item_sk
JOIN promotion p
     ON cs.cs_promo_sk = p.p_promo_sk
JOIN ship_mode sm
     ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN store s
     ON 1 = 1
JOIN date_dim d_store
     ON s.s_closed_date_sk = d_store.d_date_sk
JOIN time_dim t
     ON cs.cs_sold_time_sk = t.t_time_sk
JOIN web_page wp
     ON wp.wp_customer_sk = c.c_customer_sk
JOIN date_dim d_wp_creation
     ON wp.wp_creation_date_sk = d_wp_creation.d_date_sk
JOIN date_dim d_wp_access
     ON wp.wp_access_date_sk = d_wp_access.d_date_sk
JOIN web_sales ws
     ON ws.ws_item_sk = i.i_item_sk
    AND ws.ws_sold_date_sk = d_sold.d_date_sk
WHERE cd.cd_gender = 'M'
  AND ca.ca_state = 'CA'
  AND s.s_market_id = 10
  AND wp.wp_autogen_flag = 'N'
  AND t.t_hour BETWEEN 9 AND 17
  AND d_sold.d_holiday = 'N'
GROUP BY d_sold.d_year, i.i_category, i.i_brand
ORDER BY total_net_profit DESC
LIMIT 100
