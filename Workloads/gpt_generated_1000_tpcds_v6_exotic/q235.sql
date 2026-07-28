WITH
  ws_agg AS (
    SELECT
      ws_sold_date_sk,
      ws_web_page_sk,
      SUM(ws_ext_sales_price) AS daily_sales,
      SUM(ws_net_profit) AS daily_profit,
      COUNT(*) AS cnt_sales
    FROM web_sales
    WHERE ws_ext_sales_price > 500
    GROUP BY ws_sold_date_sk, ws_web_page_sk
  ),
  ret_agg AS (
    SELECT
      sr_returned_date_sk,
      SUM(sr_return_amt_inc_tax) AS total_return_amt,
      SUM(sr_fee) AS total_fee,
      COUNT(*) AS cnt_returns
    FROM store_returns
    WHERE sr_fee > 30
    GROUP BY sr_returned_date_sk
  ),
  reference_dates AS (
    SELECT d_date_sk, d_year, d_month_seq, d_date
    FROM date_dim
    WHERE d_year IN (2000, 2001, 2002)
      AND d_month_seq BETWEEN 1150 AND 1230
  )
SELECT *
FROM (
  SELECT
    d_sold.d_date AS trans_date,
    d_sold.d_year,
    wp.wp_type AS page_type,
    ws_agg.daily_sales,
    ws_agg.daily_profit,
    CASE WHEN ws_agg.daily_profit > 0 THEN 'PROFIT' ELSE 'LOSS' END AS profit_flag,
    ROW_NUMBER() OVER (PARTITION BY d_sold.d_year ORDER BY ws_agg.daily_profit DESC) AS profit_rank,
    (SELECT AVG(daily_profit) FROM ws_agg) AS avg_daily_profit
  FROM ws_agg
  JOIN web_sales ws
    ON ws.ws_sold_date_sk = ws_agg.ws_sold_date_sk
   AND ws.ws_web_page_sk = ws_agg.ws_web_page_sk
  JOIN date_dim d_sold
    ON ws.ws_sold_date_sk = d_sold.d_date_sk
  JOIN time_dim t_sold
    ON ws.ws_sold_time_sk = t_sold.t_time_sk
  JOIN web_page wp
    ON ws.ws_web_page_sk = wp.wp_web_page_sk
  JOIN date_dim d_create
    ON wp.wp_creation_date_sk = d_create.d_date_sk
  JOIN reference_dates rd
    ON d_sold.d_date_sk = rd.d_date_sk
  WHERE d_sold.d_qoy = 2
    AND t_sold.t_hour BETWEEN 9 AND 17
    AND wp.wp_type = 'article'
    AND ws.ws_ext_sales_price > 1000
    AND ws.ws_net_paid_inc_ship_tax IS NOT NULL

  UNION ALL

  SELECT
    d_ret.d_date AS trans_date,
    d_ret.d_year,
    NULL AS page_type,
    NULL AS daily_sales,
    NULL AS daily_profit,
    CASE WHEN ret_agg.total_return_amt > 2000 THEN 'HIGH' ELSE 'LOW' END AS profit_flag,
    ROW_NUMBER() OVER (PARTITION BY d_ret.d_year ORDER BY ret_agg.total_return_amt DESC) AS profit_rank,
    (SELECT AVG(total_return_amt) FROM ret_agg) AS avg_daily_profit
  FROM ret_agg
  JOIN store_returns sr
    ON sr.sr_returned_date_sk = ret_agg.sr_returned_date_sk
  JOIN date_dim d_ret
    ON sr.sr_returned_date_sk = d_ret.d_date_sk
  JOIN time_dim t_ret
    ON sr.sr_return_time_sk = t_ret.t_time_sk
  WHERE d_ret.d_month_seq BETWEEN 1150 AND 1200
    AND EXISTS (
      SELECT 1
      FROM web_sales ws2
      WHERE ws2.ws_sold_date_sk = sr.sr_returned_date_sk
        AND ws2.ws_ext_sales_price > 1500
    )
) final_result
ORDER BY final_result.d_year, final_result.profit_rank
LIMIT 100
