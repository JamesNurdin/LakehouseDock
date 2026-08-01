WITH
    address_sales AS (
        SELECT
            ca.ca_address_sk,
            ca.ca_city,
            ca.ca_state,
            SUM(cs.cs_net_profit) AS total_net_profit
        FROM catalog_sales cs
        JOIN customer_address ca
            ON cs.cs_bill_addr_sk = ca.ca_address_sk
        GROUP BY ca.ca_address_sk, ca.ca_city, ca.ca_state
    ),
    address_store_returns AS (
        SELECT
            ca.ca_address_sk,
            SUM(sr.sr_net_loss) AS total_store_loss
        FROM store_returns sr
        JOIN customer_address ca
            ON sr.sr_addr_sk = ca.ca_address_sk
        GROUP BY ca.ca_address_sk
    ),
    address_web_returns AS (
        SELECT
            ca.ca_address_sk,
            SUM(wr.wr_net_loss) AS total_web_loss
        FROM web_returns wr
        JOIN customer_address ca
            ON wr.wr_refunded_addr_sk = ca.ca_address_sk
        GROUP BY ca.ca_address_sk
    ),
    union_all_returns AS (
        SELECT
            a.ca_address_sk,
            a.ca_city,
            a.ca_state,
            a.total_net_profit,
            COALESCE(s.total_store_loss, 0) AS total_return_loss,
            'store' AS return_type
        FROM address_sales a
        LEFT JOIN address_store_returns s
            ON a.ca_address_sk = s.ca_address_sk

        UNION ALL

        SELECT
            a.ca_address_sk,
            a.ca_city,
            a.ca_state,
            a.total_net_profit,
            COALESCE(w.total_web_loss, 0) AS total_return_loss,
            'web' AS return_type
        FROM address_sales a
        LEFT JOIN address_web_returns w
            ON a.ca_address_sk = w.ca_address_sk
    )
SELECT DISTINCT
    u.ca_address_sk,
    u.ca_city,
    u.ca_state,
    u.total_net_profit,
    u.total_return_loss,
    u.return_type,
    u.total_net_profit / (SELECT MAX(total_net_profit) FROM address_sales) AS profit_ratio,
    ROW_NUMBER() OVER (PARTITION BY u.ca_state ORDER BY u.total_net_profit DESC) AS state_profit_rank
FROM union_all_returns u
WHERE u.return_type = 'store'
  AND NOT EXISTS (
        SELECT 1
        FROM web_returns wr
        WHERE wr.wr_refunded_addr_sk = u.ca_address_sk
    )
ORDER BY profit_ratio DESC
LIMIT 100
