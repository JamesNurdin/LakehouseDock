WITH base AS (
   SELECT
       d.d_year,
       s.s_store_name,
       r.r_reason_desc,
       sr.sr_net_loss,
       cs.cs_net_profit,
       cr.cr_net_loss,
       wr.wr_net_loss,
       cc.cc_employees,
       sm.sm_code
   FROM store_returns sr
   JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
   JOIN store s ON sr.sr_store_sk = s.s_store_sk
   JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
   JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
   JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
   JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
   JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
   JOIN catalog_sales cs ON cs.cs_bill_customer_sk = c.c_customer_sk
       AND cs.cs_sold_date_sk = d.d_date_sk
   JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
   JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
   JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
   JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
       AND cr.cr_returned_date_sk = d.d_date_sk
   JOIN web_returns wr ON wr.wr_returned_date_sk = d.d_date_sk
       AND wr.wr_refunded_customer_sk = c.c_customer_sk
),
agg1 AS (
   SELECT
       d_year,
       s_store_name,
       r_reason_desc,
       SUM(sr_net_loss)           AS total_store_loss,
       SUM(cs_net_profit)         AS total_sales_profit,
       SUM(cr_net_loss)           AS total_return_loss,
       SUM(wr_net_loss)           AS total_web_loss,
       COUNT(*)                   AS txn_cnt
   FROM base
   WHERE d_year BETWEEN 2000 AND 2002
     AND cc_employees > 1000000
     AND sm_code = 'AIR'
   GROUP BY ROLLUP (d_year, s_store_name, r_reason_desc)
),
numbered AS (
   SELECT
       *,
       ROW_NUMBER() OVER (ORDER BY total_store_loss DESC) AS rn
   FROM agg1
),
cross_set AS (
   SELECT DISTINCT d_quarter_name
   FROM date_dim
   WHERE d_year = 2001
),
cross_joined AS (
   SELECT n.*, cs.d_quarter_name
   FROM numbered n
   CROSS JOIN cross_set cs
),
union_set AS (
   SELECT d_year, s_store_name, total_store_loss
   FROM cross_joined
   WHERE rn <= 5
   UNION
   SELECT d_year, s_store_name, total_store_loss
   FROM cross_joined
   WHERE total_store_loss > 0
),
final AS (
   SELECT *
   FROM union_set
   EXCEPT
   SELECT d_year, s_store_name, total_store_loss
   FROM union_set
   WHERE total_store_loss IS NULL
)
SELECT
   d_year,
   s_store_name,
   SUM(total_store_loss) AS sum_loss,
   COUNT(*)               AS cnt,
   SUM(total_store_loss) / NULLIF(COUNT(*), 0) AS avg_loss
FROM final
GROUP BY ROLLUP (d_year, s_store_name)
ORDER BY d_year, s_store_name
LIMIT 100
