WITH
  preferred_customers AS (
    SELECT c_customer_sk, c_customer_id
    FROM tpcds.customer
    WHERE c_preferred_cust_flag = 'Y'
      AND c_last_review_date NOT IN (
        SELECT c_last_review_date
        FROM tpcds.customer
        WHERE c_preferred_cust_flag = 'N'
        LIMIT 5
      )
  ),
  sampled_items AS (
    SELECT i_item_sk, i_brand, i_brand_id
    FROM tpcds.item TABLESAMPLE BERNOULLI (10)
    WHERE i_brand_id IN (10008011, 3002001)
  ),
  sales_with_brand AS (
    SELECT
      ws.ws_order_number,
      ws.ws_ext_sales_price,
      i.i_brand,
      c.c_customer_id
    FROM tpcds.web_sales ws
    JOIN sampled_items i
      ON ws.ws_item_sk = i.i_item_sk
    JOIN preferred_customers c
      ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE ws.ws_ext_sales_price > 100
  ),
  full_join_sales AS (
    SELECT
      COALESCE(ws.ws_order_number, 0) AS ws_order_number,
      ws.ws_ext_sales_price,
      i.i_brand,
      c.c_customer_id
    FROM tpcds.web_sales ws
    FULL OUTER JOIN sampled_items i
      ON ws.ws_item_sk = i.i_item_sk
    LEFT JOIN preferred_customers c
      ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE ws.ws_ext_sales_price > 50 OR i.i_brand IS NOT NULL
  )
SELECT
  order_number,
  ext_sales_price,
  brand,
  customer_id
FROM (
  SELECT
    ws_order_number AS order_number,
    ws_ext_sales_price AS ext_sales_price,
    i_brand AS brand,
    c_customer_id AS customer_id
  FROM sales_with_brand

  UNION

  SELECT
    ws_order_number AS order_number,
    ws_ext_sales_price AS ext_sales_price,
    i_brand AS brand,
    c_customer_id AS customer_id
  FROM full_join_sales
  WHERE ws_order_number NOT IN (SELECT ws_order_number FROM sales_with_brand)
) AS unioned
ORDER BY ext_sales_price DESC
LIMIT 100
