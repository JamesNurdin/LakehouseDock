SELECT
    d.d_year AS year,
    i.i_category AS category,
    COALESCE(s.s_state, cc.cc_state, w.w_state) AS state,
    SUM(f.net_profit) AS total_profit,
    SUM(f.net_paid) AS total_paid,
    COUNT(DISTINCT f.order_number) AS order_cnt
FROM (
    SELECT ss_sold_date_sk AS sold_date_sk,
           ss_item_sk AS item_sk,
           ss_store_sk AS loc_sk,
           ss_ticket_number AS order_number,
           ss_net_profit AS net_profit,
           ss_net_paid AS net_paid,
           'store' AS source
    FROM store_sales
    UNION ALL
    SELECT cs_sold_date_sk,
           cs_item_sk,
           cs_call_center_sk,
           cs_order_number,
           cs_net_profit,
           cs_net_paid,
           'catalog' AS source
    FROM catalog_sales
    UNION ALL
    SELECT ws_sold_date_sk,
           ws_item_sk,
           ws_warehouse_sk,
           ws_order_number,
           ws_net_profit,
           ws_net_paid,
           'web' AS source
    FROM web_sales
) f
JOIN date_dim d ON f.sold_date_sk = d.d_date_sk
JOIN item i ON f.item_sk = i.i_item_sk
LEFT JOIN store s ON f.source = 'store' AND f.loc_sk = s.s_store_sk
LEFT JOIN call_center cc ON f.source = 'catalog' AND f.loc_sk = cc.cc_call_center_sk
LEFT JOIN warehouse w ON f.source = 'web' AND f.loc_sk = w.w_warehouse_sk
WHERE d.d_year = 2001
GROUP BY d.d_year, i.i_category, COALESCE(s.s_state, cc.cc_state, w.w_state)
ORDER BY total_profit DESC
LIMIT 100
