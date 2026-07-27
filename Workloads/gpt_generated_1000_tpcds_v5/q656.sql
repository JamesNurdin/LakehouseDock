WITH sales_agg AS (
  SELECT
    ss.ss_store_sk,
    ds.d_date_sk   AS sold_date_sk,
    ds.d_date      AS sold_date,
    ts.t_time_sk   AS sold_time_sk,
    ts.t_hour      AS sold_hour,
    hd.hd_income_band_sk,
    ca.ca_state,
    SUM(ss.ss_ext_sales_price) AS total_sales,
    SUM(ss.ss_net_profit)      AS total_profit,
    COUNT(DISTINCT ss.ss_ticket_number) AS distinct_tickets
  FROM store_sales ss
  JOIN date_dim ds   ON ss.ss_sold_date_sk = ds.d_date_sk
  JOIN time_dim ts   ON ss.ss_sold_time_sk = ts.t_time_sk
  JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
  JOIN customer_address ca       ON ss.ss_addr_sk = ca.ca_address_sk
  WHERE ds.d_year = 2002
    AND ts.t_hour BETWEEN 9 AND 17
    AND hd.hd_income_band_sk IN (7, 13, 14)
    AND ca.ca_state = 'TX'
    AND ss.ss_quantity > 0
  GROUP BY
    ss.ss_store_sk,
    ds.d_date_sk,
    ds.d_date,
    ts.t_time_sk,
    ts.t_hour,
    hd.hd_income_band_sk,
    ca.ca_state
),
returns_distinct AS (
  SELECT DISTINCT
    wr.wr_returned_date_sk,
    wr.wr_returned_time_sk,
    wr.wr_return_amt_inc_tax,
    wr.wr_web_page_sk,
    wr.wr_returning_hdemo_sk,
    wr.wr_returning_addr_sk
  FROM web_returns wr
  JOIN date_dim dr ON wr.wr_returned_date_sk = dr.d_date_sk
  JOIN time_dim tr ON wr.wr_returned_time_sk = tr.t_time_sk
  WHERE dr.d_year = 2002
    AND tr.t_hour BETWEEN 9 AND 17
    AND wr.wr_return_amt_inc_tax > 100
)
SELECT
  sa.ss_store_sk,
  sa.sold_date,
  sa.sold_hour,
  sa.hd_income_band_sk,
  sa.ca_state,
  sa.total_sales,
  sa.total_profit,
  rd.wr_return_amt_inc_tax,
  wp.wp_type,
  cc.cc_name,
  RANK() OVER (PARTITION BY sa.ss_store_sk ORDER BY sa.total_sales DESC) AS sales_rank,
  ROW_NUMBER() OVER (PARTITION BY sa.ss_store_sk ORDER BY rd.wr_return_amt_inc_tax DESC) AS return_amount_rownum
FROM sales_agg sa
JOIN returns_distinct rd
  ON rd.wr_returned_date_sk = sa.sold_date_sk
  AND rd.wr_returned_time_sk = sa.sold_time_sk
JOIN web_page wp
  ON rd.wr_web_page_sk = wp.wp_web_page_sk
  AND wp.wp_type = 'content'
JOIN household_demographics hd_ret
  ON rd.wr_returning_hdemo_sk = hd_ret.hd_demo_sk
  AND hd_ret.hd_income_band_sk = 7
JOIN customer_address ca_ret
  ON rd.wr_returning_addr_sk = ca_ret.ca_address_sk
  AND ca_ret.ca_state = 'CA'
JOIN call_center cc
  ON cc.cc_open_date_sk = sa.sold_date_sk
  AND cc.cc_state = 'TX'
ORDER BY sa.total_sales DESC, rd.wr_return_amt_inc_tax DESC
LIMIT 100
