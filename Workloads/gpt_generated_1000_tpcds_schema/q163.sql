WITH
  sales_data AS (
    SELECT
      cc.cc_call_center_sk,
      cc.cc_name,
      cp.cp_catalog_page_sk,
      cp.cp_department,
      c.c_customer_sk,
      c.c_first_name,
      c.c_last_name,
      ca.ca_address_sk,
      ca.ca_city,
      i.i_item_sk,
      i.i_brand,
      i.i_category,
      cs.cs_order_number,
      cs.cs_quantity,
      cs.cs_ext_sales_price,
      cs.cs_net_profit
    FROM catalog_sales cs
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    WHERE cc.cc_employees > 2000000
      AND i.i_brand = 'BrandA'
      AND cs.cs_quantity > 5
      AND ca.ca_gmt_offset = -5.00
      AND hd.hd_vehicle_count >= 1
      AND cp.cp_department = 'Electronics'
  ),

  agg_sales AS (
    SELECT
      c_customer_sk,
      SUM(cs_ext_sales_price) AS total_sales,
      SUM(cs_net_profit) AS total_profit,
      COUNT(DISTINCT cs_order_number) AS orders_count
    FROM sales_data
    GROUP BY c_customer_sk
  ),

  returns_data AS (
    SELECT
      cs.cs_bill_customer_sk AS c_customer_sk,
      SUM(cr.cr_return_quantity) AS total_ret_qty,
      SUM(cr.cr_return_amount) AS total_ret_amount
    FROM catalog_returns cr
    JOIN catalog_sales cs ON cr.cr_order_number = cs.cs_order_number
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    WHERE cr.cr_return_quantity > 0
      AND cr.cr_return_amount > 0
      AND i.i_category = 'Furniture'
      AND hd.hd_vehicle_count >= 0
      AND cr.cr_fee < 500
      AND cr.cr_reversed_charge < 200
    GROUP BY cs.cs_bill_customer_sk
  ),

  agg_returns AS (
    SELECT
      c_customer_sk,
      total_ret_qty,
      total_ret_amount
    FROM returns_data
  ),

  union_agg AS (
    SELECT
      c_customer_sk,
      total_sales,
      total_profit,
      orders_count,
      CAST(NULL AS BIGINT) AS total_ret_qty,
      CAST(NULL AS DOUBLE) AS total_ret_amount
    FROM agg_sales
    UNION DISTINCT
    SELECT
      c_customer_sk,
      CAST(NULL AS DOUBLE) AS total_sales,
      CAST(NULL AS DOUBLE) AS total_profit,
      CAST(NULL AS BIGINT) AS orders_count,
      total_ret_qty,
      total_ret_amount
    FROM agg_returns
  ),

  web_data AS (
    SELECT
      wp.wp_web_page_sk,
      wp.wp_url,
      wp.wp_char_count,
      c.c_customer_sk,
      c.c_first_name,
      c.c_last_name,
      ca.ca_city,
      cd.cd_gender
    FROM web_page wp
    JOIN customer c ON wp.wp_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE wp.wp_type = 'content'
      AND wp.wp_char_count > 1000
      AND ca.ca_state = 'CA'
      AND cd.cd_gender = 'M'
      AND wp.wp_image_count >= 5
      AND wp.wp_link_count > 10
  ),

  full_joined AS (
    SELECT
      COALESCE(u.c_customer_sk, w.c_customer_sk) AS customer_sk,
      u.total_sales,
      u.total_profit,
      u.orders_count,
      u.total_ret_qty,
      u.total_ret_amount,
      w.wp_url,
      w.wp_char_count
    FROM union_agg u
    FULL OUTER JOIN web_data w ON u.c_customer_sk = w.c_customer_sk
  )
SELECT
  SUM(COALESCE(total_sales, 0)) AS sum_sales,
  AVG(COALESCE(total_profit, 0)) AS avg_profit,
  SUM(COALESCE(total_ret_amount, 0)) AS sum_return_amount,
  COUNT(DISTINCT customer_sk) AS distinct_customers
FROM full_joined
WHERE (total_sales > 1000 OR total_ret_amount > 100)
LIMIT 100
