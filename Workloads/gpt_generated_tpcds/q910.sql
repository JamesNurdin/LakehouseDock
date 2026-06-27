WITH store_sales_state AS (
    SELECT
        ca.ca_state AS state,
        SUM(ss.ss_net_profit) AS store_net_profit,
        SUM(ss.ss_ext_discount_amt) AS store_discount,
        COUNT(DISTINCT ss.ss_customer_sk) AS store_customers
    FROM store_sales ss
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    GROUP BY ca.ca_state
),
catalog_sales_state AS (
    SELECT
        ca.ca_state AS state,
        SUM(cs.cs_net_profit) AS catalog_net_profit,
        SUM(cs.cs_ext_discount_amt) AS catalog_discount,
        COUNT(DISTINCT cs.cs_bill_customer_sk) AS catalog_customers
    FROM catalog_sales cs
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    GROUP BY ca.ca_state
),
web_sales_state AS (
    SELECT
        ca.ca_state AS state,
        SUM(ws.ws_net_profit) AS web_net_profit,
        SUM(ws.ws_ext_discount_amt) AS web_discount,
        COUNT(DISTINCT ws.ws_bill_customer_sk) AS web_customers
    FROM web_sales ws
    JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
    GROUP BY ca.ca_state
),
store_returns_state AS (
    SELECT
        ca.ca_state AS state,
        SUM(sr.sr_net_loss) AS store_return_loss,
        COUNT(DISTINCT sr.sr_customer_sk) AS store_return_customers
    FROM store_returns sr
    JOIN store_sales ss
        ON sr.sr_ticket_number = ss.ss_ticket_number
       AND sr.sr_item_sk = ss.ss_item_sk
    JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    GROUP BY ca.ca_state
),
catalog_returns_state AS (
    SELECT
        ca.ca_state AS state,
        SUM(cr.cr_net_loss) AS catalog_return_loss,
        COUNT(DISTINCT cr.cr_refunded_customer_sk) AS catalog_return_customers
    FROM catalog_returns cr
    JOIN catalog_sales cs
        ON cr.cr_order_number = cs.cs_order_number
       AND cr.cr_item_sk = cs.cs_item_sk
    JOIN customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    GROUP BY ca.ca_state
)
SELECT
    COALESCE(ss.state, cs.state, ws.state, sr.state, cr.state) AS state,
    COALESCE(ss.store_net_profit, 0) + COALESCE(cs.catalog_net_profit, 0) + COALESCE(ws.web_net_profit, 0) AS total_net_profit,
    COALESCE(sr.store_return_loss, 0) + COALESCE(cr.catalog_return_loss, 0) AS total_net_loss,
    COALESCE(ss.store_customers, 0) + COALESCE(cs.catalog_customers, 0) + COALESCE(ws.web_customers, 0) AS total_customers,
    COALESCE(ss.store_discount, 0) + COALESCE(cs.catalog_discount, 0) + COALESCE(ws.web_discount, 0) AS total_discount_amount
FROM store_sales_state ss
FULL OUTER JOIN catalog_sales_state cs ON ss.state = cs.state
FULL OUTER JOIN web_sales_state ws ON COALESCE(ss.state, cs.state) = ws.state
FULL OUTER JOIN store_returns_state sr ON COALESCE(ss.state, cs.state, ws.state) = sr.state
FULL OUTER JOIN catalog_returns_state cr ON COALESCE(ss.state, cs.state, ws.state, sr.state) = cr.state
ORDER BY total_net_profit DESC
LIMIT 20
