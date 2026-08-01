WITH
  sales_returns AS (
    SELECT
      cs.cs_order_number,
      cs.cs_item_sk,
      cs.cs_sold_date_sk,
      cs.cs_sold_time_sk,
      cs.cs_quantity,
      cs.cs_net_paid,
      cr.cr_return_quantity,
      cr.cr_return_amount,
      cr.cr_reason_sk,
      cr.cr_warehouse_sk,
      cs.cs_warehouse_sk AS cs_warehouse_sk,
      c.c_customer_sk,
      d.d_year,
      t.t_hour,
      w.w_warehouse_name,
      r.r_reason_desc
    FROM catalog_sales cs
    JOIN catalog_returns cr
      ON cs.cs_order_number = cr.cr_order_number
     AND cs.cs_item_sk = cr.cr_item_sk
    JOIN customer c
      ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN date_dim d
      ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN time_dim t
      ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN warehouse w
      ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN reason r
      ON cr.cr_reason_sk = r.r_reason_sk
  ),
  web_returns_cte AS (
    SELECT
      wr.wr_order_number,
      wr.wr_return_quantity,
      wr.wr_return_amt,
      wr.wr_reason_sk,
      wp.wp_web_page_id,
      c.c_customer_sk,
      d_wr.d_year,
      t_wr.t_hour,
      r.r_reason_desc,
      d_cre.d_year AS creation_year,
      d_acc.d_year AS access_year
    FROM web_returns wr
    JOIN web_page wp
      ON wr.wr_web_page_sk = wp.wp_web_page_sk
    JOIN customer c
      ON wr.wr_refunded_customer_sk = c.c_customer_sk
    JOIN date_dim d_wr
      ON wr.wr_returned_date_sk = d_wr.d_date_sk
    JOIN time_dim t_wr
      ON wr.wr_returned_time_sk = t_wr.t_time_sk
    JOIN reason r
      ON wr.wr_reason_sk = r.r_reason_sk
    JOIN date_dim d_cre
      ON wp.wp_creation_date_sk = d_cre.d_date_sk
    JOIN date_dim d_acc
      ON wp.wp_access_date_sk = d_acc.d_date_sk
  ),
  unioned AS (
    SELECT
      COALESCE(sr.c_customer_sk, wrc.c_customer_sk)               AS c_customer_sk,
      COALESCE(sr.d_year, wrc.d_year)                           AS year,
      (COALESCE(sr.cs_net_paid, 0) - COALESCE(sr.cr_return_amount, 0) - COALESCE(wrc.wr_return_amt, 0)) AS net_amount,
      CASE
        WHEN COALESCE(sr.cr_return_amount, 0) > 0 OR COALESCE(wrc.wr_return_amt, 0) > 0 THEN 'Return'
        ELSE 'Sale'
      END                                                       AS txn_type
    FROM sales_returns sr
    FULL OUTER JOIN web_returns_cte wrc
      ON sr.c_customer_sk = wrc.c_customer_sk
    WHERE COALESCE(sr.d_year, wrc.d_year) = 2001

    UNION

    SELECT
      COALESCE(sr.c_customer_sk, wrc.c_customer_sk)               AS c_customer_sk,
      COALESCE(sr.d_year, wrc.d_year)                           AS year,
      (COALESCE(sr.cs_net_paid, 0) - COALESCE(sr.cr_return_amount, 0) - COALESCE(wrc.wr_return_amt, 0)) AS net_amount,
      CASE
        WHEN COALESCE(sr.cr_return_amount, 0) > 0 OR COALESCE(wrc.wr_return_amt, 0) > 0 THEN 'Return'
        ELSE 'Sale'
      END                                                       AS txn_type
    FROM sales_returns sr
    INNER JOIN web_returns_cte wrc
      ON sr.c_customer_sk = wrc.c_customer_sk
    WHERE COALESCE(sr.d_year, wrc.d_year) = 2002
  )
SELECT
  u.c_customer_sk,
  u.year,
  SUM(u.net_amount)                                            AS total_net_amount,
  CASE WHEN SUM(u.net_amount) > 1000 THEN 'High' ELSE 'Low' END AS net_category,
  (SELECT COUNT(*)
     FROM catalog_sales cs_sub
    WHERE cs_sub.cs_bill_customer_sk = u.c_customer_sk)       AS total_sales_transactions
FROM unioned u
GROUP BY GROUPING SETS (
  (u.c_customer_sk, u.year),
  (u.c_customer_sk),
  (u.year)
)
ORDER BY total_net_amount DESC
OFFSET 10
LIMIT 100
