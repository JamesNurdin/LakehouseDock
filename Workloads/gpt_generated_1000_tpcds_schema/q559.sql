WITH joined_data AS (
  SELECT
    s.s_store_id,
    s.s_state,
    ca.ca_state AS ca_state,
    ca.ca_country,
    d.d_year,
    t.t_hour,
    i.i_current_price,
    ib.ib_income_band_sk,
    ib.ib_lower_bound,
    ss.ss_ext_sales_price,
    ss.ss_net_profit
  FROM store_sales ss
  TABLESAMPLE BERNOULLI (10)
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
  JOIN item i ON ss.ss_item_sk = i.i_item_sk
  JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
  JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
  JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
  JOIN store s ON ss.ss_store_sk = s.s_store_sk
  JOIN web_returns wr ON wr.wr_returned_date_sk = d.d_date_sk
  JOIN inventory inv ON inv.inv_date_sk = d.d_date_sk AND inv.inv_item_sk = i.i_item_sk
  WHERE d.d_year BETWEEN 2000 AND 2002
    AND i.i_current_price BETWEEN 10 AND 1000
    AND s.s_state = 'TX'
    AND ca.ca_country = 'United States'
    AND t.t_hour BETWEEN 9 AND 17
    AND ib.ib_lower_bound >= 50000
),
agg1 AS (
  SELECT
    s_store_id,
    d_year,
    ib_income_band_sk,
    SUM(ss_ext_sales_price) AS total_sales,
    SUM(ss_net_profit) AS total_profit
  FROM joined_data
  GROUP BY GROUPING SETS (
    (s_store_id, d_year, ib_income_band_sk),
    (s_store_id, d_year),
    (s_store_id),
    (d_year),
    ()
  )
),
high_profit_stores AS (
  SELECT s_store_id FROM agg1 WHERE total_profit > 5000
  EXCEPT
  SELECT s_store_id FROM agg1 WHERE total_sales < 2000
)
SELECT
  a.s_store_id,
  a.d_year,
  a.ib_income_band_sk,
  a.total_sales,
  a.total_profit,
  a.total_sales / NULLIF(a.total_profit, 0) AS sales_per_profit,
  (SELECT AVG(total_sales) FROM agg1) AS avg_total_sales
FROM agg1 a
WHERE a.total_sales > 1000
  AND a.s_store_id IN (SELECT s_store_id FROM high_profit_stores)
  AND a.s_store_id IN (SELECT s2.s_store_id FROM store s2 WHERE s2.s_state = 'TX')
  AND a.total_sales > (SELECT AVG(total_sales) FROM agg1)
ORDER BY a.total_sales DESC
LIMIT 100
