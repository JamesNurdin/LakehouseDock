WITH sales_base AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_sold_time_sk,
        cs.cs_ship_date_sk,
        cs.cs_bill_customer_sk,
        cs.cs_bill_hdemo_sk,
        cs.cs_call_center_sk,
        cs.cs_catalog_page_sk,
        cs.cs_warehouse_sk,
        cs.cs_item_sk,
        cs.cs_quantity,
        cs.cs_net_paid_inc_ship_tax,
        cs.cs_order_number
    FROM tpcds.catalog_sales AS cs
)
SELECT
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    i.i_category,
    cp.cp_department,
    w.w_warehouse_name,
    SUM(cs_base.cs_net_paid_inc_ship_tax) AS total_sales,
    COUNT(DISTINCT cs_base.cs_order_number) AS order_count,
    SUM(CASE WHEN cs_base.cs_quantity > 50 THEN cs_base.cs_net_paid_inc_ship_tax ELSE 0 END) AS high_qty_sales,
    CASE WHEN c.c_birth_year < 1950 THEN 'Senior' ELSE 'Adult' END AS age_group
FROM sales_base AS cs_base
JOIN tpcds.time_dim AS td
      ON cs_base.cs_sold_time_sk = td.t_time_sk
JOIN tpcds.customer AS c
      ON cs_base.cs_bill_customer_sk = c.c_customer_sk
JOIN tpcds.household_demographics AS hd
      ON cs_base.cs_bill_hdemo_sk = hd.hd_demo_sk
JOIN tpcds.call_center AS cc
      ON cs_base.cs_call_center_sk = cc.cc_call_center_sk
JOIN tpcds.catalog_page AS cp
      ON cs_base.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN tpcds.warehouse AS w
      ON cs_base.cs_warehouse_sk = w.w_warehouse_sk
JOIN tpcds.item AS i
      ON cs_base.cs_item_sk = i.i_item_sk
JOIN tpcds.inventory AS inv1
      ON inv1.inv_item_sk = i.i_item_sk
     AND inv1.inv_warehouse_sk = w.w_warehouse_sk
JOIN tpcds.inventory AS inv2
      ON inv2.inv_item_sk = i.i_item_sk
     AND inv2.inv_warehouse_sk = w.w_warehouse_sk
JOIN tpcds.web_page AS wp
      ON wp.wp_customer_sk = c.c_customer_sk
WHERE cc.cc_rec_start_date >= DATE '2020-01-01'
  AND NOT EXISTS (
        SELECT 1
        FROM tpcds.web_page AS wp_sub
        WHERE wp_sub.wp_customer_sk = c.c_customer_sk
          AND wp_sub.wp_type = 'advertisement'
      )
GROUP BY
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    i.i_category,
    cp.cp_department,
    w.w_warehouse_name,
    c.c_birth_year
ORDER BY total_sales DESC
LIMIT 100
