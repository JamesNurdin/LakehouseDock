WITH
  sales_daily AS (
    SELECT
      ss.ss_sold_date_sk AS date_sk,
      SUM(ss.ss_ext_sales_price) AS total_sales,
      SUM(ss.ss_net_profit) AS total_profit,
      COUNT(DISTINCT ss.ss_ticket_number) AS distinct_tickets,
      CASE
        WHEN SUM(ss.ss_ext_sales_price) > 10000 THEN 'HIGH'
        ELSE 'LOW'
      END AS sales_level
    FROM store_sales ss
    WHERE ss.ss_wholesale_cost > 20
    GROUP BY ss.ss_sold_date_sk
  ),
  returns_daily AS (
    SELECT
      wr.wr_returned_date_sk AS date_sk,
      SUM(wr.wr_return_amt) AS total_returns,
      SUM(wr.wr_net_loss) AS total_loss,
      COUNT(DISTINCT wr.wr_order_number) AS distinct_orders
    FROM web_returns wr
    WHERE wr.wr_returned_time_sk > 50000
    GROUP BY wr.wr_returned_date_sk
  ),
  date_filtered AS (
    SELECT
      d.d_date_sk,
      d.d_date,
      d.d_day_name,
      d.d_quarter_name,
      d.d_current_year,
      CONCAT(d.d_day_name, '_', d.d_quarter_name) AS day_quarter_concat,
      CASE
        WHEN regexp_like(d.d_day_name, '^S.*') THEN 'StartsWithS'
        ELSE 'Other'
      END AS day_name_category
    FROM date_dim d
    WHERE d.d_current_year = 'Y'
      AND regexp_extract(d.d_quarter_name, '(\\d+)') IS NOT NULL
  ),
  sales_only_dates AS (
    SELECT date_sk FROM sales_daily
    EXCEPT
    SELECT date_sk FROM returns_daily
  ),
  returns_only_dates AS (
    SELECT date_sk FROM returns_daily
    EXCEPT
    SELECT date_sk FROM sales_daily
  )

SELECT DISTINCT
  df.d_date,
  df.day_quarter_concat,
  sd.total_sales,
  sd.total_profit,
  sd.sales_level,
  df.day_name_category
FROM date_filtered df
JOIN sales_daily sd ON df.d_date_sk = sd.date_sk
JOIN sales_only_dates sod ON sd.date_sk = sod.date_sk

UNION

SELECT DISTINCT
  df.d_date,
  df.day_quarter_concat,
  rd.total_returns AS total_sales,
  rd.total_loss AS total_profit,
  CASE WHEN rd.total_returns > 5000 THEN 'HIGH' ELSE 'LOW' END AS sales_level,
  df.day_name_category
FROM date_filtered df
JOIN returns_daily rd ON df.d_date_sk = rd.date_sk
JOIN returns_only_dates rod ON rd.date_sk = rod.date_sk

ORDER BY d_date DESC
OFFSET 0
LIMIT 100
