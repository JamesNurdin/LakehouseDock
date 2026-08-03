WITH recent_dates AS (
   SELECT d_date_sk, d_year
   FROM date_dim
   WHERE d_year IN (2000, 2001)
)
SELECT d_year,
       ship_mode_type,
       total_return_amount,
       total_net_loss,
       loss_category,
       avg_income_lower
FROM (
   SELECT
       rd.d_year,
       sm.sm_type AS ship_mode_type,
       SUM(cr.cr_return_amount) AS total_return_amount,
       SUM(cr.cr_net_loss) AS total_net_loss,
       CASE WHEN SUM(cr.cr_net_loss) > 10000 THEN 'HIGH' ELSE 'LOW' END AS loss_category,
       (SELECT AVG(ib_lower_bound) FROM income_band) AS avg_income_lower
   FROM catalog_returns cr
   JOIN recent_dates rd ON cr.cr_returned_date_sk = rd.d_date_sk
   JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
   GROUP BY GROUPING SETS ((rd.d_year, sm.sm_type), (rd.d_year))
) AS cat
UNION ALL
SELECT d_year,
       ship_mode_type,
       total_return_amount,
       total_net_loss,
       loss_category,
       avg_income_lower
FROM (
   SELECT
       rd.d_year,
       sm.sm_type AS ship_mode_type,
       SUM(wr.wr_return_amt) AS total_return_amount,
       SUM(wr.wr_net_loss) AS total_net_loss,
       CASE WHEN SUM(wr.wr_net_loss) > 15000 THEN 'HIGH' ELSE 'LOW' END AS loss_category,
       (SELECT AVG(ib_lower_bound) FROM income_band) AS avg_income_lower
   FROM web_returns wr
   JOIN recent_dates rd ON wr.wr_returned_date_sk = rd.d_date_sk
   JOIN web_sales ws ON wr.wr_order_number = ws.ws_order_number
   JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
   GROUP BY GROUPING SETS ((rd.d_year, sm.sm_type), (rd.d_year))
) AS web
ORDER BY d_year DESC NULLS LAST, loss_category ASC
LIMIT 100
