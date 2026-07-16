WITH store_metrics AS (
  SELECT
    ss.ss_store_sk,
    ss.ss_sold_date_sk,
    SUM(ss.ss_net_profit) AS total_sales_profit,
    SUM(COALESCE(sr.sr_net_loss, 0)) AS total_return_loss
  FROM store_sales ss
  LEFT JOIN store_returns sr
    ON ss.ss_item_sk = sr.sr_item_sk
   AND ss.ss_ticket_number = sr.sr_ticket_number
  WHERE ss.ss_quantity > 0
  GROUP BY ss.ss_store_sk, ss.ss_sold_date_sk
  HAVING SUM(ss.ss_net_profit) > 0
)
SELECT
  sm.ss_store_sk,
  sm.ss_sold_date_sk,
  sm.total_sales_profit,
  sm.total_return_loss,
  sm.total_sales_profit - sm.total_return_loss AS net_contribution,
  RANK() OVER (PARTITION BY sm.ss_sold_date_sk ORDER BY (sm.total_sales_profit - sm.total_return_loss) DESC) AS profit_rank,
  SUM(sm.total_sales_profit - sm.total_return_loss) OVER (
    PARTITION BY sm.ss_store_sk
    ORDER BY sm.ss_sold_date_sk
    ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
  ) AS cumulative_net_contribution
FROM store_metrics sm
ORDER BY net_contribution DESC
LIMIT 100
