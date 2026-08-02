WITH s_filtered AS (
  SELECT
    ss.ss_ticket_number,
    ss.ss_customer_sk,
    ss.ss_item_sk,
    ss.ss_net_paid,
    i.i_category,
    CONCAT(i.i_brand, ' ', i.i_product_name) AS brand_product,
    d.d_year,
    t.t_hour
  FROM store_sales ss
  JOIN item i ON ss.ss_item_sk = i.i_item_sk
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
  WHERE d.d_year = 2002
    AND regexp_like(i.i_product_name, '^[A-Z]{3,}')
    AND i.i_color LIKE 'Red%'
    AND substring(i.i_item_desc, 1, 5) = 'Heavy'
),
sales_tickets AS (
  SELECT ss_ticket_number FROM s_filtered
),
returned_tickets AS (
  SELECT sr.sr_ticket_number
  FROM store_returns sr
  JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
  WHERE d.d_year = 2002
),
 ticket_no_return AS (
  SELECT st.ss_ticket_number
  FROM sales_tickets st
  EXCEPT
  SELECT rt.sr_ticket_number
  FROM returned_tickets rt
),
 sales_without_return AS (
  SELECT s.*
  FROM s_filtered s
  JOIN ticket_no_return tn ON s.ss_ticket_number = tn.ss_ticket_number
)
SELECT
  swr.i_category,
  swr.brand_product,
  COUNT(*) AS sales_cnt,
  SUM(swr.ss_net_paid) AS total_net_paid,
  AVG(swr.ss_net_paid) AS avg_net_paid,
  MAX(swr.t_hour) AS max_hour_sold
FROM sales_without_return swr
GROUP BY swr.i_category, swr.brand_product
ORDER BY total_net_paid DESC
LIMIT 100
