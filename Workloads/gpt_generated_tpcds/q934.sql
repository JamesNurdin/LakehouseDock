WITH sales_agg AS (
   SELECT
       s.s_store_name,
       d.d_year,
       d.d_quarter_name,
       hd.hd_buy_potential,
       SUM(ss.ss_ext_sales_price) AS total_sales,
       SUM(ss.ss_quantity) AS total_quantity,
       SUM(ss.ss_net_profit) AS total_profit
   FROM store_sales ss
   JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
   JOIN store s ON ss.ss_store_sk = s.s_store_sk
   JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
   WHERE s.s_closed_date_sk IS NULL
     AND d.d_year = 2001
   GROUP BY s.s_store_name, d.d_year, d.d_quarter_name, hd.hd_buy_potential
),
returns_agg AS (
   SELECT
       s.s_store_name,
       d.d_year,
       d.d_quarter_name,
       hd.hd_buy_potential,
       SUM(sr.sr_return_amt) AS total_returns,
       SUM(sr.sr_return_quantity) AS total_return_quantity,
       SUM(sr.sr_net_loss) AS total_return_loss
   FROM store_returns sr
   JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
   JOIN store s ON sr.sr_store_sk = s.s_store_sk
   JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
   WHERE s.s_closed_date_sk IS NULL
     AND d.d_year = 2001
   GROUP BY s.s_store_name, d.d_year, d.d_quarter_name, hd.hd_buy_potential
)
SELECT
   COALESCE(sa.s_store_name, ra.s_store_name) AS store_name,
   COALESCE(sa.d_year, ra.d_year) AS year,
   COALESCE(sa.d_quarter_name, ra.d_quarter_name) AS quarter,
   COALESCE(sa.hd_buy_potential, ra.hd_buy_potential) AS buy_potential,
   sa.total_sales,
   ra.total_returns,
   (sa.total_profit - ra.total_return_loss) AS net_profit_after_returns,
   CASE
       WHEN sa.total_quantity > 0 THEN ra.total_return_quantity / CAST(sa.total_quantity AS double)
       ELSE 0
   END AS return_rate
FROM sales_agg sa
FULL OUTER JOIN returns_agg ra
   ON sa.s_store_name = ra.s_store_name
  AND sa.d_year = ra.d_year
  AND sa.d_quarter_name = ra.d_quarter_name
  AND sa.hd_buy_potential = ra.hd_buy_potential
ORDER BY store_name, year, quarter, buy_potential
