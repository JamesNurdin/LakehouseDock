WITH sales AS (
 SELECT
   ss.ss_store_sk AS store_sk,
   d_s.d_year,
   d_s.d_quarter_seq,
   i.i_category,
   ss.ss_ext_sales_price AS sales_amount,
   ss.ss_ext_discount_amt AS discount_amount,
   ss.ss_net_profit AS profit,
   s.s_number_employees,
   s.s_state,
   s.s_store_id
 FROM store_sales ss
 JOIN date_dim d_s ON ss.ss_sold_date_sk = d_s.d_date_sk
 JOIN store s ON ss.ss_store_sk = s.s_store_sk
 JOIN item i ON ss.ss_item_sk = i.i_item_sk
 JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
 JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
 WHERE cd.cd_credit_rating = 'Excellent'
   AND hd.hd_income_band_sk IN (SELECT ib_income_band_sk FROM income_band WHERE ib_lower_bound >= 50000)
),
returns AS (
 SELECT
   sr.sr_store_sk AS store_sk,
   d_r.d_year,
   d_r.d_quarter_seq,
   i.i_category,
   SUM(sr.sr_net_loss) AS total_loss,
   SUM(sr.sr_return_quantity) AS total_return_qty
 FROM store_returns sr
 JOIN date_dim d_r ON sr.sr_returned_date_sk = d_r.d_date_sk
 JOIN item i ON sr.sr_item_sk = i.i_item_sk
 GROUP BY sr.sr_store_sk, d_r.d_year, d_r.d_quarter_seq, i.i_category
),
aggregated AS (
 SELECT
   st.s_store_id,
   st.s_state,
   st.s_number_employees,
   s_sales.d_year,
   s_sales.d_quarter_seq,
   s_sales.i_category,
   SUM(s_sales.sales_amount) AS total_sales,
   SUM(s_sales.discount_amount) AS total_discount,
   SUM(s_sales.profit) AS total_profit,
   COALESCE(MAX(r.total_loss), 0) AS total_returns_loss,
   SUM(s_sales.profit) - COALESCE(MAX(r.total_loss), 0) AS net_profit_adjusted,
   CASE WHEN SUM(s_sales.sales_amount) = 0 THEN 0 ELSE SUM(s_sales.discount_amount) / SUM(s_sales.sales_amount) * 100 END AS avg_discount_pct,
   CASE WHEN st.s_number_employees = 0 THEN 0 ELSE (SUM(s_sales.profit) - COALESCE(MAX(r.total_loss), 0)) / st.s_number_employees END AS profit_per_employee
 FROM sales s_sales
 LEFT JOIN returns r
   ON s_sales.store_sk = r.store_sk
   AND s_sales.d_year = r.d_year
   AND s_sales.d_quarter_seq = r.d_quarter_seq
   AND s_sales.i_category = r.i_category
 JOIN store st ON s_sales.store_sk = st.s_store_sk
 GROUP BY
   st.s_store_id,
   st.s_state,
   st.s_number_employees,
   s_sales.d_year,
   s_sales.d_quarter_seq,
   s_sales.i_category
)
SELECT
   a.s_store_id,
   a.s_state,
   a.d_year,
   a.d_quarter_seq,
   a.i_category,
   a.total_sales,
   a.total_discount,
   a.total_profit,
   a.total_returns_loss,
   a.net_profit_adjusted,
   a.avg_discount_pct,
   a.profit_per_employee,
   RANK() OVER (PARTITION BY a.d_year ORDER BY a.net_profit_adjusted DESC) AS profit_rank_year,
   LAG(a.net_profit_adjusted) OVER (PARTITION BY a.s_store_id, a.i_category ORDER BY a.d_year, a.d_quarter_seq) AS prior_quarter_profit,
   CASE
       WHEN LAG(a.net_profit_adjusted) OVER (PARTITION BY a.s_store_id, a.i_category ORDER BY a.d_year, a.d_quarter_seq) IS NULL
            OR LAG(a.net_profit_adjusted) OVER (PARTITION BY a.s_store_id, a.i_category ORDER BY a.d_year, a.d_quarter_seq) = 0 THEN NULL
       ELSE (a.net_profit_adjusted - LAG(a.net_profit_adjusted) OVER (PARTITION BY a.s_store_id, a.i_category ORDER BY a.d_year, a.d_quarter_seq)) / LAG(a.net_profit_adjusted) OVER (PARTITION BY a.s_store_id, a.i_category ORDER BY a.d_year, a.d_quarter_seq) * 100
   END AS profit_qoq_growth_pct
FROM aggregated a
ORDER BY a.d_year, a.d_quarter_seq, a.net_profit_adjusted DESC
LIMIT 200
