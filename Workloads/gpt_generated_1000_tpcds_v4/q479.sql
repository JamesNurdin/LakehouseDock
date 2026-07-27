WITH
  sales_agg AS (
    SELECT
      cs_bill_addr_sk,
      cs_ship_mode_sk,
      cs_sold_date_sk,
      cs_sold_time_sk,
      cs_bill_hdemo_sk,
      SUM(cs_ext_sales_price) AS total_sales,
      SUM(cs_quantity) AS total_qty,
      AVG(cs_ext_discount_amt) AS avg_discount
    FROM catalog_sales
    WHERE cs_ext_sales_price > 0
    GROUP BY cs_bill_addr_sk, cs_ship_mode_sk, cs_sold_date_sk, cs_sold_time_sk, cs_bill_hdemo_sk
  ),
  returns_agg AS (
    SELECT
      sr_addr_sk,
      sr_returned_date_sk,
      SUM(sr_return_amt) AS total_returns,
      COUNT(*) AS return_cnt
    FROM store_returns
    GROUP BY sr_addr_sk, sr_returned_date_sk
  )
SELECT
  d.d_year,
  t.t_hour,
  ca.ca_state,
  sm.sm_type,
  ib.ib_upper_bound,
  ws.web_city,
  ws.web_name,
  sales_agg.total_sales,
  COALESCE(returns_agg.total_returns, 0) AS total_returns,
  (sales_agg.total_sales - COALESCE(returns_agg.total_returns, 0)) AS net_sales,
  CASE
    WHEN sales_agg.avg_discount > (
      SELECT AVG(cs_ext_discount_amt)
      FROM catalog_sales
      WHERE cs_ship_mode_sk = sales_agg.cs_ship_mode_sk
    ) THEN 'High'
    ELSE 'Low'
  END AS discount_level,
  RANK() OVER (PARTITION BY d.d_year ORDER BY (sales_agg.total_sales - COALESCE(returns_agg.total_returns, 0)) DESC) AS sales_rank
FROM sales_agg
LEFT JOIN returns_agg
  ON sales_agg.cs_bill_addr_sk = returns_agg.sr_addr_sk
  AND sales_agg.cs_sold_date_sk = returns_agg.sr_returned_date_sk
JOIN customer_address ca
  ON sales_agg.cs_bill_addr_sk = ca.ca_address_sk
JOIN ship_mode sm
  ON sales_agg.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN date_dim d
  ON sales_agg.cs_sold_date_sk = d.d_date_sk
JOIN time_dim t
  ON sales_agg.cs_sold_time_sk = t.t_time_sk
JOIN household_demographics hd
  ON sales_agg.cs_bill_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib
  ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN web_page wp
  ON wp.wp_creation_date_sk = d.d_date_sk
JOIN web_site ws
  ON ws.web_open_date_sk = d.d_date_sk
WHERE d.d_year = 2001
  AND t.t_hour BETWEEN 8 AND 18
  AND ib.ib_upper_bound <= 90000
  AND sm.sm_type = 'AIR'
  AND ca.ca_state = 'CA'
  AND ws.web_city = 'Springfield'
ORDER BY net_sales DESC
