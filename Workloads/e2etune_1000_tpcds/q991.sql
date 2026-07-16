WITH sales_by_income AS (
  SELECT ib.ib_income_band_sk,
         ib.ib_lower_bound,
         ib.ib_upper_bound,
         SUM(ws.ws_net_profit) AS total_sales_profit,
         SUM(ws.ws_ext_sales_price) AS total_sales_amount
  FROM web_sales ws
  JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
  JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
  WHERE ws.ws_sold_date_sk BETWEEN 2450815 AND 2451088
  GROUP BY ib.ib_income_band_sk, ib.ib_lower_bound, ib.ib_upper_bound
),
returns_by_income AS (
  SELECT ib.ib_income_band_sk,
         ib.ib_lower_bound,
         ib.ib_upper_bound,
         r.r_reason_desc,
         SUM(cr.cr_return_amount) AS total_return_amount,
         SUM(cr.cr_net_loss) AS total_return_loss
  FROM catalog_returns cr
  JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
  JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
  JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
  WHERE cr.cr_returned_date_sk BETWEEN 2450815 AND 2451088
    AND r.r_reason_desc LIKE '%Defect%'
  GROUP BY ib.ib_income_band_sk, ib.ib_lower_bound, ib.ib_upper_bound, r.r_reason_desc
)
SELECT s.ib_lower_bound,
       s.ib_upper_bound,
       s.total_sales_profit,
       s.total_sales_amount,
       r.r_reason_desc,
       r.total_return_amount,
       r.total_return_loss,
       (s.total_sales_profit - r.total_return_loss) AS net_profit_after_returns
FROM sales_by_income s
JOIN returns_by_income r ON s.ib_income_band_sk = r.ib_income_band_sk
WHERE s.total_sales_profit > 10000
ORDER BY net_profit_after_returns DESC
LIMIT 100
