WITH catalog_data AS (
   SELECT
      cs.cs_order_number,
      d.d_year,
      i.i_brand,
      i.i_category,
      cs.cs_ext_sales_price AS sales_amount,
      cs.cs_quantity,
      cs.cs_sales_price,
      cr.cr_return_quantity,
      cr.cr_return_amount,
      cc.cc_state,
      cd.cd_gender,
      p.p_discount_active,
      sm.sm_type,
      inv.inv_quantity_on_hand,
      r.r_reason_desc
   FROM catalog_sales cs
   JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
   JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
   JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
   JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
   JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
   JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
   JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
   JOIN item i ON cs.cs_item_sk = i.i_item_sk
   JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
   LEFT JOIN catalog_returns cr ON cs.cs_order_number = cr.cr_order_number
                               AND cr.cr_item_sk = cs.cs_item_sk
   LEFT JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
                            AND inv.inv_warehouse_sk = w.w_warehouse_sk
   LEFT JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
   WHERE d.d_year = 2001
     AND i.i_brand = 'Brand#23'
     AND cd.cd_gender = 'M'
     AND cc.cc_state = 'CA'
     AND p.p_discount_active = 'Y'
     AND sm.sm_type = 'AIR'
     AND (
          cr.cr_reason_sk IS NULL
          OR EXISTS (
                SELECT 1 FROM reason r2
                WHERE r2.r_reason_sk = cr.cr_reason_sk
                  AND r2.r_reason_desc = 'Damaged Item'
          )
     )
),
web_data AS (
   SELECT
      ws.ws_order_number,
      d.d_year,
      i.i_brand,
      i.i_category,
      ws.ws_ext_sales_price AS sales_amount,
      ws.ws_quantity,
      ws.ws_sales_price,
      wr.wr_return_quantity,
      wr.wr_return_amt,
      wp.wp_type,
      ws_site.web_name,
      sm.sm_type AS ship_type,
      w.w_warehouse_name,
      p.p_discount_active
   FROM web_sales ws
   JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
   JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
   JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
   JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
   JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
   JOIN item i ON ws.ws_item_sk = i.i_item_sk
   JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
   LEFT JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
   LEFT JOIN web_site ws_site ON ws.ws_web_site_sk = ws_site.web_site_sk
   LEFT JOIN web_returns wr ON ws.ws_order_number = wr.wr_order_number
                              AND wr.wr_item_sk = ws.ws_item_sk
   WHERE d.d_year = 2001
     AND i.i_brand = 'Brand#23'
     AND cd.cd_gender = 'F'
     AND wp.wp_type = 'home'
     AND ws_site.web_name = 'SiteA'
     AND sm.sm_type = 'AIR'
),
combined AS (
   SELECT
      'catalog' AS source,
      i_brand,
      i_category,
      d_year,
      SUM(sales_amount) AS total_sales,
      COUNT(DISTINCT cs_order_number) AS order_cnt
   FROM catalog_data
   GROUP BY i_brand, i_category, d_year
   HAVING SUM(sales_amount) > 5000
   UNION ALL
   SELECT
      'web' AS source,
      i_brand,
      i_category,
      d_year,
      SUM(sales_amount) AS total_sales,
      COUNT(DISTINCT ws_order_number) AS order_cnt
   FROM web_data
   GROUP BY i_brand, i_category, d_year
   HAVING SUM(sales_amount) > 5000
)
SELECT
   source,
   i_brand,
   i_category,
   d_year,
   total_sales,
   order_cnt,
   (SELECT MAX(cs_sales_price) FROM catalog_sales) AS max_catalog_price
FROM combined
ORDER BY total_sales DESC
LIMIT 100
