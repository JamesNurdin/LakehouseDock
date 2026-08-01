WITH sampled_sales AS (
   SELECT *
   FROM catalog_sales TABLESAMPLE BERNOULLI (10)
),
item_sub AS (
   SELECT i_item_sk
   FROM item
   WHERE i_wholesale_cost < 5
),
return_sub AS (
   SELECT cr_item_sk
   FROM catalog_returns
   WHERE cr_return_quantity > 0
),
common_items AS (
   SELECT i_sk
   FROM (SELECT i_item_sk AS i_sk FROM item_sub)
   INTERSECT
   SELECT cr_item_sk FROM return_sub
),
joined_data AS (
   SELECT
      d_sold.d_year,
      c.c_customer_id,
      i.i_item_id,
      i.i_product_name,
      ws.cs_net_paid,
      ws.cs_net_profit,
      sm.sm_type,
      w.w_warehouse_name,
      cr.cr_return_amount,
      RANK() OVER (PARTITION BY d_sold.d_year ORDER BY ws.cs_net_paid DESC) AS sales_rank
   FROM sampled_sales ws
   JOIN date_dim d_sold ON ws.cs_sold_date_sk = d_sold.d_date_sk
   JOIN date_dim d_ship ON ws.cs_ship_date_sk = d_ship.d_date_sk
   LEFT JOIN catalog_returns cr
        ON cr.cr_order_number = ws.cs_order_number
       AND cr.cr_item_sk = ws.cs_item_sk
   JOIN customer c ON ws.cs_bill_customer_sk = c.c_customer_sk
   JOIN customer_demographics cd ON ws.cs_bill_cdemo_sk = cd.cd_demo_sk
   JOIN household_demographics hd ON ws.cs_bill_hdemo_sk = hd.hd_demo_sk
   JOIN customer_address ca ON ws.cs_bill_addr_sk = ca.ca_address_sk
   JOIN item i ON ws.cs_item_sk = i.i_item_sk
   JOIN ship_mode sm ON ws.cs_ship_mode_sk = sm.sm_ship_mode_sk
   JOIN warehouse w ON ws.cs_warehouse_sk = w.w_warehouse_sk
   JOIN web_page wp ON wp.wp_customer_sk = c.c_customer_sk
   JOIN date_dim d_wp_creation ON wp.wp_creation_date_sk = d_wp_creation.d_date_sk
   JOIN date_dim d_wp_access ON wp.wp_access_date_sk = d_wp_access.d_date_sk
   JOIN web_site wsit ON wsit.web_open_date_sk = d_sold.d_date_sk
   WHERE d_sold.d_year = 2001
     AND ws.cs_ext_sales_price > 1000
     AND i.i_item_sk IN (SELECT i_sk FROM common_items)
)
SELECT
   d_year,
   c_customer_id,
   i_item_id,
   i_product_name,
   cs_net_paid,
   cs_net_profit,
   sm_type,
   w_warehouse_name,
   cr_return_amount,
   sales_rank
FROM joined_data
ORDER BY d_year DESC, sales_rank
OFFSET 20 ROWS FETCH NEXT 10 ROWS ONLY
