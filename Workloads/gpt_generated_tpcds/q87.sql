WITH
    store_sales_agg AS (
        SELECT
            ca.ca_state AS state,
            SUM(ss.ss_net_profit) AS net_profit,
            CAST(0 AS decimal(7,2)) AS net_loss
        FROM store_sales ss
        JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
        GROUP BY ca.ca_state
    ),
    store_returns_agg AS (
        SELECT
            ca.ca_state AS state,
            CAST(0 AS decimal(7,2)) AS net_profit,
            SUM(sr.sr_net_loss) AS net_loss
        FROM store_returns sr
        JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
        GROUP BY ca.ca_state
    ),
    catalog_sales_agg AS (
        SELECT
            ca.ca_state AS state,
            SUM(cs.cs_net_profit) AS net_profit,
            CAST(0 AS decimal(7,2)) AS net_loss
        FROM catalog_sales cs
        JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
        GROUP BY ca.ca_state
    ),
    catalog_returns_agg AS (
        SELECT
            ca.ca_state AS state,
            CAST(0 AS decimal(7,2)) AS net_profit,
            SUM(cr.cr_net_loss) AS net_loss
        FROM catalog_returns cr
        JOIN customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
        GROUP BY ca.ca_state
    ),
    web_sales_agg AS (
        SELECT
            ca.ca_state AS state,
            SUM(ws.ws_net_profit) AS net_profit,
            CAST(0 AS decimal(7,2)) AS net_loss
        FROM web_sales ws
        JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
        GROUP BY ca.ca_state
    ),
    web_returns_agg AS (
        SELECT
            ca.ca_state AS state,
            CAST(0 AS decimal(7,2)) AS net_profit,
            SUM(wr.wr_net_loss) AS net_loss
        FROM web_returns wr
        JOIN customer_address ca ON wr.wr_refunded_addr_sk = ca.ca_address_sk
        GROUP BY ca.ca_state
    ),
    combined AS (
        SELECT
            state,
            SUM(net_profit) AS total_net_profit,
            SUM(net_loss)   AS total_net_loss
        FROM (
            SELECT state, net_profit, net_loss FROM store_sales_agg
            UNION ALL
            SELECT state, net_profit, net_loss FROM store_returns_agg
            UNION ALL
            SELECT state, net_profit, net_loss FROM catalog_sales_agg
            UNION ALL
            SELECT state, net_profit, net_loss FROM catalog_returns_agg
            UNION ALL
            SELECT state, net_profit, net_loss FROM web_sales_agg
            UNION ALL
            SELECT state, net_profit, net_loss FROM web_returns_agg
        ) agg
        GROUP BY state
    )
SELECT
    state,
    total_net_profit,
    total_net_loss,
    (total_net_profit - total_net_loss) AS net_contribution
FROM combined
ORDER BY net_contribution DESC
LIMIT 10
