WITH sales AS (
    SELECT d.d_year AS year,
           ca.ca_state AS state,
           ss.ss_net_profit AS net_profit
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
    UNION ALL
    SELECT d.d_year,
           ca.ca_state,
           ws.ws_net_profit
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
    UNION ALL
    SELECT d.d_year,
           ca.ca_state,
           cs.cs_net_profit
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
),
returns AS (
    SELECT d.d_year AS year,
           ca.ca_state AS state,
           -sr.sr_net_loss AS net_profit
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
    UNION ALL
    SELECT d.d_year,
           ca.ca_state,
           -wr.wr_net_loss
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN customer_address ca ON wr.wr_refunded_addr_sk = ca.ca_address_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
    UNION ALL
    SELECT d.d_year,
           ca.ca_state,
           -cr.cr_net_loss
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
)
SELECT year,
       state,
       sum(net_profit) AS total_net_profit
FROM (
    SELECT * FROM sales
    UNION ALL
    SELECT * FROM returns
) t
GROUP BY year, state
ORDER BY year, state
