WITH cr_agg AS (
    SELECT
        cr.cr_item_sk,
        SUM(cr.cr_return_quantity) AS total_return_qty,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_net_loss) AS total_net_loss
    FROM catalog_returns AS cr
    JOIN item AS i_cr ON cr.cr_item_sk = i_cr.i_item_sk
    GROUP BY cr.cr_item_sk
),
ws_arr AS (
    SELECT
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        ws.ws_web_site_sk,
        ws.ws_ship_mode_sk,
        ws.ws_warehouse_sk,
        ws.ws_web_page_sk,
        ws.ws_promo_sk,
        ws.ws_quantity,
        ws.ws_ext_sales_price,
        ws.ws_net_profit,
        ARRAY[ws.ws_quantity, ws.ws_ext_sales_price] AS qty_price_arr
    FROM web_sales AS ws
)
SELECT
    ws_dim.web_name AS web_site_name,
    sm_dim.sm_type AS ship_mode_type,
    sm_extra.sm_code AS ship_mode_code,
    p_dim.p_promo_name AS promo_name,
    wp.wp_type AS page_type,
    wh.w_warehouse_name AS warehouse_name,
    SUM(u.sale_amount) AS total_sales,
    SUM(COALESCE(u.return_amount, 0)) AS total_returns,
    SUM(u.net_profit) AS total_profit,
    SUM(CASE WHEN u.array_idx = 1 THEN u.array_val ELSE 0 END) AS total_array_quantity,
    SUM(CASE WHEN u.array_idx = 2 THEN u.array_val ELSE 0 END) AS total_array_sales,
    AVG(u.avg_site_profit) AS avg_site_profit
FROM (
    SELECT
        ws_arr.ws_web_site_sk,
        ws_arr.ws_ship_mode_sk,
        ws_arr.ws_promo_sk,
        ws_arr.ws_item_sk,
        ws_arr.ws_web_page_sk,
        ws_arr.ws_warehouse_sk,
        ws_arr.ws_ext_sales_price AS sale_amount,
        cr_agg.total_return_amount AS return_amount,
        ws_arr.ws_net_profit AS net_profit,
        t.val AS array_val,
        t.idx AS array_idx,
        (SELECT AVG(ws2.ws_net_profit)
         FROM web_sales ws2
         WHERE ws2.ws_web_site_sk = ws_arr.ws_web_site_sk) AS avg_site_profit
    FROM ws_arr
    LEFT JOIN cr_agg ON ws_arr.ws_item_sk = cr_agg.cr_item_sk
    CROSS JOIN (VALUES ROW(1), ROW(2)) AS factor(f)
    CROSS JOIN UNNEST(ws_arr.qty_price_arr) WITH ORDINALITY AS t(val, idx)
    WHERE ws_arr.ws_sold_date_sk BETWEEN 2450000 AND 2450200

    UNION DISTINCT

    SELECT
        ws_arr.ws_web_site_sk,
        ws_arr.ws_ship_mode_sk,
        ws_arr.ws_promo_sk,
        ws_arr.ws_item_sk,
        ws_arr.ws_web_page_sk,
        ws_arr.ws_warehouse_sk,
        ws_arr.ws_ext_sales_price AS sale_amount,
        cr2.total_return_amount AS return_amount,
        ws_arr.ws_net_profit AS net_profit,
        t2.val AS array_val,
        t2.idx AS array_idx,
        (SELECT AVG(ws3.ws_net_profit)
         FROM web_sales ws3
         WHERE ws3.ws_web_site_sk = ws_arr.ws_web_site_sk) AS avg_site_profit
    FROM ws_arr
    JOIN promotion AS p2 ON ws_arr.ws_promo_sk = p2.p_promo_sk
    JOIN item AS i2 ON ws_arr.ws_item_sk = i2.i_item_sk
    LEFT JOIN cr_agg AS cr2 ON ws_arr.ws_item_sk = cr2.cr_item_sk
    CROSS JOIN (VALUES ROW(3), ROW(4)) AS factor2(f)
    CROSS JOIN UNNEST(ws_arr.qty_price_arr) WITH ORDINALITY AS t2(val, idx)
    WHERE ws_arr.ws_sold_date_sk BETWEEN 2450201 AND 2450400
) AS u
JOIN ship_mode AS sm_dim ON u.ws_ship_mode_sk = sm_dim.sm_ship_mode_sk
JOIN ship_mode AS sm_extra ON u.ws_ship_mode_sk = sm_extra.sm_ship_mode_sk
JOIN promotion AS p_dim ON u.ws_promo_sk = p_dim.p_promo_sk
JOIN web_site AS ws_dim ON u.ws_web_site_sk = ws_dim.web_site_sk
JOIN web_page AS wp ON u.ws_web_page_sk = wp.wp_web_page_sk
JOIN warehouse AS wh ON u.ws_warehouse_sk = wh.w_warehouse_sk
GROUP BY
    ws_dim.web_name,
    sm_dim.sm_type,
    sm_extra.sm_code,
    p_dim.p_promo_name,
    wp.wp_type,
    wh.w_warehouse_name
ORDER BY total_sales DESC
LIMIT 100
