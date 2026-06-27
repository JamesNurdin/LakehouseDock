WITH sales_aggregated AS (
   -- Store channel aggregation
   SELECT
      d.d_year AS year,
      ib.ib_lower_bound AS income_lower,
      ib.ib_upper_bound AS income_upper,
      'store' AS channel,
      SUM(ss.ss_net_profit) AS sales_profit,
      SUM(COALESCE(sr.sr_net_loss, 0)) AS returns_loss
   FROM store_sales ss
   JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
   JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
   JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
   JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
   LEFT JOIN store_returns sr
     ON ss.ss_ticket_number = sr.sr_ticket_number
     AND ss.ss_item_sk = sr.sr_item_sk
   GROUP BY d.d_year, ib.ib_lower_bound, ib.ib_upper_bound

   UNION ALL

   -- Catalog channel aggregation
   SELECT
      d.d_year AS year,
      ib.ib_lower_bound AS income_lower,
      ib.ib_upper_bound AS income_upper,
      'catalog' AS channel,
      SUM(cs.cs_net_profit) AS sales_profit,
      SUM(COALESCE(cr.cr_net_loss, 0)) AS returns_loss
   FROM catalog_sales cs
   JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
   JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
   JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
   JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
   LEFT JOIN catalog_returns cr
     ON cs.cs_order_number = cr.cr_order_number
     AND cs.cs_item_sk = cr.cr_item_sk
   GROUP BY d.d_year, ib.ib_lower_bound, ib.ib_upper_bound

   UNION ALL

   -- Web channel aggregation
   SELECT
      d.d_year AS year,
      ib.ib_lower_bound AS income_lower,
      ib.ib_upper_bound AS income_upper,
      'web' AS channel,
      SUM(ws.ws_net_profit) AS sales_profit,
      SUM(COALESCE(wr.wr_net_loss, 0)) AS returns_loss
   FROM web_sales ws
   JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
   JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
   JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
   JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
   LEFT JOIN web_returns wr
     ON ws.ws_order_number = wr.wr_order_number
     AND ws.ws_item_sk = wr.wr_item_sk
   GROUP BY d.d_year, ib.ib_lower_bound, ib.ib_upper_bound
)
SELECT
   year,
   income_lower,
   income_upper,
   channel,
   sales_profit,
   returns_loss,
   (sales_profit - returns_loss) AS net_profit
FROM sales_aggregated
ORDER BY year, income_lower, channel
