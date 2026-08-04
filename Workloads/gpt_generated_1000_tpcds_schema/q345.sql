WITH
  store_path AS (
    SELECT
      cd.cd_demo_sk,
      s.s_state,
      s.s_store_id,
      ss.ss_net_paid AS sales_amount,
      c.c_customer_sk,
      ss.ss_item_sk
    FROM store_sales ss
    RIGHT JOIN store s
      ON ss.ss_store_sk = s.s_store_sk
    JOIN customer c
      ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd
      ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN customer_demographics cd_cur
      ON c.c_current_cdemo_sk = cd_cur.cd_demo_sk
    JOIN store s2
      ON ss.ss_store_sk = s2.s_store_sk
  ),
  web_path AS (
    SELECT
      cd_bill.cd_demo_sk,
      wp.wp_type,
      ws.ws_net_paid AS sales_amount,
      cust_bill.c_customer_sk AS bill_cust_sk,
      cust_ship.c_customer_sk AS ship_cust_sk,
      ws.ws_item_sk,
      wp.wp_web_page_id
    FROM web_sales ws
    JOIN web_page wp
      ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN customer cust_bill
      ON ws.ws_bill_customer_sk = cust_bill.c_customer_sk
    JOIN customer_demographics cd_bill
      ON ws.ws_bill_cdemo_sk = cd_bill.cd_demo_sk
    JOIN customer cust_ship
      ON ws.ws_ship_customer_sk = cust_ship.c_customer_sk
    JOIN customer_demographics cd_ship
      ON ws.ws_ship_cdemo_sk = cd_ship.cd_demo_sk
    JOIN customer wp_cust
      ON wp.wp_customer_sk = wp_cust.c_customer_sk
    JOIN customer_demographics cd_wp_cur
      ON wp_cust.c_current_cdemo_sk = cd_wp_cur.cd_demo_sk
  ),
  store_demo_keys AS (
    SELECT DISTINCT cd_demo_sk FROM store_path
  ),
  web_demo_keys AS (
    SELECT DISTINCT cd_demo_sk FROM web_path
  ),
  common_demo_keys AS (
    SELECT cd_demo_sk FROM store_demo_keys
    INTERSECT
    SELECT cd_demo_sk FROM web_demo_keys
  ),
  union_sales AS (
    SELECT cd_demo_sk,
           SUM(sales_amount) AS total_sales,
           COUNT(DISTINCT c_customer_sk) AS distinct_customers,
           COUNT(DISTINCT ss_item_sk) AS distinct_items
    FROM store_path
    WHERE cd_demo_sk IN (SELECT cd_demo_sk FROM common_demo_keys)
    GROUP BY cd_demo_sk
    UNION
    SELECT cd_demo_sk,
           SUM(sales_amount) AS total_sales,
           COUNT(DISTINCT bill_cust_sk) AS distinct_customers,
           COUNT(DISTINCT ws_item_sk) AS distinct_items
    FROM web_path
    WHERE cd_demo_sk IN (SELECT cd_demo_sk FROM common_demo_keys)
    GROUP BY cd_demo_sk
  ),
  final_agg AS (
    SELECT
      cd_demo_sk,
      SUM(total_sales) AS combined_sales,
      SUM(DISTINCT total_sales) AS distinct_sales_sum,
      COUNT(DISTINCT distinct_customers) AS distinct_customers_total,
      COUNT(DISTINCT distinct_items) AS distinct_items_total,
      ROW_NUMBER() OVER (PARTITION BY cd_demo_sk ORDER BY SUM(total_sales) DESC) AS rnk
    FROM union_sales
    GROUP BY cd_demo_sk
  )
SELECT
  cd_demo_sk,
  combined_sales,
  distinct_sales_sum,
  distinct_customers_total,
  distinct_items_total
FROM final_agg
WHERE rnk <= 3
ORDER BY combined_sales DESC
OFFSET 0 FETCH NEXT 10 ROWS ONLY
