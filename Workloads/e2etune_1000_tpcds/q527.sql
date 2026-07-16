WITH site_warehouse_band AS (
   SELECT ws.web_site_id,
          w.w_city,
          ib.ib_income_band_sk,
          SUM(wr.wr_return_amt) AS total_return_amt,
          COUNT(*) AS cnt_returns,
          AVG(wr.wr_return_amt) AS avg_return_amt
   FROM web_returns wr
   JOIN income_band ib
     ON wr.wr_return_amt BETWEEN ib.ib_lower_bound AND ib.ib_upper_bound
   JOIN web_site ws
     ON wr.wr_returned_date_sk = ws.web_open_date_sk
   JOIN warehouse w
     ON ws.web_country = w.w_country
    AND ws.web_state = w.w_state
   WHERE ws.web_country = 'United States'
   GROUP BY ws.web_site_id, w.w_city, ib.ib_income_band_sk
)
SELECT web_site_id,
       w_city,
       ib_income_band_sk,
       total_return_amt,
       cnt_returns,
       avg_return_amt,
       ROW_NUMBER() OVER (PARTITION BY web_site_id ORDER BY total_return_amt DESC) AS rn_within_site
FROM site_warehouse_band
ORDER BY total_return_amt DESC
LIMIT 50
