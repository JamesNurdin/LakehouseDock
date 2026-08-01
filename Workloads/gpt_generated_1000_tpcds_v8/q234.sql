WITH
    inv_agg AS (
        SELECT
            inv_item_sk,
            inv_date_sk,
            SUM(inv_quantity_on_hand) AS total_on_hand
        FROM inventory
        WHERE inv_quantity_on_hand > 0
        GROUP BY inv_item_sk, inv_date_sk
    ),
    order_intersect AS (
        SELECT ws_order_number AS order_number
        FROM web_sales ws
        JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
        WHERE d.d_year = 2001
          AND ws.ws_quantity > 0
        INTERSECT
        SELECT cr_order_number
        FROM catalog_returns cr
        JOIN date_dim d2 ON cr.cr_returned_date_sk = d2.d_date_sk
        WHERE d2.d_year = 2001
          AND cr.cr_return_quantity > 0
    ),
    agg_data AS (
        SELECT
            d.d_year,
            i.i_brand,
            sm.sm_type,
            inv_agg.total_on_hand,
            SUM(ws.ws_net_profit) AS total_profit,
            COUNT(DISTINCT ws.ws_order_number) AS orders_cnt,
            MAX(ws_max.max_sale_price) AS max_sale_price
        FROM web_sales ws
        JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
        JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
        JOIN item i ON ws.ws_item_sk = i.i_item_sk
        JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
        JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
        JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
        JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
        JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
        JOIN inventory inv ON ws.ws_item_sk = inv.inv_item_sk
            AND ws.ws_sold_date_sk = inv.inv_date_sk
        JOIN inv_agg ON inv.inv_item_sk = inv_agg.inv_item_sk
            AND inv.inv_date_sk = inv_agg.inv_date_sk
        JOIN order_intersect oi ON ws.ws_order_number = oi.order_number
        JOIN catalog_returns cr ON ws.ws_order_number = cr.cr_order_number
        JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
        JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
        JOIN store_returns sr ON sr.sr_item_sk = i.i_item_sk
            AND sr.sr_returned_date_sk = d.d_date_sk
        JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
        CROSS JOIN LATERAL (
            SELECT MAX(ws2.ws_ext_sales_price) AS max_sale_price
            FROM web_sales ws2
            WHERE ws2.ws_item_sk = i.i_item_sk
        ) AS ws_max
        WHERE d.d_year = 2001
          AND i.i_color = 'Color1'
          AND sm.sm_type = 'AIR'
          AND cd.cd_gender = 'M'
          AND r.r_reason_desc LIKE '%defect%'
        GROUP BY ROLLUP (d.d_year, i.i_brand, sm.sm_type, inv_agg.total_on_hand)
    )
SELECT
    d_year,
    i_brand,
    sm_type,
    total_on_hand,
    total_profit,
    orders_cnt,
    max_sale_price,
    ROW_NUMBER() OVER (PARTITION BY i_brand ORDER BY total_profit DESC) AS brand_rank
FROM agg_data
ORDER BY d_year DESC, total_profit DESC
LIMIT 100
