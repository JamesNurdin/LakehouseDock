WITH profit_loss AS (
    -- Store sales (profit)
    SELECT ca.ca_state AS state,
           ss.ss_net_profit AS amount
    FROM store_sales ss
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    WHERE ca.ca_state IS NOT NULL

    UNION ALL
    -- Catalog sales (profit)
    SELECT ca.ca_state,
           cs.cs_net_profit
    FROM catalog_sales cs
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    WHERE ca.ca_state IS NOT NULL

    UNION ALL
    -- Web sales (profit)
    SELECT ca.ca_state,
           ws.ws_net_profit
    FROM web_sales ws
    JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
    WHERE ca.ca_state IS NOT NULL

    UNION ALL
    -- Store returns (loss)
    SELECT ca.ca_state,
           -sr.sr_net_loss
    FROM store_returns sr
    JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    WHERE ca.ca_state IS NOT NULL

    UNION ALL
    -- Catalog returns (loss)
    SELECT ca.ca_state,
           -cr.cr_net_loss
    FROM catalog_returns cr
    JOIN customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    WHERE ca.ca_state IS NOT NULL

    UNION ALL
    -- Web returns (loss)
    SELECT ca.ca_state,
           -wr.wr_net_loss
    FROM web_returns wr
    JOIN customer_address ca ON wr.wr_refunded_addr_sk = ca.ca_address_sk
    WHERE ca.ca_state IS NOT NULL
)
SELECT state,
       SUM(CASE WHEN amount >= 0 THEN amount END) AS total_profit,
       SUM(CASE WHEN amount < 0 THEN -amount END) AS total_loss,
       SUM(amount) AS net_contribution
FROM profit_loss
GROUP BY state
HAVING SUM(amount) IS NOT NULL
ORDER BY net_contribution DESC
LIMIT 10
