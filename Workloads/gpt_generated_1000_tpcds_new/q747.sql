WITH
    order_set AS (
        SELECT cs.cs_order_number AS order_key
        FROM catalog_sales cs
        WHERE cs.cs_quantity > 5
        INTERSECT
        SELECT ss.ss_ticket_number AS order_key
        FROM store_sales ss
        WHERE ss.ss_quantity > 5
    ),
    base AS (
        SELECT
            cs.cs_order_number,
            cs.cs_quantity,
            cs.cs_net_paid,
            c.c_customer_sk,
            c.c_customer_id,
            hd.hd_income_band_sk,
            ib.ib_upper_bound,
            p.p_promo_id,
            sm.sm_ship_mode_id,
            sm.sm_code,
            cp.cp_type,
            cc.cc_state,
            wp.wp_autogen_flag,
            cr.cr_return_amount
        FROM catalog_sales cs
        JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
        JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
        JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
        JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
        JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
        JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
        JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
        LEFT JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
        LEFT JOIN web_returns wr ON wr.wr_order_number = cs.cs_order_number
        LEFT JOIN web_page wp ON wp.wp_web_page_sk = wr.wr_web_page_sk
        WHERE cc.cc_state = 'CA'
          AND cp.cp_type = 'PROMO'
          AND sm.sm_code = 'AIR'
          AND wp.wp_autogen_flag = 'N'
          AND ib.ib_upper_bound > 60000
          AND cs.cs_quantity > 5
    ),
    store_part AS (
        SELECT
            ss.ss_ticket_number,
            ss.ss_quantity,
            ss.ss_net_paid,
            c.c_customer_sk,
            c.c_customer_id,
            hd.hd_income_band_sk,
            p.p_promo_id
        FROM store_sales ss
        JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
        JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
        JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
        WHERE c.c_birth_year BETWEEN 1960 AND 1970
          AND hd.hd_vehicle_count >= 2
    ),
    joined AS (
        SELECT
            COALESCE(b.cs_order_number, s.ss_ticket_number) AS order_key,
            COALESCE(b.c_customer_id, s.c_customer_id) AS customer_id,
            b.cs_quantity AS cs_quantity,
            s.ss_quantity AS ss_quantity,
            b.cs_net_paid AS cs_net_paid,
            s.ss_net_paid AS ss_net_paid,
            b.cc_state,
            b.cp_type,
            b.sm_code,
            b.ib_upper_bound,
            b.cr_return_amount
        FROM base b
        FULL OUTER JOIN store_part s
            ON b.c_customer_sk = s.c_customer_sk
        JOIN order_set os
            ON os.order_key = COALESCE(b.cs_order_number, s.ss_ticket_number)
    )
SELECT
    order_key,
    customer_id,
    SUM(COALESCE(cs_net_paid, 0) + COALESCE(ss_net_paid, 0)) AS total_net_paid,
    COUNT(*) AS transaction_cnt,
    MAX(COALESCE(cs_quantity, 0)) AS max_quantity,
    MIN(COALESCE(cs_quantity, 0)) AS min_quantity,
    AVG(COALESCE(cs_quantity, 0)) AS avg_quantity,
    (
        SELECT SUM(cr2.cr_return_amount)
        FROM catalog_returns cr2
        WHERE cr2.cr_order_number = order_key
    ) AS total_return_amount,
    SUM(SUM(COALESCE(cs_net_paid, 0) + COALESCE(ss_net_paid, 0))) OVER (
        ORDER BY order_key
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS running_total_net_paid
FROM joined
GROUP BY ROLLUP (order_key, customer_id)
ORDER BY total_net_paid DESC
LIMIT 100
