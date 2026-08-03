WITH item_sales AS (
    SELECT
        i.i_item_id,
        i.i_brand,
        i.i_category,
        i.i_item_sk,
        cs.cs_order_number,
        cs.cs_quantity        AS cs_qty,
        cs.cs_net_profit      AS cs_net_profit,
        ss.ss_quantity        AS ss_qty,
        ss.ss_net_profit      AS ss_net_profit,
        ss.ss_promo_sk,
        ws.ws_quantity        AS ws_qty,
        ws.ws_net_profit      AS ws_net_profit,
        cr.cr_return_quantity AS cr_ret_qty,
        cr.cr_refunded_cash   AS cr_refunded_cash,
        wr.wr_return_quantity AS wr_ret_qty,
        wr.wr_refunded_cash   AS wr_refunded_cash,
        p.p_promo_name,
        p.p_end_date_sk
    FROM
        item i
        LEFT JOIN catalog_sales cs      ON cs.cs_item_sk = i.i_item_sk
        LEFT JOIN catalog_returns cr    ON cr.cr_item_sk = i.i_item_sk
                                          AND cr.cr_order_number = cs.cs_order_number
        LEFT JOIN store_sales ss        ON ss.ss_item_sk = i.i_item_sk
        LEFT JOIN web_sales ws          ON ws.ws_item_sk = i.i_item_sk
        LEFT JOIN web_returns wr       ON wr.wr_item_sk = i.i_item_sk
                                          AND wr.wr_order_number = ws.ws_order_number
        LEFT JOIN promotion p          ON p.p_promo_sk = cs.cs_promo_sk
    WHERE
        p.p_end_date_sk BETWEEN 2450100 AND 2450500
        AND p.p_channel_radio = 'N'
        AND cr.cr_refunded_cash > 100
        AND ss.ss_ext_tax < 100
        AND i.i_brand = 'Brand#23'
)
SELECT
    i_item_id,
    i_brand,
    i_category,
    total_profit,
    total_qty,
    avg_refunded_cash,
    rank_in_category
FROM (
    SELECT
        i_item_id,
        i_brand,
        i_category,
        (COALESCE(cs_net_profit, 0) + COALESCE(ss_net_profit, 0) + COALESCE(ws_net_profit, 0)) AS total_profit,
        (COALESCE(cs_qty, 0) + COALESCE(ss_qty, 0) + COALESCE(ws_qty, 0))      AS total_qty,
        (
            SELECT AVG(cr2.cr_refunded_cash)
            FROM catalog_returns cr2
            WHERE cr2.cr_item_sk = i_item_sk
        ) AS avg_refunded_cash,
        RANK() OVER (PARTITION BY i_category ORDER BY (COALESCE(cs_net_profit, 0) + COALESCE(ss_net_profit, 0) + COALESCE(ws_net_profit, 0)) DESC) AS rank_in_category,
        ss_promo_sk
    FROM
        item_sales
    WHERE NOT EXISTS (
        SELECT 1
        FROM promotion p2
        WHERE p2.p_promo_sk = ss_promo_sk
          AND p2.p_discount_active = 'Y'
    )
) t
WHERE rank_in_category <= 5
ORDER BY i_category, total_profit DESC
LIMIT 100
