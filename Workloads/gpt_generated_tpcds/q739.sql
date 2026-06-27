WITH combined AS (
    SELECT ca.ca_state AS state,
           ss.ss_net_profit AS profit,
           0.0 AS loss
    FROM store_sales ss
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk

    UNION ALL

    SELECT ca.ca_state AS state,
           0.0 AS profit,
           sr.sr_net_loss AS loss
    FROM store_returns sr
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk

    UNION ALL

    SELECT ca.ca_state AS state,
           cs.cs_net_profit AS profit,
           0.0 AS loss
    FROM catalog_sales cs
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk

    UNION ALL

    SELECT ca.ca_state AS state,
           0.0 AS profit,
           cr.cr_net_loss AS loss
    FROM catalog_returns cr
    JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk

    UNION ALL

    SELECT ca.ca_state AS state,
           ws.ws_net_profit AS profit,
           0.0 AS loss
    FROM web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk

    UNION ALL

    SELECT ca.ca_state AS state,
           0.0 AS profit,
           wr.wr_net_loss AS loss
    FROM web_returns wr
    JOIN customer c ON wr.wr_refunded_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON wr.wr_refunded_addr_sk = ca.ca_address_sk
)
SELECT
    state,
    sum(profit) AS total_sales_profit,
    sum(loss) AS total_returns_loss,
    sum(profit) - sum(loss) AS net_profit_after_returns
FROM combined
GROUP BY state
ORDER BY net_profit_after_returns DESC
LIMIT 20
