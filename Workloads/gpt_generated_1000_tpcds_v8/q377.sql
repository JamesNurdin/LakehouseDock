WITH
  base_sales AS (
    SELECT
      s.s_store_name,
      i.i_product_name,
      cd.cd_gender,
      s.s_state,
      ss.ss_store_sk,
      ss.ss_item_sk,
      SUM(ss.ss_ext_sales_price) AS total_sales,
      ROW_NUMBER() OVER (PARTITION BY s.s_state ORDER BY SUM(ss.ss_ext_sales_price) DESC) AS rn_state
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
    JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    WHERE i.i_wholesale_cost > 10
      AND i.i_current_price BETWEEN 20 AND 200
      AND i.i_rec_start_date >= DATE '1999-01-01'
      AND s.s_state = 'CA'
      AND s.s_gmt_offset >= -5
      AND cd.cd_gender = 'F'
      AND ss.ss_quantity > 1
    GROUP BY s.s_store_name, i.i_product_name, cd.cd_gender, s.s_state, ss.ss_store_sk, ss.ss_item_sk
  ),
  items_not_in_web AS (
    SELECT ss.ss_item_sk AS item_sk
    FROM store_sales ss
    EXCEPT
    SELECT ws.ws_item_sk
    FROM web_sales ws
  ),
  common_customers AS (
    SELECT ss.ss_customer_sk AS customer_sk
    FROM store_sales ss
    INTERSECT
    SELECT ws.ws_bill_customer_sk
    FROM web_sales ws
  )
SELECT
  bs.s_store_name,
  bs.i_product_name,
  bs.cd_gender,
  bs.total_sales,
  RANK() OVER (PARTITION BY bs.s_state ORDER BY bs.total_sales DESC) AS state_sales_rank,
  NULL AS item_not_in_web,
  NULL AS common_customer
FROM base_sales bs
WHERE bs.rn_state <= 10

UNION ALL

SELECT
  NULL,
  NULL,
  NULL,
  NULL,
  NULL,
  inf.item_sk,
  NULL
FROM items_not_in_web inf

UNION ALL

SELECT
  NULL,
  NULL,
  NULL,
  NULL,
  NULL,
  NULL,
  com.customer_sk
FROM common_customers com

ORDER BY total_sales DESC NULLS LAST
OFFSET 0
LIMIT 100
