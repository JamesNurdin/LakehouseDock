WITH base AS (
    SELECT
        i.i_category AS category,
        s.s_state AS state,
        sm.sm_type AS ship_type,
        SUM(cs.cs_net_paid) AS total_catalog_net_paid,
        SUM(ws.ws_net_paid) AS total_web_net_paid,
        COUNT(DISTINCT cs.cs_order_number) AS distinct_orders
    FROM
        catalog_returns cr
        JOIN catalog_sales cs
            ON cr.cr_order_number = cs.cs_order_number
        JOIN item i
            ON cr.cr_item_sk = i.i_item_sk
        JOIN reason r
            ON cr.cr_reason_sk = r.r_reason_sk
        JOIN ship_mode sm
            ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
        JOIN warehouse w
            ON cr.cr_warehouse_sk = w.w_warehouse_sk
        JOIN store_returns sr
            ON sr.sr_item_sk = i.i_item_sk
        JOIN store s
            ON sr.sr_store_sk = s.s_store_sk
        JOIN web_sales ws
            ON ws.ws_item_sk = i.i_item_sk
        JOIN web_page wp
            ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE
        i.i_category_id IN (3, 5, 7)
        AND sm.sm_type = 'AIR'
        AND s.s_state = 'CA'
        AND wp.wp_char_count > 1500
        AND cr.cr_return_quantity > 5
        AND NOT EXISTS (
            SELECT 1
            FROM store_returns sr_ex
            WHERE sr_ex.sr_item_sk = i.i_item_sk
              AND sr_ex.sr_return_quantity > 20
        )
    GROUP BY GROUPING SETS (
        (i.i_category, s.s_state, sm.sm_type),
        (i.i_category, s.s_state),
        (i.i_category),
        ()
    )
)
SELECT
    category,
    state,
    ship_type,
    total_catalog_net_paid,
    total_web_net_paid,
    distinct_orders,
    ROW_NUMBER() OVER (PARTITION BY category ORDER BY (total_catalog_net_paid + total_web_net_paid) DESC) AS rn
FROM base
ORDER BY (total_catalog_net_paid + total_web_net_paid) DESC
LIMIT 100
