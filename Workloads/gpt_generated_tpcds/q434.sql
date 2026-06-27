WITH
    sales_by_state AS (
        -- Store channel sales
        SELECT
            ca.ca_state AS state,
            SUM(ss.ss_net_paid) AS total_sales,
            SUM(ss.ss_net_profit) AS total_profit
        FROM store_sales ss
        JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
        JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
        GROUP BY ca.ca_state

        UNION ALL

        -- Catalog channel sales (using billing address as the location)
        SELECT
            ca.ca_state AS state,
            SUM(cs.cs_net_paid) AS total_sales,
            SUM(cs.cs_net_profit) AS total_profit
        FROM catalog_sales cs
        JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
        JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
        GROUP BY ca.ca_state

        UNION ALL

        -- Web channel sales (using billing address as the location)
        SELECT
            ca.ca_state AS state,
            SUM(ws.ws_net_paid) AS total_sales,
            SUM(ws.ws_net_profit) AS total_profit
        FROM web_sales ws
        JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
        JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
        GROUP BY ca.ca_state
    ),
    aggregated_sales AS (
        SELECT
            state,
            SUM(total_sales) AS total_sales,
            SUM(total_profit) AS total_profit
        FROM sales_by_state
        GROUP BY state
    ),
    returns_by_state AS (
        -- Store channel returns
        SELECT
            ca.ca_state AS state,
            SUM(sr.sr_net_loss) AS total_return_loss
        FROM store_returns sr
        JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
        JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
        GROUP BY ca.ca_state

        UNION ALL

        -- Catalog channel returns (using refunded address as the location)
        SELECT
            ca.ca_state AS state,
            SUM(cr.cr_net_loss) AS total_return_loss
        FROM catalog_returns cr
        JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
        JOIN customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
        GROUP BY ca.ca_state

        UNION ALL

        -- Web channel returns (using refunded address as the location)
        SELECT
            ca.ca_state AS state,
            SUM(wr.wr_net_loss) AS total_return_loss
        FROM web_returns wr
        JOIN customer c ON wr.wr_refunded_customer_sk = c.c_customer_sk
        JOIN customer_address ca ON wr.wr_refunded_addr_sk = ca.ca_address_sk
        GROUP BY ca.ca_state
    ),
    aggregated_returns AS (
        SELECT
            state,
            SUM(total_return_loss) AS total_return_loss
        FROM returns_by_state
        GROUP BY state
    )
SELECT
    s.state,
    s.total_sales,
    s.total_profit,
    COALESCE(r.total_return_loss, 0) AS total_return_loss,
    s.total_sales - COALESCE(r.total_return_loss, 0) AS net_revenue
FROM aggregated_sales s
LEFT JOIN aggregated_returns r ON s.state = r.state
ORDER BY net_revenue DESC
LIMIT 10
