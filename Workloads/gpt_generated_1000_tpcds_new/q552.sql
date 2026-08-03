WITH sampled_store AS (
    SELECT *
    FROM store_sales
    TABLESAMPLE BERNOULLI (5)
),

base AS (
    SELECT
        COALESCE(cs.cs_order_number, ws.ws_order_number)                 AS order_number,
        i.i_item_id                                                     AS i_item_id,
        i.i_product_name                                                AS i_product_name,
        c.c_customer_id                                                AS c_customer_id,
        p.p_promo_name                                                 AS p_promo_name,
        sm.sm_ship_mode_id                                             AS sm_ship_mode_id,
        COALESCE(r1.r_reason_desc, r2.r_reason_desc)                   AS reason_desc,
        td.t_hour                                                      AS t_hour,
        CASE WHEN COALESCE(cs.cs_net_profit, 0) + COALESCE(ws.ws_net_profit, 0) > 0 THEN 'POS' ELSE 'NEG' END AS profit_flag,
        COALESCE(cs.cs_net_paid, 0) + COALESCE(ws.ws_net_paid, 0)      AS net_paid,
        COALESCE(ss.ss_quantity, 0)                                    AS store_quantity,
        COALESCE(ss.ss_net_profit, 0)                                 AS store_profit
    FROM catalog_sales cs
    FULL OUTER JOIN web_sales ws
        ON cs.cs_order_number = ws.ws_order_number
    JOIN item i
        ON COALESCE(cs.cs_item_sk, ws.ws_item_sk) = i.i_item_sk
    JOIN customer c
        ON COALESCE(cs.cs_bill_customer_sk, ws.ws_bill_customer_sk) = c.c_customer_sk
    JOIN promotion p
        ON COALESCE(cs.cs_promo_sk, ws.ws_promo_sk) = p.p_promo_sk
    JOIN ship_mode sm
        ON COALESCE(cs.cs_ship_mode_sk, ws.ws_ship_mode_sk) = sm.sm_ship_mode_sk
    JOIN time_dim td
        ON COALESCE(cs.cs_sold_time_sk, ws.ws_sold_time_sk) = td.t_time_sk
    LEFT JOIN catalog_returns cr
        ON cs.cs_order_number = cr.cr_order_number
    LEFT JOIN web_returns wr
        ON ws.ws_order_number = wr.wr_order_number
    LEFT JOIN reason r1
        ON cr.cr_reason_sk = r1.r_reason_sk
    LEFT JOIN reason r2
        ON wr.wr_reason_sk = r2.r_reason_sk
    LEFT JOIN sampled_store ss
        ON ss.ss_item_sk = i.i_item_sk AND ss.ss_customer_sk = c.c_customer_sk
    LEFT JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    LEFT JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    LEFT JOIN web_site wsite
        ON ws.ws_web_site_sk = wsite.web_site_sk
),

unioned AS (
    SELECT
        order_number, i_item_id, i_product_name, c_customer_id, p_promo_name,
        sm_ship_mode_id, reason_desc, t_hour, profit_flag,
        net_paid, store_quantity, store_profit
    FROM base
    UNION DISTINCT
    SELECT
        order_number, i_item_id, i_product_name, c_customer_id, p_promo_name,
        sm_ship_mode_id, reason_desc, t_hour, profit_flag,
        net_paid, store_quantity, store_profit
    FROM base
    WHERE profit_flag = 'NEG'
),

aggregated AS (
    SELECT
        profit_flag,
        COUNT(DISTINCT order_number) AS distinct_orders,
        COUNT(DISTINCT i_item_id)   AS distinct_items,
        SUM(net_paid)               AS total_net_paid,
        SUM(store_quantity)         AS total_store_quantity
    FROM unioned
    GROUP BY profit_flag
)

SELECT
    profit_flag,
    distinct_orders,
    distinct_items,
    total_net_paid,
    total_store_quantity
FROM aggregated
CROSS JOIN (VALUES (1), (2)) AS t(dummy)
ORDER BY profit_flag DESC, distinct_orders DESC
LIMIT 100
