WITH store_ret AS (
    SELECT
        s.s_state AS state,
        i.i_category AS category,
        SUM(sr.sr_net_loss) AS total_store_loss,
        COUNT(DISTINCT sr.sr_ticket_number) AS return_cnt
    FROM store_returns sr
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    WHERE ca.ca_street_number LIKE '3%'
      AND regexp_like(i.i_product_name, '\\d')
    GROUP BY s.s_state, i.i_category
),
web_sales_agg AS (
    SELECT
        ca.ca_state AS state,
        i.i_category AS category,
        SUM(ws.ws_net_profit) AS total_web_profit,
        COUNT(DISTINCT ws.ws_order_number) AS sales_cnt
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
    WHERE ca.ca_street_number LIKE '3%'
      AND regexp_like(i.i_product_name, '\\d')
      AND ws.ws_net_profit > 0
    GROUP BY ca.ca_state, i.i_category
)
SELECT
    COALESCE(sr.state, ws.state) AS state,
    sr.category,
    sr.total_store_loss,
    sr.return_cnt,
    ws.total_web_profit,
    ws.sales_cnt,
    concat(sr.category, ' - ', COALESCE(sr.state, ws.state)) AS category_state_key
FROM store_ret sr
FULL OUTER JOIN web_sales_agg ws
    ON sr.state = ws.state
   AND sr.category = ws.category
WHERE regexp_like(COALESCE(sr.state, ws.state), '^[A-Z]{2}$')
ORDER BY sr.total_store_loss DESC NULLS LAST, ws.total_web_profit DESC NULLS LAST
LIMIT 100
