WITH
  sales_filtered AS (
    SELECT
      ss.ss_sold_date_sk,
      ss.ss_ticket_number,
      ss.ss_quantity,
      ss.ss_sales_price,
      ss.ss_net_paid_inc_tax,
      ss.ss_wholesale_cost,
      d.d_year,
      d.d_month_seq,
      d.d_day_name,
      d.d_date_sk
    FROM store_sales ss
    JOIN date_dim d
      ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND d.d_day_name = 'Monday'
      AND d.d_current_week = 'N'
      AND ss.ss_net_paid_inc_tax > 1000
      AND ss.ss_wholesale_cost < 50
      AND ss.ss_sales_price > 0
  ),
  returns_filtered AS (
    SELECT
      wr.wr_returned_date_sk,
      wr.wr_order_number,
      wr.wr_net_loss,
      wr.wr_account_credit,
      d.d_year AS ret_year,
      d.d_date_sk
    FROM web_returns wr
    JOIN date_dim d
      ON wr.wr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND wr.wr_net_loss > 500
      AND wr.wr_account_credit < 100
  ),
  ticket_not_returned AS (
    SELECT ss_ticket_number
    FROM sales_filtered
    EXCEPT
    SELECT wr_order_number
    FROM returns_filtered
  ),
  common_dates AS (
    SELECT d_date_sk FROM date_dim WHERE d_day_name = 'Monday'
    INTERSECT
    SELECT d_date_sk FROM date_dim WHERE d_month_seq = 4
  ),
  joined_data AS (
    SELECT
      sf.d_year,
      sf.d_month_seq,
      sf.d_day_name,
      sf.ss_ticket_number,
      sf.ss_quantity,
      sf.ss_sales_price,
      sf.ss_net_paid_inc_tax,
      rf.wr_net_loss,
      rf.wr_account_credit,
      sf.ss_sold_date_sk
    FROM sales_filtered sf
    JOIN returns_filtered rf
      ON sf.ss_sold_date_sk = rf.wr_returned_date_sk
    WHERE sf.ss_sold_date_sk IN (SELECT d_date_sk FROM common_dates)
      AND sf.ss_ticket_number IN (SELECT ss_ticket_number FROM ticket_not_returned)
  )
SELECT
  jd.d_year,
  jd.d_month_seq,
  jd.d_day_name,
  SUM(jd.ss_net_paid_inc_tax) AS total_sales_inc_tax,
  SUM(jd.wr_net_loss) AS total_return_loss,
  COUNT(DISTINCT jd.ss_ticket_number) AS distinct_sales_txns,
  AVG(jd.ss_sales_price) AS avg_sales_price,
  MIN(jd.ss_sales_price) AS min_sales_price,
  MAX(jd.ss_sales_price) AS max_sales_price,
  ROW_NUMBER() OVER (ORDER BY SUM(jd.ss_net_paid_inc_tax) DESC) AS rn
FROM joined_data jd
CROSS JOIN LATERAL (
  SELECT jd.ss_quantity * jd.ss_sales_price AS line_revenue
) lr
GROUP BY jd.d_year, jd.d_month_seq, jd.d_day_name
ORDER BY total_sales_inc_tax DESC
LIMIT 100
