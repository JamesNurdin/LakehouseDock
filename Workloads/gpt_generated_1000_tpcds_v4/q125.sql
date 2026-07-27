WITH joined_data AS (
  SELECT
    cs.cs_order_number,
    cs.cs_sold_date_sk,
    d.d_date,
    d.d_year,
    i.i_item_id,
    i.i_category,
    i.i_brand,
    cs.cs_quantity,
    cs.cs_ext_sales_price,
    cs.cs_ext_discount_amt,
    cs.cs_net_paid,
    p.p_promo_id,
    p.p_discount_active,
    sm.sm_ship_mode_id,
    w.w_warehouse_name,
    cp.cp_catalog_number,
    ws.web_site_id,
    c_bill.c_customer_id AS bill_customer_id,
    c_ship.c_customer_id AS ship_customer_id,
    CASE WHEN cs.cs_ext_discount_amt > 100 THEN 'High' ELSE 'Low' END AS discount_level
  FROM catalog_sales cs
  INNER JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
  INNER JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
  INNER JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
  INNER JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
  INNER JOIN item i ON cs.cs_item_sk = i.i_item_sk
  INNER JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
  INNER JOIN customer c_bill ON cs.cs_bill_customer_sk = c_bill.c_customer_sk
  INNER JOIN customer c_ship ON cs.cs_ship_customer_sk = c_ship.c_customer_sk
  INNER JOIN store_sales ss ON ss.ss_sold_date_sk = d.d_date_sk
                         AND ss.ss_item_sk = i.i_item_sk
                         AND ss.ss_customer_sk = c_bill.c_customer_sk
  INNER JOIN inventory inv ON inv.inv_date_sk = d.d_date_sk
                         AND inv.inv_item_sk = i.i_item_sk
                         AND inv.inv_warehouse_sk = w.w_warehouse_sk
  INNER JOIN web_site ws ON ws.web_open_date_sk = d.d_date_sk
)
SELECT DISTINCT
  jd.cs_order_number,
  jd.d_date,
  jd.i_item_id,
  jd.i_category,
  jd.i_brand,
  jd.cs_quantity,
  jd.cs_ext_sales_price,
  jd.discount_level,
  jd.p_discount_active,
  ROW_NUMBER() OVER (PARTITION BY jd.i_category ORDER BY jd.cs_ext_sales_price DESC) AS category_sales_rank
FROM joined_data jd
WHERE jd.d_year = 2001
  AND jd.i_brand = 'Brand#45'
  AND jd.p_discount_active = 'Y'
ORDER BY jd.cs_ext_sales_price DESC
LIMIT 100
