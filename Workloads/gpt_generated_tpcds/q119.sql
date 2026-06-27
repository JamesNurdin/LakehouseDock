WITH store_ret AS (
    SELECT ca.ca_state AS state,
           sr.sr_net_loss AS net_loss,
           ss.ss_net_profit AS original_net_profit
    FROM store_returns sr
    JOIN store_sales ss
      ON sr.sr_ticket_number = ss.ss_ticket_number
     AND sr.sr_item_sk = ss.ss_item_sk
    JOIN customer_address ca
      ON sr.sr_addr_sk = ca.ca_address_sk
),
web_ret AS (
    SELECT ca.ca_state AS state,
           wr.wr_net_loss AS net_loss,
           ws.ws_net_profit AS original_net_profit
    FROM web_returns wr
    JOIN web_sales ws
      ON wr.wr_order_number = ws.ws_order_number
     AND wr.wr_item_sk = ws.ws_item_sk
    JOIN customer_address ca
      ON wr.wr_returning_addr_sk = ca.ca_address_sk
),
catalog_ret AS (
    SELECT ca.ca_state AS state,
           cr.cr_net_loss AS net_loss,
           CAST(NULL AS decimal(7,2)) AS original_net_profit
    FROM catalog_returns cr
    JOIN customer_address ca
      ON cr.cr_returning_addr_sk = ca.ca_address_sk
)
SELECT state,
       COUNT(*) AS total_returns,
       SUM(net_loss) AS total_net_loss,
       SUM(original_net_profit) AS total_original_net_profit,
       CASE WHEN SUM(original_net_profit) = 0 THEN NULL
            ELSE SUM(net_loss) / SUM(original_net_profit)
       END AS loss_to_profit_ratio
FROM (
    SELECT state, net_loss, original_net_profit FROM store_ret
    UNION ALL
    SELECT state, net_loss, original_net_profit FROM web_ret
    UNION ALL
    SELECT state, net_loss, original_net_profit FROM catalog_ret
) all_returns
GROUP BY state
ORDER BY total_net_loss DESC
LIMIT 20
