WITH all_sales AS (
    SELECT
        ss.ss_sold_date_sk AS sold_date_sk,
        ss.ss_store_sk AS store_sk,
        ss.ss_item_sk AS item_sk,
        ss.ss_quantity AS quantity,
        ss.ss_net_profit AS net_profit,
        ss.ss_net_paid AS net_paid,
        ss.ss_ticket_number AS ticket_number,
        ss.ss_promo_sk AS promo_sk
    FROM store_sales ss
    UNION ALL
    SELECT
        ws.ws_sold_date_sk,
        NULL,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_net_profit,
        ws.ws_net_paid,
        ws.ws_order_number,
        ws.ws_promo_sk
    FROM web_sales ws
    UNION ALL
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_call_center_sk,
        cs.cs_item_sk,
        cs.cs_quantity,
        cs.cs_net_profit,
        cs.cs_net_paid,
        cs.cs_order_number,
        cs.cs_promo_sk
    FROM catalog_sales cs
)
SELECT
    d.d_year,
    COALESCE(s.s_state, cc.cc_state, 'Online') AS channel_state,
    i.i_category,
    SUM(all_sales.quantity) AS total_quantity,
    SUM(all_sales.net_profit) AS total_profit,
    COUNT(DISTINCT all_sales.ticket_number) AS distinct_orders
FROM all_sales
JOIN date_dim d ON all_sales.sold_date_sk = d.d_date_sk
JOIN item i ON all_sales.item_sk = i.i_item_sk
LEFT JOIN store s ON all_sales.store_sk = s.s_store_sk
LEFT JOIN call_center cc ON all_sales.store_sk = cc.cc_call_center_sk
WHERE d.d_year BETWEEN 1999 AND 2002
GROUP BY d.d_year,
         COALESCE(s.s_state, cc.cc_state, 'Online'),
         i.i_category
ORDER BY total_profit DESC
LIMIT 200
