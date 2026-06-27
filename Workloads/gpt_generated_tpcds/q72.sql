WITH sales_returns AS (
  SELECT
    ss.ss_store_sk,
    d_s.d_year,
    d_s.d_moy,
    cd.cd_gender,
    SUM(ss.ss_quantity) AS total_quantity,
    SUM(ss.ss_net_profit) AS total_net_profit,
    SUM(COALESCE(sr.sr_return_quantity, 0)) AS total_return_quantity,
    SUM(COALESCE(sr.sr_return_amt, 0)) AS total_return_amount,
    SUM(COALESCE(sr.sr_net_loss, 0)) AS total_return_net_loss
  FROM store_sales ss
  JOIN date_dim d_s
    ON ss.ss_sold_date_sk = d_s.d_date_sk
  JOIN customer_demographics cd
    ON ss.ss_cdemo_sk = cd.cd_demo_sk
  LEFT JOIN store_returns sr
    ON ss.ss_ticket_number = sr.sr_ticket_number
   AND ss.ss_item_sk = sr.sr_item_sk
  LEFT JOIN date_dim d_r
    ON sr.sr_returned_date_sk = d_r.d_date_sk
  WHERE d_s.d_year = 2001
  GROUP BY ss.ss_store_sk, d_s.d_year, d_s.d_moy, cd.cd_gender
)

SELECT
  srp.ss_store_sk,
  srp.d_year,
  srp.d_moy,
  srp.cd_gender,
  srp.total_quantity,
  srp.total_net_profit,
  srp.total_return_quantity,
  srp.total_return_amount,
  srp.total_return_net_loss,
  (srp.total_net_profit - srp.total_return_net_loss) AS net_profit_after_returns,
  CASE
    WHEN srp.total_quantity = 0 THEN 0
    ELSE (srp.total_return_quantity * 100.0) / srp.total_quantity
  END AS return_quantity_pct,
  SUM(srp.total_net_profit - srp.total_return_net_loss) OVER (
    PARTITION BY srp.ss_store_sk
    ORDER BY srp.d_year, srp.d_moy
    ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
  ) AS cumulative_net_profit,
  ROW_NUMBER() OVER (
    PARTITION BY srp.d_year, srp.d_moy, srp.cd_gender
    ORDER BY (srp.total_net_profit - srp.total_return_net_loss) DESC
  ) AS profit_rank_by_month_gender
FROM sales_returns srp
ORDER BY srp.ss_store_sk, srp.d_year, srp.d_moy, srp.cd_gender
