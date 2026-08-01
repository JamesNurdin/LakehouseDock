WITH
  sales_base AS (
    SELECT
      cs_sold_date_sk,
      cs_ext_sales_price,
      cs_coupon_amt,
      cs_quantity,
      cs_ext_discount_amt,
      cs_order_number,
      cs_bill_hdemo_sk,
      cs_bill_addr_sk
    FROM catalog_sales
    WHERE cs_quantity > 1
      AND cs_ext_sales_price > 500
      AND cs_coupon_amt < 1000
  ),
  high_discount AS (
    SELECT cs_order_number
    FROM catalog_sales
    WHERE cs_ext_discount_amt > 800
  ),
  low_discount AS (
    SELECT cs_order_number
    FROM catalog_sales
    WHERE cs_ext_discount_amt < 200
  ),
  excluded_orders AS (
    SELECT cs_order_number FROM high_discount
    EXCEPT
    SELECT cs_order_number FROM low_discount
  ),
  filtered_sales AS (
    SELECT *
    FROM sales_base
    WHERE cs_sold_date_sk IN (
            SELECT d_date_sk
            FROM date_dim
            WHERE d_year = 2002
              AND d_month_seq BETWEEN 121 AND 124
          )
      AND cs_bill_hdemo_sk IN (
            SELECT hd_demo_sk
            FROM household_demographics
            WHERE hd_income_band_sk BETWEEN 3 AND 5
          )
      AND cs_bill_addr_sk IN (
            SELECT ca_address_sk
            FROM customer_address
            WHERE ca_state = 'CA'
              AND ca_street_type = 'Drive'
          )
  )
SELECT
  d.d_year,
  d.d_month_seq,
  s.s_store_name,
  SUM(fs.cs_ext_sales_price)                         AS total_sales,
  AVG(fs.cs_ext_sales_price)                         AS avg_sales,
  COUNT(DISTINCT fs.cs_order_number)                 AS orders,
  MIN(fs.cs_coupon_amt)                              AS min_coupon,
  MAX(fs.cs_coupon_amt)                              AS max_coupon,
  CASE WHEN SUM(fs.cs_ext_sales_price) > 100000 THEN 'High' ELSE 'Low' END AS sales_category
FROM filtered_sales fs
RIGHT JOIN date_dim d ON fs.cs_sold_date_sk = d.d_date_sk
LEFT  JOIN store s ON s.s_closed_date_sk = d.d_date_sk
LEFT  JOIN customer_address ca ON fs.cs_bill_addr_sk = ca.ca_address_sk
LEFT  JOIN household_demographics hd ON fs.cs_bill_hdemo_sk = hd.hd_demo_sk
WHERE d.d_year = 2002
GROUP BY d.d_year, d.d_month_seq, s.s_store_name

UNION

SELECT
  d.d_year,
  d.d_month_seq,
  s.s_store_name,
  SUM(fs2.cs_ext_sales_price)                        AS total_sales,
  AVG(fs2.cs_ext_sales_price)                        AS avg_sales,
  COUNT(DISTINCT fs2.cs_order_number)                AS orders,
  MIN(fs2.cs_coupon_amt)                             AS min_coupon,
  MAX(fs2.cs_coupon_amt)                             AS max_coupon,
  CASE WHEN SUM(fs2.cs_ext_sales_price) > 50000 THEN 'Medium' ELSE 'Low' END AS sales_category
FROM filtered_sales fs2
RIGHT JOIN date_dim d ON fs2.cs_sold_date_sk = d.d_date_sk
LEFT  JOIN store s ON s.s_closed_date_sk = d.d_date_sk
WHERE fs2.cs_order_number IN (SELECT cs_order_number FROM excluded_orders)
  AND d.d_year = 2002
GROUP BY d.d_year, d.d_month_seq, s.s_store_name

ORDER BY total_sales DESC
LIMIT 100
