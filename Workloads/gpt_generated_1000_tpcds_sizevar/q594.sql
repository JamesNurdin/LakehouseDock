WITH base AS (
   SELECT
     ss.ss_ticket_number,
     ss.ss_sold_date_sk,
     ss.ss_sold_time_sk,
     ss.ss_item_sk,
     ss.ss_quantity,
     ss.ss_net_paid,
     ss.ss_net_profit,
     cd.cd_gender,
     cd.cd_marital_status,
     hd.hd_income_band_sk,
     ib.ib_lower_bound,
     ib.ib_upper_bound,
     t.t_hour,
     sr.sr_return_quantity,
     sr.sr_return_amt,
     wr.wr_return_quantity,
     wr.wr_return_amt
   FROM store_sales ss
   TABLESAMPLE BERNOULLI (10) -- sample 10% of rows
   JOIN time_dim t
     ON ss.ss_sold_time_sk = t.t_time_sk
   JOIN customer_demographics cd
     ON ss.ss_cdemo_sk = cd.cd_demo_sk
   JOIN household_demographics hd
     ON ss.ss_hdemo_sk = hd.hd_demo_sk
   JOIN income_band ib
     ON hd.hd_income_band_sk = ib.ib_income_band_sk
   LEFT JOIN store_returns sr
     ON ss.ss_item_sk = sr.sr_item_sk
    AND ss.ss_ticket_number = sr.sr_ticket_number
   LEFT JOIN web_returns wr
     ON wr.wr_returned_time_sk = t.t_time_sk
   WHERE t.t_hour BETWEEN 8 AND 18                         -- filter on time of day
     AND hd.hd_dep_count > 2                               -- filter on household dependents
     AND ib.ib_upper_bound <= 200000                       -- filter on income band
     AND ss.ss_net_paid > 100                               -- filter on sales amount
),

agg1 AS (
   SELECT
     ss_ticket_number,
     cd_gender,
     hd_income_band_sk,
     SUM(ss_net_paid)   AS total_paid,
     SUM(ss_net_profit) AS total_profit,
     COUNT(*)            AS sales_cnt,
     SUM(CASE WHEN sr_return_quantity IS NOT NULL THEN sr_return_quantity ELSE 0 END) AS total_store_returns,
     SUM(CASE WHEN wr_return_quantity IS NOT NULL THEN wr_return_quantity ELSE 0 END) AS total_web_returns
   FROM base
   GROUP BY ss_ticket_number, cd_gender, hd_income_band_sk
),

lateral_calc AS (
   SELECT
     a.*,
     CASE
       WHEN a.total_paid = 0 THEN 0
       ELSE (a.total_store_returns + a.total_web_returns) * 1.0 / a.total_paid
     END AS return_rate,
     lc.paid_category
   FROM agg1 a
   CROSS JOIN LATERAL (
     SELECT CASE WHEN a.total_paid > 1000 THEN 'HIGH' ELSE 'LOW' END AS paid_category
   ) lc
)

SELECT
  hd_income_band_sk,
  cd_gender,
  AVG(total_paid)   AS avg_total_paid,
  AVG(total_profit) AS avg_total_profit,
  AVG(return_rate)  AS avg_return_rate,
  COUNT(*)           AS groups_cnt,
  MAX(paid_category) FILTER (WHERE paid_category = 'HIGH') AS has_high_category
FROM lateral_calc
GROUP BY hd_income_band_sk, cd_gender
HAVING AVG(total_paid) > 500
ORDER BY avg_total_paid DESC
OFFSET 0 FETCH FIRST 10 ROWS ONLY
