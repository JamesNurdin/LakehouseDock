WITH
sales AS (
   SELECT
       d.d_year,
       s.s_store_name,
       i.i_category,
       SUM(cs.cs_net_profit) AS net_profit,
       COUNT(DISTINCT cs.cs_order_number) AS orders
   FROM catalog_sales cs
   JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
   JOIN store s ON s.s_closed_date_sk = d.d_date_sk
   JOIN item i ON cs.cs_item_sk = i.i_item_sk
   JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
   JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
   JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
   JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
   JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
   JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
   JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
   WHERE d.d_year BETWEEN 2001 AND 2002
     AND cc.cc_state = 'CA'
     AND s.s_state = 'CA'
     AND i.i_color = 'Red'
     AND p.p_discount_active = 'Y'
     AND sm.sm_type = 'AIR'
     AND cd.cd_gender = 'M'
     AND ca.ca_city = 'Seattle'
     AND EXISTS (
         SELECT 1 FROM web_returns wr
         WHERE wr.wr_item_sk = cs.cs_item_sk
           AND wr.wr_returned_date_sk = d.d_date_sk
     )
   GROUP BY ROLLUP (d.d_year, s.s_store_name, i.i_category)
),
returns AS (
   SELECT
       d.d_year,
       s.s_store_name,
       i.i_category,
       SUM(cr.cr_net_loss) AS net_loss,
       COUNT(DISTINCT cr.cr_order_number) AS return_orders
   FROM catalog_returns cr
   JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
   JOIN store s ON s.s_closed_date_sk = d.d_date_sk
   JOIN item i ON cr.cr_item_sk = i.i_item_sk
   JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
   JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
   JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
   JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
   JOIN web_site ws ON ws.web_open_date_sk = d.d_date_sk
   WHERE d.d_year = 2001
     AND cc.cc_country = 'United States'
     AND s.s_city = 'Los Angeles'
     AND i.i_size = 'MEDIUM'
     AND sm.sm_carrier = 'Carrier1'
     AND r.r_reason_desc = 'Customer Damaged'
     AND ws.web_country = 'United States'
   GROUP BY ROLLUP (d.d_year, s.s_store_name, i.i_category)
),
inventory_sample AS (
   SELECT inv.inv_item_sk, inv.inv_quantity_on_hand
   FROM inventory inv TABLESAMPLE BERNOULLI (10)
   JOIN date_dim d ON inv.inv_date_sk = d.d_date_sk
   WHERE d.d_year = 2001
),
combined AS (
   SELECT d_year, s_store_name, i_category, net_profit AS metric, orders AS cnt
   FROM sales
   UNION DISTINCT
   SELECT d_year, s_store_name, i_category, -net_loss AS metric, return_orders AS cnt
   FROM returns
),
final_set AS (
   SELECT *
   FROM combined
   EXCEPT
   SELECT d_year, s_store_name, i_category, metric, cnt
   FROM combined
   WHERE metric = 0
)
SELECT
   d_year,
   s_store_name,
   i_category,
   SUM(metric) AS total_metric,
   SUM(cnt) AS total_cnt
FROM final_set
GROUP BY ROLLUP (d_year, s_store_name, i_category)
ORDER BY d_year NULLS LAST, s_store_name, i_category
