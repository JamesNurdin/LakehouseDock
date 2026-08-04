/*
Goal: Analyze average store return amounts by call‑center city and product category for the year 2001. The query distinguishes high vs low return amounts, uses a 10% Bernoulli sample of store_returns, requires that the product category has at least one promotion in the same year, and aggregates the data in two steps (per‑group then overall).
*/
WITH base AS (
   SELECT
     sr.sr_returned_date_sk,
     d.d_year,
     i.i_item_id,
     i.i_current_price,
     i.i_category,
     c.c_customer_id,
     cd.cd_gender,
     hd.hd_income_band_sk,
     ib.ib_lower_bound,
     p.p_promo_name,
     cc.cc_city,
     ws.web_name,
     t.t_hour,
     sr.sr_return_amt,
     CASE WHEN sr.sr_return_amt > 100 THEN 'high' ELSE 'low' END AS return_level
   FROM store_returns sr TABLESAMPLE BERNOULLI (10)
   JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
   JOIN time_dim t ON sr.sr_return_time_sk = t.t_time_sk
   JOIN item i ON sr.sr_item_sk = i.i_item_sk
   JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
   JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
   JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
   JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
   JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
   JOIN promotion p ON p.p_item_sk = i.i_item_sk AND p.p_start_date_sk = d.d_date_sk
   JOIN call_center cc ON cc.cc_open_date_sk = d.d_date_sk
   JOIN catalog_page cp ON cp.cp_start_date_sk = d.d_date_sk
   JOIN web_site ws ON ws.web_open_date_sk = d.d_date_sk
   WHERE d.d_year = 2001
     AND i.i_current_price BETWEEN 10 AND 100
     AND cc.cc_city = 'Salem'
),
aggreg_low AS (
   SELECT
     d_year,
     i_category,
     cc_city,
     SUM(sr_return_amt) AS total_return,
     COUNT(*) AS cnt,
     AVG(CASE WHEN return_level = 'high' THEN 1.0 ELSE 0.0 END) AS high_return_ratio
   FROM base
   WHERE i_current_price < 50
   GROUP BY d_year, i_category, cc_city
),
aggreg_high AS (
   SELECT
     d_year,
     i_category,
     cc_city,
     SUM(sr_return_amt) AS total_return,
     COUNT(*) AS cnt,
     AVG(CASE WHEN return_level = 'high' THEN 1.0 ELSE 0.0 END) AS high_return_ratio
   FROM base
   WHERE i_current_price >= 50
   GROUP BY d_year, i_category, cc_city
),
unioned AS (
   SELECT * FROM aggreg_low
   UNION
   SELECT * FROM aggreg_high
)
SELECT
  u.cc_city,
  AVG(u.total_return) AS avg_total_return,
  SUM(u.cnt) AS total_transactions,
  MAX(u.high_return_ratio) AS max_high_return_ratio
FROM unioned u
WHERE EXISTS (
   SELECT 1
   FROM promotion p2
   JOIN date_dim d2 ON p2.p_start_date_sk = d2.d_date_sk
   JOIN item i2 ON p2.p_item_sk = i2.i_item_sk
   WHERE i2.i_category = u.i_category
     AND d2.d_year = u.d_year
)
GROUP BY u.cc_city
HAVING AVG(u.total_return) > 500
ORDER BY avg_total_return DESC
LIMIT 100
