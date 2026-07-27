WITH sales_agg AS (
    SELECT
        p.p_promo_id,
        i.i_category,
        sm.sm_code,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(*) AS sales_cnt,
        AVG(ws.ws_quantity) AS avg_qty
    FROM web_sales ws
    JOIN time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    LEFT JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN web_site we ON ws.ws_web_site_sk = we.web_site_sk
    JOIN household_demographics hd_bill ON ws.ws_bill_hdemo_sk = hd_bill.hd_demo_sk
    JOIN household_demographics hd_ship ON ws.ws_ship_hdemo_sk = hd_ship.hd_demo_sk
    WHERE
        td.t_hour BETWEEN 8 AND 18
        AND i.i_current_price > 20
        AND i.i_rec_start_date <= DATE '2000-12-31'
        AND i.i_rec_end_date >= DATE '2000-01-01'
    GROUP BY
        p.p_promo_id,
        i.i_category,
        sm.sm_code
)
SELECT
    sa.p_promo_id,
    sa.i_category,
    COALESCE(sa.sm_code, 'UNKNOWN') AS ship_mode_code,
    sa.total_sales,
    sa.total_profit,
    sa.sales_cnt,
    sa.avg_qty,
    COALESCE(sa.total_sales / NULLIF(sa.sales_cnt, 0), 0) AS avg_sale_per_order,
    (
        SELECT COUNT(*)
        FROM promotion p2
        WHERE p2.p_promo_id = sa.p_promo_id
          AND p2.p_discount_active = 'Y'
    ) AS active_discount_count
FROM sales_agg sa
WHERE
    sa.total_profit > 1000
    AND EXISTS (
        SELECT 1
        FROM promotion p3
        WHERE p3.p_promo_id = sa.p_promo_id
          AND p3.p_channel_email = 'Y'
    )
ORDER BY sa.total_profit DESC
LIMIT 100
