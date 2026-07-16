WITH unified AS (
   SELECT d.d_year AS year,
          s.s_state AS state,
          ss.ss_net_paid AS sales,
          sr.sr_return_amt AS returns,
          ss.ss_net_profit AS profit
   FROM store_sales ss
   JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
   JOIN store s ON ss.ss_store_sk = s.s_store_sk
   LEFT JOIN store_returns sr
      ON ss.ss_ticket_number = sr.sr_ticket_number
   UNION ALL
   SELECT d.d_year AS year,
          NULL AS state,
          cs.cs_net_paid AS sales,
          cr.cr_return_amount AS returns,
          cs.cs_net_profit AS profit
   FROM catalog_sales cs
   JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
   LEFT JOIN catalog_returns cr
      ON cs.cs_order_number = cr.cr_order_number
   UNION ALL
   SELECT d.d_year AS year,
          NULL AS state,
          ws.ws_net_paid AS sales,
          wr.wr_return_amt AS returns,
          ws.ws_net_profit AS profit
   FROM web_sales ws
   JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
   LEFT JOIN web_returns wr
      ON ws.ws_order_number = wr.wr_order_number
)
SELECT
   year,
   state,
   SUM(sales) AS total_sales,
   SUM(returns) AS total_returns,
   (SUM(sales) - SUM(returns)) AS net_revenue,
   SUM(profit) AS total_profit
FROM unified
GROUP BY year, state
ORDER BY year, state
