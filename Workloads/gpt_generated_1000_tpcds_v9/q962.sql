WITH base AS (
    SELECT
        ss.ss_sold_date_sk,
        t.t_hour,
        i.i_item_id,
        i.i_category,
        c.c_customer_sk,
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        c.c_birth_country,
        ca.ca_suite_number,
        s.s_store_id,
        s.s_state,
        p_ss.p_discount_active,
        p_ss.p_promo_name,
        cc.cc_name,
        cp.cp_department,
        sm.sm_type,
        w.w_warehouse_name,
        ss.ss_quantity AS ss_quantity,
        ss.ss_net_paid AS ss_net_paid,
        cs.cs_quantity AS cs_quantity,
        cs.cs_net_paid AS cs_net_paid,
        cr.cr_return_amount,
        r.r_reason_desc,
        wp.wp_url
    FROM store_sales ss
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN promotion p_ss ON ss.ss_promo_sk = p_ss.p_promo_sk
    JOIN catalog_sales cs ON cs.cs_sold_time_sk = t.t_time_sk
        AND cs.cs_item_sk = i.i_item_sk
        AND cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN promotion p_cs ON cs.cs_promo_sk = p_cs.p_promo_sk
    JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN web_page wp ON wp.wp_customer_sk = c.c_customer_sk
    WHERE
        s.s_state = 'GA'
        AND c.c_birth_country = 'PHILIPPINES'
        AND i.i_category = 'Electronics'
        AND p_ss.p_discount_active = 'Y'
        AND sm.sm_type = 'AIR'
        AND t.t_hour BETWEEN 9 AND 17
        AND ss.ss_quantity > 0
),
agg AS (
    SELECT
        c_customer_id,
        c_first_name,
        c_last_name,
        c_birth_country,
        s_store_id,
        s_state,
        i_category,
        SUM(ss_net_paid + cs_net_paid) AS total_net_paid,
        SUM(cr_return_amount) AS total_return_amount,
        c_customer_sk
    FROM base
    GROUP BY
        c_customer_id,
        c_first_name,
        c_last_name,
        c_birth_country,
        s_store_id,
        s_state,
        i_category,
        c_customer_sk
)
SELECT
    DISTINCT
    a.c_customer_id,
    a.c_first_name,
    a.c_last_name,
    a.c_birth_country,
    a.s_store_id,
    a.s_state,
    a.i_category,
    a.total_net_paid,
    a.total_return_amount,
    CASE
        WHEN a.total_net_paid > 50000 THEN 'VIP'
        WHEN a.total_net_paid BETWEEN 20000 AND 50000 THEN 'Gold'
        ELSE 'Silver'
    END AS customer_segment,
    RANK() OVER (ORDER BY a.total_net_paid DESC) AS revenue_rank,
    (SELECT COUNT(*) FROM store_sales ss2 WHERE ss2.ss_customer_sk = a.c_customer_sk) AS total_transactions,
    (SELECT SUM(cr2.cr_return_amount) FROM catalog_returns cr2 WHERE cr2.cr_refunded_customer_sk = a.c_customer_sk) AS total_refunded_amount
FROM agg a
ORDER BY a.total_net_paid DESC, revenue_rank
LIMIT 100
