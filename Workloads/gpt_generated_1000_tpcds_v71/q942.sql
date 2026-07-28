WITH catalog_part AS (
   SELECT
     cs.cs_order_number AS order_number,
     cs.cs_sales_price AS sales_price,
     cs.cs_net_profit AS net_profit,
     c.c_customer_id AS customer_id,
     cd.cd_gender,
     ib.ib_lower_bound AS income_lower,
     p.p_promo_name AS promo_name,
     sm.sm_type AS ship_mode,
     w.w_warehouse_name AS warehouse_name,
     cp.cp_department AS department,
     cc.cc_name AS call_center,
     ROW_NUMBER() OVER (PARTITION BY p.p_promo_name ORDER BY cs.cs_sales_price DESC) AS sales_rank
   FROM catalog_sales cs
   JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
   JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
   JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
   JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
   JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
   JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
   JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
   JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
   JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
   WHERE cs.cs_sales_price > 50
     AND cs.cs_quantity >= 2
     AND cs.cs_sold_date_sk BETWEEN 2450800 AND 2451175
     AND p.p_discount_active = 'Y'
     AND ib.ib_upper_bound <= 100000
     AND NOT EXISTS (
         SELECT 1
         FROM store_sales ss
         JOIN store s ON ss.ss_store_sk = s.s_store_sk
         WHERE ss.ss_customer_sk = c.c_customer_sk
           AND ss.ss_net_profit > 1000
           AND s.s_state = 'CA'
     )
),
web_part AS (
   SELECT
     ws.ws_order_number AS order_number,
     ws.ws_sales_price AS sales_price,
     ws.ws_net_profit AS net_profit,
     c.c_customer_id AS customer_id,
     cd.cd_gender,
     ib.ib_lower_bound AS income_lower,
     p.p_promo_name AS promo_name,
     sm.sm_type AS ship_mode,
     w.w_warehouse_name AS warehouse_name,
     wp.wp_type AS web_page_type,
     wsws.web_name AS website_name,
     ROW_NUMBER() OVER (PARTITION BY p.p_promo_name ORDER BY ws.ws_sales_price DESC) AS sales_rank
   FROM web_sales ws
   JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
   JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
   JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
   JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
   JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
   JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
   JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
   JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
   JOIN web_site wsws ON ws.ws_web_site_sk = wsws.web_site_sk
   WHERE ws.ws_sales_price > 30
     AND ws.ws_quantity >= 1
     AND ws.ws_sold_date_sk BETWEEN 2450800 AND 2451175
     AND wp.wp_type = 'content'
     AND ws.ws_net_profit > 0
     AND NOT EXISTS (
         SELECT 1
         FROM store_sales ss
         JOIN store s ON ss.ss_store_sk = s.s_store_sk
         WHERE ss.ss_customer_sk = c.c_customer_sk
           AND ss.ss_net_profit > 1000
           AND s.s_state = 'CA'
     )
)
SELECT *
FROM (
   SELECT * FROM catalog_part
   UNION ALL
   SELECT * FROM web_part
) combined
WHERE sales_rank <= 10
  AND sales_price > (
      SELECT AVG(sales_price)
      FROM (
          SELECT sales_price FROM catalog_part
          UNION ALL
          SELECT sales_price FROM web_part
      ) avg_sub
  )
ORDER BY promo_name, sales_rank
LIMIT 100
