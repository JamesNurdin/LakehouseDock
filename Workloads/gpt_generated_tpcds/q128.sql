WITH
    store_sales_by_state AS (
        SELECT
            ca.ca_state,
            SUM(ss.ss_net_profit) AS total_store_profit,
            COUNT(*) AS store_sales_cnt
        FROM store_sales ss
        JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
        JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
        GROUP BY ca.ca_state
    ),
    store_returns_by_state AS (
        SELECT
            ca.ca_state,
            SUM(sr.sr_net_loss) AS total_store_loss,
            COUNT(*) AS store_returns_cnt
        FROM store_returns sr
        JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
        JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
        GROUP BY ca.ca_state
    ),
    web_sales_by_state AS (
        SELECT
            ca.ca_state,
            SUM(ws.ws_net_profit) AS total_web_profit,
            COUNT(*) AS web_sales_cnt
        FROM web_sales ws
        JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
        JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
        GROUP BY ca.ca_state
    ),
    web_returns_by_state AS (
        SELECT
            ca.ca_state,
            SUM(wr.wr_net_loss) AS total_web_loss,
            COUNT(*) AS web_returns_cnt
        FROM web_returns wr
        JOIN customer c ON wr.wr_refunded_customer_sk = c.c_customer_sk
        JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
        GROUP BY ca.ca_state
    )
SELECT
    COALESCE(ss.ca_state, sr.ca_state, ws.ca_state, wr.ca_state) AS state,
    COALESCE(ss.total_store_profit, 0) - COALESCE(sr.total_store_loss, 0) AS net_store_profit,
    COALESCE(ws.total_web_profit, 0) - COALESCE(wr.total_web_loss, 0) AS net_web_profit,
    (COALESCE(ss.total_store_profit, 0) - COALESCE(sr.total_store_loss, 0)) +
    (COALESCE(ws.total_web_profit, 0) - COALESCE(wr.total_web_loss, 0)) AS total_net_profit,
    COALESCE(ss.store_sales_cnt, 0) AS store_sales_cnt,
    COALESCE(sr.store_returns_cnt, 0) AS store_returns_cnt,
    COALESCE(ws.web_sales_cnt, 0) AS web_sales_cnt,
    COALESCE(wr.web_returns_cnt, 0) AS web_returns_cnt
FROM store_sales_by_state ss
FULL OUTER JOIN store_returns_by_state sr ON ss.ca_state = sr.ca_state
FULL OUTER JOIN web_sales_by_state ws ON COALESCE(ss.ca_state, sr.ca_state) = ws.ca_state
FULL OUTER JOIN web_returns_by_state wr ON COALESCE(ss.ca_state, sr.ca_state, ws.ca_state) = wr.ca_state
ORDER BY total_net_profit DESC
LIMIT 20
