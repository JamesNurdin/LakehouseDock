WITH
  refunded_agg AS (
    SELECT
      wr_refunded_customer_sk,
      SUM(wr_return_amt) AS total_return_amt,
      COUNT(DISTINCT wr_order_number) AS distinct_orders
    FROM web_returns
    GROUP BY wr_refunded_customer_sk
  ),
  returning_agg AS (
    SELECT
      wr_returning_customer_sk,
      SUM(wr_return_tax) AS total_return_tax,
      COUNT(DISTINCT wr_reason_sk) AS distinct_reasons
    FROM web_returns
    GROUP BY wr_returning_customer_sk
  ),
  base AS (
    SELECT
      c.c_customer_sk,
      c.c_first_name,
      c.c_last_name,
      ca.ca_city,
      ca.ca_state,
      d.d_year,
      t.t_hour,
      wp.wp_url,
      ra.total_return_amt,
      ra.distinct_orders,
      rga.total_return_tax,
      rga.distinct_reasons,
      CASE WHEN ra.total_return_amt > 1000 THEN 'High' ELSE 'Low' END AS return_amount_category,
      ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY ra.total_return_amt DESC) AS rn
    FROM refunded_agg ra
    JOIN customer c
      ON ra.wr_refunded_customer_sk = c.c_customer_sk
    JOIN customer_address ca
      ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN web_returns wr
      ON wr.wr_refunded_customer_sk = c.c_customer_sk
    JOIN date_dim d
      ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN time_dim t
      ON wr.wr_returned_time_sk = t.t_time_sk
    JOIN web_page wp
      ON wr.wr_web_page_sk = wp.wp_web_page_sk
    JOIN returning_agg rga
      ON rga.wr_returning_customer_sk = c.c_customer_sk
    WHERE d.d_year = 2001
      AND t.t_hour BETWEEN 8 AND 18
      AND ca.ca_state = 'TX'
      AND wp.wp_type = 'content'
      AND c.c_preferred_cust_flag = 'Y'
  )
SELECT *
FROM (
  SELECT c_customer_sk
  FROM base
  WHERE rn = 1
) AS sub1
INTERSECT
SELECT *
FROM (
  SELECT c_customer_sk
  FROM base
  WHERE return_amount_category = 'High'
) AS sub2
ORDER BY c_customer_sk
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY
