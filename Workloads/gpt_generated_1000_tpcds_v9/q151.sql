WITH joined_data AS (
    SELECT
        cr.cr_return_amount,
        cr.cr_return_quantity,
        cr.cr_order_number,
        s.s_store_id AS s_store_id,
        d.d_year AS d_year,
        r.r_reason_desc AS r_reason_desc,
        cc.cc_name AS cc_name,
        cc.cc_state AS cc_state,
        i.i_current_price AS i_current_price,
        ws.web_name AS web_name,
        sm.sm_type AS sm_type,
        p.p_discount_active AS p_discount_active,
        t.t_meal_time AS t_meal_time
    FROM catalog_returns cr
    FULL OUTER JOIN call_center cc
        ON cr.cr_call_center_sk = cc.cc_call_center_sk
    LEFT JOIN item i
        ON cr.cr_item_sk = i.i_item_sk
    LEFT JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    LEFT JOIN ship_mode sm
        ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    LEFT JOIN date_dim d
        ON cr.cr_returned_date_sk = d.d_date_sk
    LEFT JOIN time_dim t
        ON cr.cr_returned_time_sk = t.t_time_sk
    LEFT JOIN customer cust
        ON cr.cr_refunded_customer_sk = cust.c_customer_sk
    LEFT JOIN customer_demographics cd
        ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd
        ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN customer_address ca
        ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    LEFT JOIN store s
        ON s.s_closed_date_sk = d.d_date_sk
    LEFT JOIN promotion p
        ON p.p_item_sk = i.i_item_sk
    LEFT JOIN web_site ws
        ON ws.web_open_date_sk = d.d_date_sk
    LEFT JOIN web_page wp
        ON wp.wp_creation_date_sk = d.d_date_sk
        AND wp.wp_customer_sk = cust.c_customer_sk
    LEFT JOIN web_returns wr
        ON wr.wr_returned_date_sk = d.d_date_sk
        AND wr.wr_item_sk = i.i_item_sk
        AND wr.wr_refunded_customer_sk = cust.c_customer_sk
    WHERE
        d.d_year = 2000
        AND t.t_meal_time = 'dinner'
        AND r.r_reason_desc LIKE '%damaged%'
        AND cc.cc_state = 'CA'
        AND i.i_current_price > 100
        AND ws.web_name IN ('site_0', 'site_1')
        AND sm.sm_type = 'AIR'
        AND p.p_discount_active = 'Y'
),
agg_data AS (
    SELECT
        s_store_id,
        d_year,
        r_reason_desc,
        cc_name,
        SUM(cr_return_amount) AS total_return_amount,
        SUM(cr_return_quantity) AS total_return_qty,
        COUNT(DISTINCT cr_order_number) AS distinct_orders,
        AVG(cr_return_amount) AS avg_return_amount
    FROM joined_data
    GROUP BY
        s_store_id,
        d_year,
        r_reason_desc,
        cc_name
)
SELECT
    s_store_id AS store_id,
    d_year AS year,
    r_reason_desc AS reason_desc,
    cc_name AS call_center_name,
    total_return_amount,
    total_return_qty,
    distinct_orders,
    avg_return_amount,
    (avg_return_amount / total_return_amount) AS avg_to_total_ratio
FROM agg_data
WHERE (avg_return_amount / total_return_amount) > 0.001
ORDER BY total_return_amount DESC
LIMIT 100
