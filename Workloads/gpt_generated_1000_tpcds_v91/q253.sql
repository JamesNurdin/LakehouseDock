WITH agg AS (
    SELECT 
        i.i_item_id,
        s.s_store_id,
        s.s_state,
        i.i_current_price,
        p_ss.p_promo_id,
        SUM(ss.ss_ext_sales_price) AS total_store_sales,
        SUM(ss.ss_net_profit) AS total_store_profit,
        COALESCE(SUM(sr.sr_return_amt), 0) AS total_store_returns,
        COALESCE(SUM(ws.ws_ext_sales_price), 0) AS total_web_sales,
        COALESCE(SUM(ws.ws_net_profit), 0) AS total_web_profit,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_sales_txns,
        COUNT(DISTINCT ws.ws_order_number) AS web_sales_orders,
        COUNT(DISTINCT sr.sr_ticket_number) AS return_txns
    FROM item i
    JOIN store_sales ss ON ss.ss_item_sk = i.i_item_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN promotion p_ss ON ss.ss_promo_sk = p_ss.p_promo_sk
    JOIN household_demographics hd_ss ON ss.ss_hdemo_sk = hd_ss.hd_demo_sk
    LEFT JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
                              AND sr.sr_item_sk = i.i_item_sk
    LEFT JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
    LEFT JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    LEFT JOIN warehouse w_ws ON ws.ws_warehouse_sk = w_ws.w_warehouse_sk
    LEFT JOIN promotion p_ws ON ws.ws_promo_sk = p_ws.p_promo_sk
    LEFT JOIN catalog_returns cr ON cr.cr_item_sk = i.i_item_sk
    LEFT JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    LEFT JOIN warehouse w_cr ON cr.cr_warehouse_sk = w_cr.w_warehouse_sk
    WHERE p_ss.p_channel_dmail = 'Y'
      AND s.s_state = 'CA'
      AND i.i_current_price > 50
      AND w_cr.w_country = 'USA'
      AND ws.ws_sales_price < 100
      AND p_ws.p_channel_email = 'N'
    GROUP BY 
        i.i_item_id,
        s.s_store_id,
        s.s_state,
        i.i_current_price,
        p_ss.p_promo_id
)
SELECT 
    i_item_id,
    s_store_id,
    total_store_sales,
    total_store_profit,
    total_web_sales,
    total_web_profit,
    total_store_returns,
    store_sales_txns,
    web_sales_orders,
    return_txns,
    (total_store_profit / NULLIF(total_store_sales, 0)) AS store_profit_margin,
    (total_web_profit / NULLIF(total_web_sales, 0)) AS web_profit_margin
FROM agg
WHERE (total_store_profit / NULLIF(total_store_sales, 0)) > (
      SELECT AVG(total_store_profit / NULLIF(total_store_sales, 0)) FROM agg
)
INTERSECT
SELECT 
    i_item_id,
    s_store_id,
    total_store_sales,
    total_store_profit,
    total_web_sales,
    total_web_profit,
    total_store_returns,
    store_sales_txns,
    web_sales_orders,
    return_txns,
    (total_store_profit / NULLIF(total_store_sales, 0)) AS store_profit_margin,
    (total_web_profit / NULLIF(total_web_sales, 0)) AS web_profit_margin
FROM agg
WHERE total_web_sales > 20000
EXCEPT
SELECT 
    i_item_id,
    s_store_id,
    total_store_sales,
    total_store_profit,
    total_web_sales,
    total_web_profit,
    total_store_returns,
    store_sales_txns,
    web_sales_orders,
    return_txns,
    (total_store_profit / NULLIF(total_store_sales, 0)) AS store_profit_margin,
    (total_web_profit / NULLIF(total_web_sales, 0)) AS web_profit_margin
FROM agg
WHERE return_txns > 10
ORDER BY store_profit_margin DESC
LIMIT 100
