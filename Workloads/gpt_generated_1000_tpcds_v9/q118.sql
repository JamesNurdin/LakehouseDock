WITH sales_base AS (
  SELECT
    d.d_date_sk,
    d.d_year,
    d.d_week_seq,
    ws.web_name,
    ws.web_gmt_offset,
    ss.ss_ext_sales_price,
    ss.ss_ext_discount_amt,
    ss.ss_customer_sk,
    c.c_salutation,
    i.inv_quantity_on_hand
  FROM tpcds.store_sales ss
  JOIN tpcds.date_dim d
    ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN tpcds.customer c
    ON ss.ss_customer_sk = c.c_customer_sk
  JOIN tpcds.inventory i
    ON i.inv_date_sk = d.d_date_sk
  JOIN tpcds.web_site ws
    ON ws.web_open_date_sk = d.d_date_sk
  WHERE d.d_week_seq IN (1, 11)
    AND d.d_following_holiday = 'N'
    AND c.c_salutation = 'Mr.'
    AND ss.ss_ext_discount_amt > 100
    AND i.inv_quantity_on_hand > 0
    AND ws.web_gmt_offset BETWEEN -5 AND 5
)
SELECT
  d_date_sk,
  d_year,
  d_week_seq,
  web_name,
  SUM(ss_ext_sales_price) AS total_sales,
  AVG(ss_ext_discount_amt) AS avg_discount,
  COUNT(DISTINCT ss_customer_sk) AS distinct_customers,
  CASE
    WHEN SUM(ss_ext_discount_amt) > 5000 THEN 'High Discount'
    ELSE 'Low Discount'
  END AS discount_category,
  (
    SELECT MAX(i2.inv_quantity_on_hand)
    FROM tpcds.inventory i2
    WHERE i2.inv_date_sk = d_date_sk
  ) AS max_qty_on_hand_for_date
FROM sales_base
GROUP BY
  d_date_sk,
  d_year,
  d_week_seq,
  web_name
HAVING SUM(ss_ext_sales_price) > 10000
ORDER BY total_sales DESC
LIMIT 100
