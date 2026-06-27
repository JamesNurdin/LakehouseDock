WITH
    store_sales_agg AS (
        SELECT
            ca.ca_state AS state,
            SUM(ss.ss_net_profit) AS store_net_profit,
            COUNT(*) AS store_sales_cnt
        FROM store_sales ss
        JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
        JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
        GROUP BY ca.ca_state
    ),
    store_returns_agg AS (
        SELECT
            ca.ca_state AS state,
            SUM(sr.sr_net_loss) AS store_net_loss,
            COUNT(*) AS store_returns_cnt
        FROM store_returns sr
        JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
        JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
        GROUP BY ca.ca_state
    ),
    catalog_sales_agg AS (
        SELECT
            ca.ca_state AS state,
            SUM(cs.cs_net_profit) AS catalog_net_profit,
            COUNT(*) AS catalog_sales_cnt
        FROM catalog_sales cs
        JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
        JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
        GROUP BY ca.ca_state
    ),
    catalog_returns_agg AS (
        SELECT
            ca.ca_state AS state,
            SUM(cr.cr_net_loss) AS catalog_net_loss,
            COUNT(*) AS catalog_returns_cnt
        FROM catalog_returns cr
        JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
        JOIN customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
        GROUP BY ca.ca_state
    ),
    web_sales_agg AS (
        SELECT
            ca.ca_state AS state,
            SUM(ws.ws_net_profit) AS web_net_profit,
            COUNT(*) AS web_sales_cnt
        FROM web_sales ws
        JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
        JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
        GROUP BY ca.ca_state
    ),
    web_returns_agg AS (
        SELECT
            ca.ca_state AS state,
            SUM(wr.wr_net_loss) AS web_net_loss,
            COUNT(*) AS web_returns_cnt
        FROM web_returns wr
        JOIN customer c ON wr.wr_refunded_customer_sk = c.c_customer_sk
        JOIN customer_address ca ON wr.wr_refunded_addr_sk = ca.ca_address_sk
        GROUP BY ca.ca_state
    ),
    states AS (
        SELECT state FROM store_sales_agg
        UNION
        SELECT state FROM store_returns_agg
        UNION
        SELECT state FROM catalog_sales_agg
        UNION
        SELECT state FROM catalog_returns_agg
        UNION
        SELECT state FROM web_sales_agg
        UNION
        SELECT state FROM web_returns_agg
    )
SELECT
    s.state,
    COALESCE(ssa.store_net_profit, 0) AS store_net_profit,
    COALESCE(sra.store_net_loss, 0) AS store_net_loss,
    COALESCE(csa.catalog_net_profit, 0) AS catalog_net_profit,
    COALESCE(cra.catalog_net_loss, 0) AS catalog_net_loss,
    COALESCE(wsa.web_net_profit, 0) AS web_net_profit,
    COALESCE(wra.web_net_loss, 0) AS web_net_loss,
    (COALESCE(ssa.store_net_profit, 0) + COALESCE(csa.catalog_net_profit, 0) + COALESCE(wsa.web_net_profit, 0)
     - COALESCE(sra.store_net_loss, 0) - COALESCE(cra.catalog_net_loss, 0) - COALESCE(wra.web_net_loss, 0)) AS total_net_profit
FROM states s
LEFT JOIN store_sales_agg ssa ON s.state = ssa.state
LEFT JOIN store_returns_agg sra ON s.state = sra.state
LEFT JOIN catalog_sales_agg csa ON s.state = csa.state
LEFT JOIN catalog_returns_agg cra ON s.state = cra.state
LEFT JOIN web_sales_agg wsa ON s.state = wsa.state
LEFT JOIN web_returns_agg wra ON s.state = wra.state
ORDER BY total_net_profit DESC
LIMIT 10
