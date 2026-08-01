WITH
  sales_brief AS (
    SELECT
      cs.cs_bill_customer_sk AS customer_sk,
      c.c_first_name,
      c.c_last_name,
      i.i_product_name,
      cs.cs_quantity AS quantity,
      cs.cs_net_paid AS net_paid,
      ROW_NUMBER() OVER (PARTITION BY cs.cs_bill_customer_sk ORDER BY cs.cs_net_paid DESC) AS rn_sales,
      (
        SELECT COUNT(*)
        FROM store_returns sr
        WHERE sr.sr_customer_sk = cs.cs_bill_customer_sk
          AND EXISTS (
            SELECT 1
            FROM date_dim dr
            WHERE dr.d_date_sk = sr.sr_returned_date_sk
              AND dr.d_year = 2001
          )
      ) AS return_cnt_2001,
      NULL AS rn_returns
    FROM catalog_sales cs
    JOIN date_dim d_sold ON cs.cs_sold_date_sk = d_sold.d_date_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN inventory inv ON inv.inv_item_sk = cs.cs_item_sk
                     AND inv.inv_warehouse_sk = cs.cs_warehouse_sk
    JOIN date_dim d_inv ON inv.inv_date_sk = d_inv.d_date_sk
    WHERE d_sold.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
      AND i.i_brand = 'Brand#45'
      AND w.w_city = 'COSTA RICA'
      AND p.p_discount_active = 'Y'
      AND hd.hd_income_band_sk BETWEEN 5 AND 10
      AND cp.cp_type = 'LEAF'
      AND inv.inv_quantity_on_hand > 500
  ),
  returns_brief AS (
    SELECT
      sr.sr_customer_sk AS customer_sk,
      c.c_first_name,
      c.c_last_name,
      i.i_product_name,
      sr.sr_return_quantity AS quantity,
      sr.sr_return_amt AS net_paid,
      NULL AS rn_sales,
      ROW_NUMBER() OVER (PARTITION BY sr.sr_customer_sk ORDER BY sr.sr_return_amt DESC) AS rn_returns,
      NULL AS return_cnt_2001
    FROM store_returns sr
    JOIN date_dim dr ON sr.sr_returned_date_sk = dr.d_date_sk
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    WHERE dr.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
      AND hd.hd_income_band_sk BETWEEN 5 AND 10
  ),
  combined_brief AS (
    SELECT * FROM sales_brief
    UNION DISTINCT
    SELECT * FROM returns_brief
  ),
  web_data AS (
    SELECT
      wp.wp_web_page_sk,
      wp.wp_web_page_id,
      wp.wp_url,
      ws.web_name,
      ws.web_city,
      wp.wp_type,
      wp.wp_char_count,
      c.c_customer_sk
    FROM web_page wp
    JOIN customer c ON wp.wp_customer_sk = c.c_customer_sk
    FULL OUTER JOIN web_site ws ON wp.wp_web_page_sk = ws.web_site_sk
    WHERE wp.wp_type = 'CONTENT' OR ws.web_state = 'CA'
  ),
  pages_all AS (
    SELECT cp_catalog_page_sk FROM catalog_page
  ),
  pages_active AS (
    SELECT cp.cp_catalog_page_sk
    FROM catalog_page cp
    JOIN date_dim d_start ON cp.cp_start_date_sk = d_start.d_date_sk
    JOIN date_dim d_end   ON cp.cp_end_date_sk   = d_end.d_date_sk
    WHERE d_start.d_date <= DATE '2001-12-31'
      AND d_end.d_date   >= DATE '2001-01-01'
  ),
  pages_to_exclude AS (
    SELECT cp_catalog_page_sk FROM pages_all
    EXCEPT
    SELECT cp_catalog_page_sk FROM pages_active
  ),
  common_items AS (
    SELECT i.i_item_sk
    FROM sales_brief sb
    JOIN item i ON sb.i_product_name = i.i_product_name
    INTERSECT
    SELECT i2.i_item_sk
    FROM returns_brief rb
    JOIN item i2 ON rb.i_product_name = i2.i_product_name
  )
SELECT
  cb.customer_sk,
  cb.c_first_name,
  cb.c_last_name,
  cb.i_product_name,
  cb.quantity,
  cb.net_paid,
  cb.rn_sales,
  cb.rn_returns,
  cb.return_cnt_2001,
  wd.wp_web_page_id,
  wd.web_name,
  (SELECT cp_catalog_page_sk FROM pages_to_exclude LIMIT 1) AS excluded_page_sk
FROM combined_brief cb
LEFT JOIN web_data wd ON cb.customer_sk = wd.c_customer_sk
WHERE cb.rn_sales = 1 OR cb.rn_returns = 1
ORDER BY cb.net_paid DESC NULLS LAST
LIMIT 100
