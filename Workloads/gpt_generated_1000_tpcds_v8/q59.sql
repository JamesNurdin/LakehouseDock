WITH inv_agg AS (
   SELECT inv_item_sk,
          inv_warehouse_sk,
          SUM(inv_quantity_on_hand) AS total_on_hand
   FROM inventory
   WHERE inv_quantity_on_hand > 300
   GROUP BY inv_item_sk, inv_warehouse_sk
)
SELECT
   i.i_item_id,
   i.i_product_name,
   c.c_customer_id,
   c.c_birth_year,
   w.w_warehouse_name,
   s.s_store_name,
   wp.wp_url,
   SUM(cs.cs_net_profit) AS catalog_net_profit,
   SUM(ss.ss_net_profit) AS store_net_profit,
   SUM(ws.ws_net_profit) AS web_net_profit,
   (SUM(cs.cs_net_profit) + SUM(ss.ss_net_profit) + SUM(ws.ws_net_profit)) AS total_net_profit,
   RANK() OVER (ORDER BY (SUM(cs.cs_net_profit) + SUM(ss.ss_net_profit) + SUM(ws.ws_net_profit)) DESC) AS profit_rank,
   inv.total_on_hand
FROM catalog_sales cs
JOIN catalog_returns cr
  ON cr.cr_order_number = cs.cs_order_number
 AND cr.cr_item_sk = cs.cs_item_sk
JOIN store_sales ss
  ON ss.ss_item_sk = cs.cs_item_sk
 AND ss.ss_sold_date_sk = cs.cs_sold_date_sk
JOIN web_sales ws
  ON ws.ws_item_sk = cs.cs_item_sk
 AND ws.ws_sold_date_sk = cs.cs_sold_date_sk
JOIN item i
  ON i.i_item_sk = cs.cs_item_sk
JOIN time_dim t
  ON t.t_time_sk = cs.cs_sold_time_sk
JOIN customer c
  ON c.c_customer_sk = cs.cs_bill_customer_sk
JOIN customer_address ca
  ON ca.ca_address_sk = cs.cs_bill_addr_sk
JOIN household_demographics hd
  ON hd.hd_demo_sk = cs.cs_bill_hdemo_sk
JOIN promotion p
  ON p.p_promo_sk = cs.cs_promo_sk
JOIN store s
  ON s.s_store_sk = ss.ss_store_sk
JOIN warehouse w
  ON w.w_warehouse_sk = cs.cs_warehouse_sk
JOIN web_page wp
  ON wp.wp_web_page_sk = ws.ws_web_page_sk
JOIN inv_agg inv
  ON inv.inv_item_sk = i.i_item_sk
 AND inv.inv_warehouse_sk = w.w_warehouse_sk
WHERE t.t_hour BETWEEN 9 AND 17
  AND c.c_birth_year BETWEEN 1940 AND 1960
  AND p.p_discount_active = 'Y'
  AND ss.ss_sold_time_sk = t.t_time_sk
  AND ws.ws_sold_time_sk = t.t_time_sk
GROUP BY
   i.i_item_id,
   i.i_product_name,
   c.c_customer_id,
   c.c_birth_year,
   w.w_warehouse_name,
   s.s_store_name,
   wp.wp_url,
   inv.total_on_hand
ORDER BY total_net_profit DESC
LIMIT 100
