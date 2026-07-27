WITH
  returns_morning AS (
    SELECT
      CAST('return' AS varchar) AS record_type,
      t.t_hour AS hour,
      SUM(r.cr_return_amount) AS total_amount,
      COUNT(*) AS cnt
    FROM catalog_returns r
    JOIN catalog_sales s
      ON r.cr_order_number = s.cs_order_number
     AND r.cr_item_sk = s.cs_item_sk
    JOIN time_dim t
      ON r.cr_returned_time_sk = t.t_time_sk
    JOIN customer_address a
      ON r.cr_refunded_addr_sk = a.ca_address_sk
    WHERE t.t_hour BETWEEN 8 AND 12
      AND a.ca_state = 'CA'
    GROUP BY t.t_hour
  ),
  sales_morning AS (
    SELECT
      CAST('sale' AS varchar) AS record_type,
      t.t_hour AS hour,
      SUM(s.cs_sales_price) AS total_amount,
      COUNT(*) AS cnt
    FROM catalog_sales s
    JOIN time_dim t
      ON s.cs_sold_time_sk = t.t_time_sk
    JOIN customer_address a
      ON s.cs_bill_addr_sk = a.ca_address_sk
    WHERE t.t_hour BETWEEN 8 AND 12
      AND a.ca_state = 'CA'
    GROUP BY t.t_hour
  )
SELECT record_type, hour, total_amount, cnt
FROM returns_morning
UNION ALL
SELECT record_type, hour, total_amount, cnt
FROM sales_morning
ORDER BY hour, record_type
LIMIT 100
