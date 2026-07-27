SELECT
  d.d_year,
  i.i_category,
  i.i_brand,
  call_center.cc_name,
  SUM(ss.ss_net_paid) AS total_store_sales,
  SUM(cs.cs_net_paid) AS total_catalog_sales,
  SUM(ws.ws_net_paid) AS total_web_sales,
  AVG(p.p_cost) AS avg_promo_cost,
  COUNT(DISTINCT c.c_customer_sk) AS unique_customers
FROM store_sales ss
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
JOIN item i ON ss.ss_item_sk = i.i_item_sk
JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
JOIN catalog_sales cs ON ss.ss_item_sk = cs.cs_item_sk
  AND ss.ss_customer_sk = cs.cs_bill_customer_sk
  AND ss.ss_cdemo_sk = cs.cs_bill_cdemo_sk
  AND ss.ss_hdemo_sk = cs.cs_bill_hdemo_sk
  AND ss.ss_sold_date_sk = cs.cs_sold_date_sk
JOIN call_center ON cs.cs_call_center_sk = call_center.cc_call_center_sk
JOIN catalog_page ON cs.cs_catalog_page_sk = catalog_page.cp_catalog_page_sk
JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN web_sales ws ON ss.ss_item_sk = ws.ws_item_sk
  AND ss.ss_customer_sk = ws.ws_bill_customer_sk
  AND ss.ss_cdemo_sk = ws.ws_bill_cdemo_sk
  AND ss.ss_hdemo_sk = ws.ws_bill_hdemo_sk
  AND ss.ss_sold_date_sk = ws.ws_sold_date_sk
JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
WHERE
  d.d_year = 2001
  AND d.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
  AND i.i_category = 'Sports'
  AND i.i_brand = 'Brand#12'
  AND c.c_birth_country = 'United States'
  AND p.p_discount_active = 'Y'
  AND call_center.cc_state = 'CA'
  AND ss.ss_quantity > 5
  AND cs.cs_sales_price > 100
  AND EXISTS (
    SELECT 1
    FROM catalog_returns cr
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    WHERE cr.cr_order_number = cs.cs_order_number
      AND cr.cr_return_amount > 50
      AND r.r_reason_desc LIKE '%damaged%'
  )
  AND EXISTS (
    SELECT 1
    FROM store_returns sr
    JOIN reason r2 ON sr.sr_reason_sk = r2.r_reason_sk
    WHERE sr.sr_ticket_number = ss.ss_ticket_number
      AND sr.sr_return_amt > 20
      AND r2.r_reason_desc LIKE '%defective%'
  )
GROUP BY
  d.d_year,
  i.i_category,
  i.i_brand,
  call_center.cc_name
ORDER BY total_store_sales DESC
LIMIT 100
