WITH sales_daily AS (
   SELECT cs_sold_date_sk AS date_sk,
          SUM(cs_net_paid_inc_tax) AS daily_sales,
          SUM(cs_net_profit) AS daily_profit
   FROM catalog_sales
   GROUP BY cs_sold_date_sk
   UNION ALL
   SELECT ws_sold_date_sk AS date_sk,
          SUM(ws_net_paid_inc_tax) AS daily_sales,
          SUM(ws_net_profit) AS daily_profit
   FROM web_sales
   GROUP BY ws_sold_date_sk
),
sales_agg AS (
   SELECT date_sk,
          SUM(daily_sales) AS total_sales,
          SUM(daily_profit) AS total_profit
   FROM sales_daily
   GROUP BY date_sk
),
returns_daily AS (
   SELECT sr_returned_date_sk AS date_sk,
          SUM(sr_net_loss) AS daily_loss,
          SUM(sr_return_amt) AS daily_return_amount
   FROM store_returns
   GROUP BY sr_returned_date_sk
),
combined AS (
   SELECT
      s.date_sk,
      s.total_sales,
      s.total_profit,
      COALESCE(r.daily_loss, 0) AS total_loss,
      s.total_profit - COALESCE(r.daily_loss, 0) AS net_profit,
      SUM(s.total_profit - COALESCE(r.daily_loss, 0)) OVER (
         ORDER BY s.date_sk
         ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
      ) AS cumulative_net_profit
   FROM sales_agg s
   LEFT JOIN returns_daily r ON s.date_sk = r.date_sk
)
SELECT
   date_sk,
   total_sales,
   total_loss,
   net_profit,
   cumulative_net_profit,
   CASE
      WHEN net_profit < LAG(net_profit) OVER (ORDER BY date_sk) THEN 'Decline'
      ELSE 'Growth'
   END AS profit_trend
FROM combined
ORDER BY date_sk
