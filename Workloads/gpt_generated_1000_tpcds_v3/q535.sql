WITH catalog_data AS (
    SELECT
        p.p_promo_id AS promo_id,
        'Catalog' AS channel,
        SUM(cs.cs_net_profit - COALESCE(cr.cr_net_loss, 0)) AS net_profit,
        SUM(cs.cs_quantity) AS total_quantity,
        (
            SELECT MAX(p2.p_cost)
            FROM promotion p2
            WHERE p2.p_promo_sk = p.p_promo_sk
        ) AS max_promo_cost,
        cc.cc_name AS source_detail,
        p.p_promo_sk,
        cc.cc_name
    FROM
        catalog_sales cs
        JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
        JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
        JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
        LEFT JOIN catalog_returns cr
            ON cs.cs_order_number = cr.cr_order_number
            AND cs.cs_item_sk = cr.cr_item_sk
    WHERE
        cc.cc_rec_start_date >= DATE '2001-01-01'
        AND cc.cc_rec_end_date <= DATE '2001-12-31'
        AND EXISTS (
            SELECT 1
            FROM catalog_returns cr2
            WHERE cr2.cr_order_number = cs.cs_order_number
        )
    GROUP BY
        p.p_promo_id,
        p.p_promo_sk,
        cc.cc_name
),
web_data AS (
    SELECT
        p.p_promo_id AS promo_id,
        'Web' AS channel,
        SUM(ws.ws_net_profit - COALESCE(wr.wr_net_loss, 0)) AS net_profit,
        SUM(ws.ws_quantity) AS total_quantity,
        (
            SELECT MAX(p2.p_cost)
            FROM promotion p2
            WHERE p2.p_promo_sk = p.p_promo_sk
        ) AS max_promo_cost,
        w.w_city AS source_detail,
        p.p_promo_sk,
        w.w_city
    FROM
        web_sales ws
        JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
        JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
        LEFT JOIN web_returns wr
            ON ws.ws_order_number = wr.wr_order_number
            AND ws.ws_item_sk = wr.wr_item_sk
    WHERE
        p.p_start_date_sk BETWEEN 2450185 AND 2450282
        AND EXISTS (
            SELECT 1
            FROM web_returns wr2
            WHERE wr2.wr_order_number = ws.ws_order_number
        )
    GROUP BY
        p.p_promo_id,
        p.p_promo_sk,
        w.w_city
),
combined AS (
    SELECT promo_id, channel, net_profit, total_quantity, max_promo_cost, source_detail
    FROM catalog_data
    UNION ALL
    SELECT promo_id, channel, net_profit, total_quantity, max_promo_cost, source_detail
    FROM web_data
)
SELECT
    promo_id,
    channel,
    net_profit,
    total_quantity,
    max_promo_cost,
    source_detail
FROM combined
ORDER BY promo_id, channel
