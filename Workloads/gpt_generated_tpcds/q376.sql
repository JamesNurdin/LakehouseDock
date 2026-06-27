WITH store_data AS (
  SELECT d.d_year AS year,
         SUM(ss.ss_net_profit) AS sales_profit,
         SUM(COALESCE(sr.sr_net_loss, 0)) AS returns_loss
  FROM store_sales ss
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
  JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
  LEFT JOIN store_returns sr
    ON ss.ss_ticket_number = sr.sr_ticket_number
   AND ss.ss_item_sk = sr.sr_item_sk
  WHERE ca.ca_state = 'CA'
    AND cd.cd_gender = 'M'
  GROUP BY d.d_year
),
catalog_data AS (
  SELECT d.d_year AS year,
         SUM(cs.cs_net_profit) AS sales_profit,
         SUM(COALESCE(cr.cr_net_loss, 0)) AS returns_loss
  FROM catalog_sales cs
  JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
  JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
  JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
  LEFT JOIN catalog_returns cr
    ON cs.cs_order_number = cr.cr_order_number
   AND cs.cs_item_sk = cr.cr_item_sk
  WHERE ca.ca_state = 'CA'
    AND cd.cd_gender = 'M'
  GROUP BY d.d_year
),
web_data AS (
  SELECT d.d_year AS year,
         SUM(ws.ws_net_profit) AS sales_profit,
         SUM(COALESCE(wr.wr_net_loss, 0)) AS returns_loss
  FROM web_sales ws
  JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
  JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
  JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
  LEFT JOIN web_returns wr
    ON ws.ws_order_number = wr.wr_order_number
   AND ws.ws_item_sk = wr.wr_item_sk
  WHERE ca.ca_state = 'CA'
    AND cd.cd_gender = 'M'
  GROUP BY d.d_year
),
combined AS (
  SELECT year, 'Store'   AS channel, sales_profit, returns_loss FROM store_data
  UNION ALL
  SELECT year, 'Catalog' AS channel, sales_profit, returns_loss FROM catalog_data
  UNION ALL
  SELECT year, 'Web'     AS channel, sales_profit, returns_loss FROM web_data
)
SELECT year,
       channel,
       SUM(sales_profit) - SUM(returns_loss) AS net_profit
FROM combined
GROUP BY year, channel
ORDER BY year, channel
