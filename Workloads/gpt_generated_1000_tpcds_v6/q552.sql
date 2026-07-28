WITH
  sales_agg AS (
    SELECT
      td.t_sub_shift,
      ca.ca_location_type,
      SUM(ss.ss_ext_sales_price) AS total_sales,
      SUM(ss.ss_net_profit) AS total_profit,
      COUNT(*) AS sales_cnt
    FROM store_sales ss
    JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    WHERE td.t_am_pm = 'PM'
    GROUP BY td.t_sub_shift, ca.ca_location_type
  ),
  returns_agg AS (
    SELECT
      td.t_sub_shift,
      ca.ca_location_type,
      SUM(wr.wr_return_amt) AS total_returns,
      SUM(wr.wr_net_loss) AS total_loss,
      COUNT(*) AS return_cnt
    FROM web_returns wr
    JOIN time_dim td ON wr.wr_returned_time_sk = td.t_time_sk
    JOIN customer_address ca ON wr.wr_refunded_addr_sk = ca.ca_address_sk
    WHERE td.t_am_pm = 'PM'
    GROUP BY td.t_sub_shift, ca.ca_location_type
  ),
  combined AS (
    SELECT
      s.t_sub_shift      AS sub_shift,
      s.ca_location_type AS location_type,
      s.total_sales,
      0.0                AS total_returns,
      s.total_profit,
      0.0                AS total_loss,
      s.sales_cnt,
      0                  AS return_cnt,
      'store_sales'      AS source
    FROM sales_agg s
    UNION ALL
    SELECT
      r.t_sub_shift,
      r.ca_location_type,
      0.0,
      r.total_returns,
      0.0,
      r.total_loss,
      0,
      r.return_cnt,
      'web_returns'
    FROM returns_agg r
  )
SELECT
  sub_shift,
  location_type,
  total_sales,
  total_returns,
  total_profit,
  total_loss,
  sales_cnt,
  return_cnt,
  source,
  SUM(total_sales + total_returns) OVER (
    PARTITION BY sub_shift
    ORDER BY location_type
    ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
  ) AS cum_amount
FROM combined
ORDER BY sub_shift, location_type, source
