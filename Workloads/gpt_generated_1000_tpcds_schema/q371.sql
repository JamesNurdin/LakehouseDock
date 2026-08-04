WITH
  sales_with_date AS (
    SELECT
      ss.ss_ticket_number,
      ss.ss_sold_date_sk,
      ss.ss_addr_sk,
      ss.ss_net_paid,
      ss.ss_net_profit,
      ss.ss_coupon_amt,
      d.d_year,
      d.d_month_seq,
      d.d_date
    FROM
      store_sales ss
      JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE
      d.d_year = 2001
      AND ss.ss_net_profit > 0
      AND ss.ss_coupon_amt < 5000
  ),
  returns_with_date AS (
    SELECT
      cr.cr_order_number,
      cr.cr_returned_date_sk,
      cr.cr_ship_mode_sk,
      cr.cr_return_amount,
      d.d_year
    FROM
      catalog_returns cr
      JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    WHERE
      cr.cr_return_amount > 100
  ),
  intersect_keys AS (
    SELECT DISTINCT ss_ticket_number
    FROM sales_with_date
    INTERSECT
    SELECT DISTINCT cr_order_number
    FROM returns_with_date
  ),
  except_keys AS (
    SELECT DISTINCT ss_ticket_number
    FROM sales_with_date
    EXCEPT
    SELECT DISTINCT cr_order_number
    FROM returns_with_date
  )
SELECT
  s.ss_ticket_number,
  s.ss_net_paid,
  s.ss_net_profit,
  d.d_date,
  ca.ca_city,
  sm.sm_code,
  ws.web_name,
  RANK() OVER (PARTITION BY d.d_year ORDER BY s.ss_net_profit DESC) AS profit_rank,
  CASE WHEN s.ss_net_profit > 1000 THEN 'High' ELSE 'Medium' END AS profit_category
FROM
  (sales_with_date s
    JOIN date_dim d ON s.ss_sold_date_sk = d.d_date_sk)
  FULL OUTER JOIN returns_with_date r ON d.d_date_sk = r.cr_returned_date_sk
  LEFT JOIN customer_address ca ON s.ss_addr_sk = ca.ca_address_sk
  LEFT JOIN ship_mode sm ON r.cr_ship_mode_sk = sm.sm_ship_mode_sk
  LEFT JOIN web_site ws ON ws.web_open_date_sk = d.d_date_sk
WHERE
  ca.ca_state = 'CA'
  AND sm.sm_code = 'AIR'
  AND d.d_month_seq BETWEEN 1 AND 12
  AND s.ss_ticket_number IN (SELECT ss_ticket_number FROM intersect_keys)
  AND s.ss_ticket_number NOT IN (SELECT ss_ticket_number FROM except_keys)
GROUP BY
  s.ss_ticket_number,
  s.ss_net_paid,
  s.ss_net_profit,
  d.d_date,
  ca.ca_city,
  sm.sm_code,
  ws.web_name,
  d.d_year
ORDER BY
  profit_rank
LIMIT 100
