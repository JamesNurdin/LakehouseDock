WITH joined_all AS (
   SELECT
       cs.cs_item_sk,
       i.i_item_id,
       i.i_category,
       i.i_brand,
       cs.cs_net_paid,
       cs.cs_net_profit,
       cs.cs_order_number,
       ws.ws_net_paid,
       ws.ws_order_number,
       sr.sr_net_loss,
       wr.wr_net_loss,
       d.d_year,
       d.d_date,
       w.w_city,
       p.p_discount_active,
       sm.sm_type,
       ca.ca_county
   FROM catalog_sales cs
   JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
   JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
   JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
   JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
   JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
   JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
   JOIN (SELECT * FROM warehouse TABLESAMPLE BERNOULLI (10)) w ON cs.cs_warehouse_sk = w.w_warehouse_sk
   JOIN item i ON cs.cs_item_sk = i.i_item_sk
   JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
   LEFT JOIN store_returns sr ON sr.sr_item_sk = i.i_item_sk AND sr.sr_returned_date_sk = d.d_date_sk
   LEFT JOIN store s ON sr.sr_store_sk = s.s_store_sk
   LEFT JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
   LEFT JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk AND ws.ws_sold_date_sk = d.d_date_sk
   LEFT JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
   LEFT JOIN web_returns wr ON wr.wr_item_sk = i.i_item_sk
        AND wr.wr_returned_date_sk = d.d_date_sk
        AND wr.wr_order_number = ws.ws_order_number
   WHERE d.d_year = 2001
     AND ca.ca_county = 'Maricopa County'
     AND w.w_city = 'New York'
     AND p.p_discount_active = 'Y'
     AND sm.sm_type = 'AIR'
     AND i.i_category = 'Sports'
),

aggregated AS (
   SELECT
       cs_item_sk AS i_item_sk,
       i_item_id,
       i_category,
       i_brand,
       SUM(cs_net_paid) AS total_catalog_sales,
       SUM(cs_net_profit) AS total_catalog_profit,
       SUM(COALESCE(ws_net_paid, 0)) AS total_web_sales,
       SUM(COALESCE(sr_net_loss, 0)) AS total_store_returns_loss,
       SUM(COALESCE(wr_net_loss, 0)) AS total_web_returns_loss,
       COUNT(DISTINCT cs_order_number) AS catalog_orders,
       COUNT(DISTINCT ws_order_number) AS web_orders,
       d_year
   FROM joined_all
   GROUP BY cs_item_sk, i_item_id, i_category, i_brand, d_year
),

intersect_items AS (
   SELECT i_item_sk FROM aggregated WHERE total_catalog_sales > 5000
   INTERSECT
   SELECT i_item_sk FROM aggregated WHERE total_web_sales > 2000
)

SELECT
   a.i_item_id,
   a.i_category,
   a.i_brand,
   a.total_catalog_sales,
   a.total_web_sales,
   a.total_store_returns_loss,
   a.total_web_returns_loss,
   a.catalog_orders,
   a.web_orders,
   RANK() OVER (PARTITION BY a.i_category ORDER BY a.total_catalog_sales DESC) AS sales_rank,
   SUM(a.total_catalog_sales) OVER (PARTITION BY a.i_category ORDER BY a.total_catalog_sales DESC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_sales_by_category
FROM aggregated a
WHERE a.i_item_sk IN (SELECT i_item_sk FROM intersect_items)
ORDER BY cumulative_sales_by_category DESC, sales_rank
LIMIT 100
