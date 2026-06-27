WITH store_agg AS (
    SELECT
        c.c_customer_sk,
        ca.ca_state,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_order_count,
        SUM(ss.ss_net_paid) AS store_net_paid,
        SUM(ss.ss_net_profit) AS store_net_profit
    FROM store_sales ss
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    GROUP BY c.c_customer_sk, ca.ca_state
),
catalog_agg AS (
    SELECT
        c.c_customer_sk,
        ca.ca_state,
        COUNT(DISTINCT cs.cs_order_number) AS catalog_order_count,
        SUM(cs.cs_net_paid) AS catalog_net_paid,
        SUM(cs.cs_net_profit) AS catalog_net_profit
    FROM catalog_sales cs
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    GROUP BY c.c_customer_sk, ca.ca_state
),
returns_agg AS (
    SELECT
        c.c_customer_sk,
        ca.ca_state,
        SUM(cr.cr_net_loss) AS total_return_loss,
        COUNT(*) AS return_count
    FROM catalog_returns cr
    JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    GROUP BY c.c_customer_sk, ca.ca_state
),
web_agg AS (
    SELECT
        c.c_customer_sk,
        ca.ca_state,
        COUNT(DISTINCT ws.ws_order_number) AS web_order_count,
        SUM(ws.ws_net_paid) AS web_net_paid,
        SUM(ws.ws_net_profit) AS web_net_profit
    FROM web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
    GROUP BY c.c_customer_sk, ca.ca_state
)
SELECT
    COALESCE(s.c_customer_sk, ca.c_customer_sk, w.c_customer_sk, r.c_customer_sk) AS customer_sk,
    COALESCE(s.ca_state, ca.ca_state, w.ca_state, r.ca_state) AS state,
    COALESCE(s.store_order_count, 0) + COALESCE(ca.catalog_order_count, 0) + COALESCE(w.web_order_count, 0) AS total_orders,
    COALESCE(s.store_net_paid, 0) + COALESCE(ca.catalog_net_paid, 0) + COALESCE(w.web_net_paid, 0) AS total_net_paid,
    COALESCE(s.store_net_profit, 0) + COALESCE(ca.catalog_net_profit, 0) + COALESCE(w.web_net_profit, 0) AS total_net_profit,
    COALESCE(r.total_return_loss, 0) AS total_return_loss,
    (COALESCE(s.store_net_profit, 0) + COALESCE(ca.catalog_net_profit, 0) + COALESCE(w.web_net_profit, 0) - COALESCE(r.total_return_loss, 0))
        / NULLIF(COALESCE(s.store_order_count, 0) + COALESCE(ca.catalog_order_count, 0) + COALESCE(w.web_order_count, 0), 0) AS avg_profit_per_order
FROM store_agg s
FULL OUTER JOIN catalog_agg ca ON s.c_customer_sk = ca.c_customer_sk AND s.ca_state = ca.ca_state
FULL OUTER JOIN web_agg w ON COALESCE(s.c_customer_sk, ca.c_customer_sk) = w.c_customer_sk AND COALESCE(s.ca_state, ca.ca_state) = w.ca_state
FULL OUTER JOIN returns_agg r ON COALESCE(s.c_customer_sk, ca.c_customer_sk, w.c_customer_sk) = r.c_customer_sk AND COALESCE(s.ca_state, ca.ca_state, w.ca_state) = r.ca_state
ORDER BY total_net_paid DESC
LIMIT 100
