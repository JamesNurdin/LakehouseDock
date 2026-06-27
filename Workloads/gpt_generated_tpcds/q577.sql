WITH store_sales_profit AS (
    SELECT d.d_year AS year,
           ca.ca_state AS state,
           SUM(ss.ss_net_profit) AS profit,
           CAST(0 AS decimal(7,2)) AS loss
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    GROUP BY d.d_year, ca.ca_state
),
store_returns_loss AS (
    SELECT d.d_year AS year,
           ca.ca_state AS state,
           CAST(0 AS decimal(7,2)) AS profit,
           SUM(sr.sr_net_loss) AS loss
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    GROUP BY d.d_year, ca.ca_state
),
catalog_sales_profit AS (
    SELECT d.d_year AS year,
           ca.ca_state AS state,
           SUM(cs.cs_net_profit) AS profit,
           CAST(0 AS decimal(7,2)) AS loss
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    GROUP BY d.d_year, ca.ca_state
),
web_sales_profit AS (
    SELECT d.d_year AS year,
           ca.ca_state AS state,
           SUM(ws.ws_net_profit) AS profit,
           CAST(0 AS decimal(7,2)) AS loss
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
    GROUP BY d.d_year, ca.ca_state
),
web_returns_loss AS (
    SELECT d.d_year AS year,
           ca.ca_state AS state,
           CAST(0 AS decimal(7,2)) AS profit,
           SUM(wr.wr_net_loss) AS loss
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN customer_address ca ON wr.wr_refunded_addr_sk = ca.ca_address_sk
    GROUP BY d.d_year, ca.ca_state
),
combined AS (
    SELECT year, state, profit, loss FROM store_sales_profit
    UNION ALL
    SELECT year, state, profit, loss FROM store_returns_loss
    UNION ALL
    SELECT year, state, profit, loss FROM catalog_sales_profit
    UNION ALL
    SELECT year, state, profit, loss FROM web_sales_profit
    UNION ALL
    SELECT year, state, profit, loss FROM web_returns_loss
)
SELECT year,
       state,
       SUM(profit) AS total_profit,
       SUM(loss) AS total_loss,
       SUM(profit) - SUM(loss) AS net_profit
FROM combined
GROUP BY year, state
ORDER BY net_profit DESC
LIMIT 20
