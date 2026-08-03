WITH
    sales_promo AS (
        SELECT
            ws.ws_order_number,
            ws.ws_sold_time_sk,
            ws.ws_ext_sales_price,
            p.p_promo_sk,
            p.p_promo_name AS promo_name,
            t.t_shift,
            ROW_NUMBER() OVER (PARTITION BY p.p_promo_sk ORDER BY ws.ws_ext_sales_price DESC) AS rn_promo
        FROM web_sales ws
        RIGHT OUTER JOIN promotion p
            ON ws.ws_promo_sk = p.p_promo_sk
        JOIN time_dim t
            ON ws.ws_sold_time_sk = t.t_time_sk
        WHERE ws.ws_ext_sales_price > 1000
          AND p.p_channel_email = 'N'
          AND t.t_shift = 'first'
    ),
    returns_info AS (
        SELECT
            cr.cr_order_number,
            cr.cr_return_amount,
            cc.cc_name,
            cp.cp_department,
            t.t_shift AS return_shift,
            ROW_NUMBER() OVER (PARTITION BY cc.cc_call_center_sk ORDER BY cr.cr_return_amount DESC) AS rn_cc
        FROM catalog_returns cr
        FULL OUTER JOIN call_center cc
            ON cr.cr_call_center_sk = cc.cc_call_center_sk
        JOIN catalog_page cp
            ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
        JOIN time_dim t
            ON cr.cr_returned_time_sk = t.t_time_sk
        WHERE cr.cr_return_amount > 500
          AND cc.cc_state = 'CA'
          AND cp.cp_type = 'A'
    ),
    common_orders AS (
        SELECT ws_order_number AS order_no
        FROM web_sales
        INTERSECT
        SELECT cr_order_number
        FROM catalog_returns
    ),
    small_time AS (
        SELECT t_time_sk, t_shift
        FROM time_dim
        WHERE t_shift IN ('first', 'second')
        LIMIT 5
    ),
    computed_set AS (
        SELECT seq AS seq_num
        FROM (VALUES 1, 2, 3, 4, 5) AS v(seq)
    ),
    cross_combination AS (
        SELECT st.t_time_sk, cs.seq_num
        FROM small_time st
        CROSS JOIN computed_set cs
    )
SELECT
    sp.ws_order_number,
    sp.p_promo_sk,
    sp.promo_name,
    sp.ws_ext_sales_price,
    sp.rn_promo,
    ri.cr_return_amount,
    ri.cc_name,
    ri.cp_department,
    ri.rn_cc,
    co.order_no,
    cc.t_time_sk,
    cc.seq_num
FROM sales_promo sp
LEFT JOIN returns_info ri
    ON sp.ws_order_number = ri.cr_order_number
INNER JOIN common_orders co
    ON sp.ws_order_number = co.order_no
INNER JOIN cross_combination cc
    ON sp.ws_sold_time_sk = cc.t_time_sk
WHERE sp.rn_promo <= 5
ORDER BY sp.ws_ext_sales_price DESC
LIMIT 100
