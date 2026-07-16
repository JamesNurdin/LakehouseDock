WITH sales AS (
    SELECT 'Catalog' AS channel,
           d.d_year,
           i.i_category,
           ca.ca_country,
           SUM(cs.cs_net_profit) AS net_profit
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
    GROUP BY 1,2,3,4
    UNION ALL
    SELECT 'Store' AS channel,
           d.d_year,
           i.i_category,
           ca.ca_country,
           SUM(ss.ss_net_profit) AS net_profit
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
    GROUP BY 1,2,3,4
    UNION ALL
    SELECT 'Web' AS channel,
           d.d_year,
           i.i_category,
           ca.ca_country,
           SUM(ws.ws_net_profit) AS net_profit
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
    GROUP BY 1,2,3,4
), returns AS (
    SELECT 'Catalog' AS channel,
           d.d_year,
           i.i_category,
           ca.ca_country,
           SUM(cr.cr_net_loss) AS net_loss
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
    GROUP BY 1,2,3,4
    UNION ALL
    SELECT 'Store' AS channel,
           d.d_year,
           i.i_category,
           ca.ca_country,
           SUM(sr.sr_net_loss) AS net_loss
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
    GROUP BY 1,2,3,4
    UNION ALL
    SELECT 'Web' AS channel,
           d.d_year,
           i.i_category,
           ca.ca_country,
           SUM(wr.wr_net_loss) AS net_loss
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    JOIN customer c ON wr.wr_refunded_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
    GROUP BY 1,2,3,4
)
SELECT s.channel,
       s.d_year,
       s.i_category,
       s.ca_country,
       s.net_profit - COALESCE(r.net_loss, 0) AS net_gain
FROM sales s
LEFT JOIN returns r
    ON s.channel = r.channel
   AND s.d_year = r.d_year
   AND s.i_category = r.i_category
   AND s.ca_country = r.ca_country
ORDER BY net_gain DESC
LIMIT 100
