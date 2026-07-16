WITH non_returned_sales AS (
    SELECT
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_net_profit,
        ws.ws_ship_mode_sk,
        ws.ws_bill_addr_sk,
        ws.ws_bill_customer_sk,
        ws.ws_web_page_sk
    FROM web_sales ws
    LEFT JOIN web_returns wr
        ON ws.ws_order_number = wr.wr_order_number
        AND ws.ws_item_sk = wr.wr_item_sk
    WHERE wr.wr_order_number IS NULL
      AND ws.ws_quantity > 5
)
SELECT
    ca.ca_state,
    sm.sm_type,
    COUNT(DISTINCT nrs.ws_order_number) AS order_count,
    SUM(nrs.ws_net_profit) AS total_web_net_profit,
    SUM(COALESCE(cr.cr_net_loss, 0)) AS total_catalog_net_loss,
    AVG(nrs.ws_net_profit) AS avg_web_net_profit,
    RANK() OVER (PARTITION BY ca.ca_state ORDER BY SUM(nrs.ws_net_profit) DESC) AS profit_rank
FROM non_returned_sales nrs
JOIN customer c
    ON nrs.ws_bill_customer_sk = c.c_customer_sk
JOIN customer_address ca
    ON nrs.ws_bill_addr_sk = ca.ca_address_sk
JOIN ship_mode sm
    ON nrs.ws_ship_mode_sk = sm.sm_ship_mode_sk
JOIN web_page wp
    ON nrs.ws_web_page_sk = wp.wp_web_page_sk
LEFT JOIN catalog_returns cr
    ON cr.cr_returning_customer_sk = c.c_customer_sk
   AND cr.cr_returning_addr_sk = ca.ca_address_sk
   AND cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
WHERE (cr.cr_return_quantity IS NULL OR cr.cr_return_quantity IN (29, 42, 27))
  AND wp.wp_type = 'product'
GROUP BY ca.ca_state, sm.sm_type
HAVING SUM(nrs.ws_net_profit) > 1000
ORDER BY ca.ca_state, total_web_net_profit DESC
