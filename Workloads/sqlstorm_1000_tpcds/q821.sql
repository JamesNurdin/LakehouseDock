WITH unified_sales AS (
 SELECT
   d.d_year AS year,
   w.w_state AS state,
   cd.cd_gender AS gender,
   cd.cd_marital_status AS marital_status,
   i.i_category AS category,
   cs.cs_net_profit AS net_profit,
   cs.cs_quantity AS quantity
 FROM catalog_sales cs
 JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
 JOIN item i ON cs.cs_item_sk = i.i_item_sk
 JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
 JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
 JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
 WHERE d.d_year = 2000
   AND p.p_discount_active = 'Y'
 UNION ALL
 SELECT
   d.d_year,
   w.w_state,
   cd.cd_gender,
   cd.cd_marital_status,
   i.i_category,
   ws.ws_net_profit,
   ws.ws_quantity
 FROM web_sales ws
 JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
 JOIN item i ON ws.ws_item_sk = i.i_item_sk
 JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
 JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
 JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
 WHERE d.d_year = 2000
   AND p.p_discount_active = 'Y'
 UNION ALL
 SELECT
   d.d_year,
   s.s_state,
   cd.cd_gender,
   cd.cd_marital_status,
   i.i_category,
   ss.ss_net_profit,
   ss.ss_quantity
 FROM store_sales ss
 JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
 JOIN item i ON ss.ss_item_sk = i.i_item_sk
 JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
 JOIN store s ON ss.ss_store_sk = s.s_store_sk
 JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
 WHERE d.d_year = 2000
   AND p.p_discount_active = 'Y'
)
SELECT
  state,
  gender,
  marital_status,
  category,
  SUM(net_profit) AS total_net_profit,
  SUM(quantity) AS total_quantity,
  COUNT(*) AS sales_transactions
FROM unified_sales
WHERE state IS NOT NULL
GROUP BY state, gender, marital_status, category
ORDER BY total_net_profit DESC
LIMIT 100
