WITH sales_cat AS (
   SELECT
     cs.cs_bill_customer_sk AS c_customer_sk,
     d.d_year,
     d.d_month_seq,
     SUM(cs.cs_net_profit) AS profit,
     SUM(cs.cs_net_paid) AS paid,
     SUM(cs.cs_quantity) AS qty,
     COUNT(DISTINCT cs.cs_order_number) AS orders
   FROM catalog_sales cs
   JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
   GROUP BY cs.cs_bill_customer_sk, d.d_year, d.d_month_seq
),
sales_store AS (
   SELECT
     ss.ss_customer_sk AS c_customer_sk,
     d.d_year,
     d.d_month_seq,
     SUM(ss.ss_net_profit) AS profit,
     SUM(ss.ss_net_paid) AS paid,
     SUM(ss.ss_quantity) AS qty,
     COUNT(DISTINCT ss.ss_ticket_number) AS orders
   FROM store_sales ss
   JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
   GROUP BY ss.ss_customer_sk, d.d_year, d.d_month_seq
),
sales_web AS (
   SELECT
     ws.ws_bill_customer_sk AS c_customer_sk,
     d.d_year,
     d.d_month_seq,
     SUM(ws.ws_net_profit) AS profit,
     SUM(ws.ws_net_paid) AS paid,
     SUM(ws.ws_quantity) AS qty,
     COUNT(DISTINCT ws.ws_order_number) AS orders
   FROM web_sales ws
   JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
   GROUP BY ws.ws_bill_customer_sk, d.d_year, d.d_month_seq
),
all_sales AS (
   SELECT * FROM sales_cat
   UNION ALL
   SELECT * FROM sales_store
   UNION ALL
   SELECT * FROM sales_web
),
sales_total AS (
   SELECT
     c_customer_sk,
     d_year,
     d_month_seq,
     SUM(profit) AS total_profit,
     SUM(paid) AS total_paid,
     SUM(qty) AS total_qty,
     SUM(orders) AS total_orders
   FROM all_sales
   GROUP BY c_customer_sk, d_year, d_month_seq
),
returns_cat AS (
   SELECT
     cr.cr_refunded_customer_sk AS c_customer_sk,
     d.d_year,
     d.d_month_seq,
     SUM(cr.cr_net_loss) AS loss,
     SUM(cr.cr_return_quantity) AS ret_qty,
     COUNT(DISTINCT cr.cr_order_number) AS ret_orders
   FROM catalog_returns cr
   JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
   GROUP BY cr.cr_refunded_customer_sk, d.d_year, d.d_month_seq
),
returns_store AS (
   SELECT
     sr.sr_customer_sk AS c_customer_sk,
     d.d_year,
     d.d_month_seq,
     SUM(sr.sr_net_loss) AS loss,
     SUM(sr.sr_return_quantity) AS ret_qty,
     COUNT(DISTINCT sr.sr_ticket_number) AS ret_orders
   FROM store_returns sr
   JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
   GROUP BY sr.sr_customer_sk, d.d_year, d.d_month_seq
),
returns_web AS (
   SELECT
     wr.wr_refunded_customer_sk AS c_customer_sk,
     d.d_year,
     d.d_month_seq,
     SUM(wr.wr_net_loss) AS loss,
     SUM(wr.wr_return_quantity) AS ret_qty,
     COUNT(DISTINCT wr.wr_order_number) AS ret_orders
   FROM web_returns wr
   JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
   GROUP BY wr.wr_refunded_customer_sk, d.d_year, d.d_month_seq
),
all_returns AS (
   SELECT * FROM returns_cat
   UNION ALL
   SELECT * FROM returns_store
   UNION ALL
   SELECT * FROM returns_web
),
returns_total AS (
   SELECT
     c_customer_sk,
     d_year,
     d_month_seq,
     SUM(loss) AS total_loss,
     SUM(ret_qty) AS total_ret_qty,
     SUM(ret_orders) AS total_ret_orders
   FROM all_returns
   GROUP BY c_customer_sk, d_year, d_month_seq
),
sales_returns_combined AS (
   SELECT
     COALESCE(s.c_customer_sk, r.c_customer_sk) AS c_customer_sk,
     COALESCE(s.d_year, r.d_year) AS d_year,
     COALESCE(s.d_month_seq, r.d_month_seq) AS d_month_seq,
     COALESCE(s.total_profit, 0) AS total_profit,
     COALESCE(s.total_paid, 0) AS total_paid,
     COALESCE(s.total_qty, 0) AS total_qty,
     COALESCE(s.total_orders, 0) AS total_orders,
     COALESCE(r.total_loss, 0) AS total_loss,
     COALESCE(r.total_ret_qty, 0) AS total_ret_qty,
     COALESCE(r.total_ret_orders, 0) AS total_ret_orders
   FROM sales_total s
   FULL OUTER JOIN returns_total r
     ON s.c_customer_sk = r.c_customer_sk
    AND s.d_year = r.d_year
    AND s.d_month_seq = r.d_month_seq
),
full_data AS (
   SELECT
     src.c_customer_sk,
     src.d_year,
     src.d_month_seq,
     src.total_profit,
     src.total_loss,
     src.total_paid,
     src.total_qty,
     src.total_orders,
     src.total_ret_qty,
     src.total_ret_orders,
     COALESCE(src.total_profit - src.total_loss, 0) AS net_profit,
     CASE
       WHEN COALESCE(src.total_profit - src.total_loss, 0) < 0 THEN 'Loss'
       ELSE 'Profit'
     END AS profit_indicator,
     ROW_NUMBER() OVER (PARTITION BY src.d_year ORDER BY COALESCE(src.total_profit - src.total_loss, 0) DESC) AS profit_rank_year,
     c.c_first_name,
     c.c_last_name,
     c.c_email_address,
     ca.ca_city,
     ca.ca_state,
     CONCAT(TRIM(ca.ca_city), ', ', TRIM(ca.ca_state)) AS location
   FROM sales_returns_combined src
   LEFT JOIN customer c ON src.c_customer_sk = c.c_customer_sk
   LEFT JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
   WHERE src.d_year BETWEEN 1999 AND 2002
),
state_avg AS (
   SELECT
     ca_state,
     AVG(net_profit) AS avg_state_profit
   FROM full_data
   GROUP BY ca_state
)
SELECT
  fd.c_customer_sk,
  fd.c_first_name,
  fd.c_last_name,
  fd.c_email_address,
  fd.location,
  fd.d_year,
  fd.d_month_seq,
  CONCAT(CAST(fd.d_year AS VARCHAR), '-', LPAD(CAST(((fd.d_month_seq - 1) % 12 + 1) AS VARCHAR), 2, '0')) AS year_month,
  fd.total_profit,
  fd.total_loss,
  fd.net_profit,
  fd.profit_indicator,
  fd.profit_rank_year,
  (SELECT avg_state_profit FROM state_avg sa WHERE sa.ca_state = fd.ca_state) AS state_avg_profit,
  CASE
    WHEN fd.net_profit > (SELECT avg_state_profit FROM state_avg sa WHERE sa.ca_state = fd.ca_state) THEN 'Above Avg'
    ELSE 'Below Avg'
  END AS relative_performance,
  UPPER(substr(fd.c_last_name, 1, 1)) AS last_initial,
  COALESCE(fd.location, 'Unknown') AS location_filled
FROM full_data fd
ORDER BY fd.d_year, fd.profit_rank_year
LIMIT 100
