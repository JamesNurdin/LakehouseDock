WITH
  sr_agg AS (
    SELECT
      sr.sr_customer_sk AS customer_sk,
      SUM(sr.sr_return_amt) AS total_return_amt,
      COUNT(*) AS return_cnt,
      MAX(sr.sr_returned_date_sk) AS max_return_date_sk
    FROM store_returns sr
    WHERE sr.sr_returned_date_sk > 2450000
    GROUP BY sr.sr_customer_sk
  ),
  ws_agg AS (
    SELECT
      ws.ws_bill_customer_sk AS customer_sk,
      ws.ws_warehouse_sk AS warehouse_sk,
      SUM(ws.ws_net_paid_inc_ship) AS total_net_paid,
      COUNT(*) AS sales_cnt,
      MAX(ws.ws_sold_date_sk) AS max_sold_date_sk
    FROM web_sales ws
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    WHERE ws.ws_sold_date_sk BETWEEN 2450000 AND 2451500
    GROUP BY ws.ws_bill_customer_sk, ws.ws_warehouse_sk
  ),
  full_join AS (
    SELECT
      COALESCE(ws.customer_sk, sr.customer_sk) AS customer_sk,
      ws.warehouse_sk,
      ws.total_net_paid,
      ws.sales_cnt,
      sr.total_return_amt,
      sr.return_cnt
    FROM ws_agg ws
    FULL OUTER JOIN sr_agg sr
      ON ws.customer_sk = sr.customer_sk
  ),
  wp_agg AS (
    SELECT
      wp.wp_customer_sk AS customer_sk,
      COUNT(*) AS page_cnt,
      AVG(wp.wp_link_count) AS avg_link_count
    FROM web_page wp
    WHERE wp.wp_rec_start_date >= DATE '1999-09-03'
      AND wp.wp_link_count > 10
    GROUP BY wp.wp_customer_sk
  ),
  set_a AS (
    SELECT
      c.c_email_address,
      c.c_birth_month,
      fj.customer_sk,
      w.w_warehouse_name,
      fj.sales_cnt,
      fj.total_net_paid,
      fj.return_cnt,
      fj.total_return_amt,
      (fj.total_net_paid - COALESCE(fj.total_return_amt, 0)) AS net_gain,
      (fj.total_net_paid - COALESCE(fj.total_return_amt, 0)) / NULLIF(fj.total_net_paid, 0) AS net_gain_ratio,
      wpag.page_cnt,
      wpag.avg_link_count,
      SUM((fj.total_net_paid - COALESCE(fj.total_return_amt, 0))) OVER (
        PARTITION BY c.c_birth_month
        ORDER BY c.c_email_address
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
      ) AS running_net_gain_by_month
    FROM full_join fj
    LEFT JOIN customer c ON c.c_customer_sk = fj.customer_sk
    LEFT JOIN warehouse w ON w.w_warehouse_sk = fj.warehouse_sk
    LEFT JOIN wp_agg wpag ON wpag.customer_sk = c.c_customer_sk
    WHERE c.c_preferred_cust_flag = 'Y'
      AND c.c_birth_day BETWEEN 5 AND 20
      AND c.c_birth_year >= 1950
      AND (fj.total_net_paid - COALESCE(fj.total_return_amt, 0)) / NULLIF(fj.total_net_paid, 0) > 0.05
  ),
  set_b AS (
    SELECT
      c.c_email_address,
      c.c_birth_month,
      fj.customer_sk,
      w.w_warehouse_name,
      fj.sales_cnt,
      fj.total_net_paid,
      fj.return_cnt,
      fj.total_return_amt,
      (fj.total_net_paid - COALESCE(fj.total_return_amt, 0)) AS net_gain,
      (fj.total_net_paid - COALESCE(fj.total_return_amt, 0)) / NULLIF(fj.total_net_paid, 0) AS net_gain_ratio,
      wpag.page_cnt,
      wpag.avg_link_count,
      SUM((fj.total_net_paid - COALESCE(fj.total_return_amt, 0))) OVER (
        PARTITION BY c.c_birth_month
        ORDER BY c.c_email_address
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
      ) AS running_net_gain_by_month
    FROM full_join fj
    LEFT JOIN customer c ON c.c_customer_sk = fj.customer_sk
    LEFT JOIN warehouse w ON w.w_warehouse_sk = fj.warehouse_sk
    LEFT JOIN wp_agg wpag ON wpag.customer_sk = c.c_customer_sk
    WHERE c.c_preferred_cust_flag = 'N'
      AND c.c_birth_day BETWEEN 1 AND 31
      AND c.c_birth_year < 1960
      AND (fj.total_net_paid - COALESCE(fj.total_return_amt, 0)) / NULLIF(fj.total_net_paid, 0) > 0.05
  ),
  union_set AS (
    SELECT * FROM set_a
    UNION
    SELECT * FROM set_b
  ),
  exclude_set AS (
    SELECT *
    FROM union_set
    WHERE c_email_address LIKE '%example.com%'
  )
SELECT *
FROM union_set
EXCEPT
SELECT *
FROM exclude_set
ORDER BY net_gain_ratio DESC
OFFSET 10 ROWS FETCH NEXT 20 ROWS ONLY
