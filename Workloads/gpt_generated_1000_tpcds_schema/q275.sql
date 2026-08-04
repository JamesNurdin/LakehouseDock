WITH ss_sample AS (
    SELECT *
    FROM store_sales
    TABLESAMPLE BERNOULLI (10)
),

joined AS (
    SELECT
        st.s_store_name,
        st.s_state,
        promo.p_promo_name,
        t_s.t_meal_time,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        ss.ss_net_paid,
        sr.sr_return_amt,
        r.r_reason_desc,
        wp.wp_max_ad_count
    FROM ss_sample ss
    JOIN time_dim t_s ON ss.ss_sold_time_sk = t_s.t_time_sk
    JOIN customer cust ON ss.ss_customer_sk = cust.c_customer_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN store st ON ss.ss_store_sk = st.s_store_sk
    JOIN promotion promo ON ss.ss_promo_sk = promo.p_promo_sk
    LEFT JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
    LEFT JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    LEFT JOIN time_dim t_r ON sr.sr_return_time_sk = t_r.t_time_sk
    LEFT JOIN catalog_sales cs ON cs.cs_bill_customer_sk = cust.c_customer_sk
    LEFT JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    LEFT JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    LEFT JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN web_page wp ON wp.wp_customer_sk = cust.c_customer_sk
),

agg AS (
    SELECT
        s_store_name,
        s_state,
        p_promo_name,
        t_meal_time,
        ib_lower_bound,
        ib_upper_bound,
        SUM(ss_net_paid) AS total_net_paid,
        COUNT(*) AS sales_cnt
    FROM joined
    GROUP BY
        s_store_name,
        s_state,
        p_promo_name,
        t_meal_time,
        ib_lower_bound,
        ib_upper_bound
)

SELECT
    s_store_name,
    p_promo_name,
    t_meal_time,
    ib_lower_bound,
    ib_upper_bound,
    total_net_paid,
    sales_cnt,
    ROW_NUMBER() OVER (ORDER BY total_net_paid DESC) AS row_num
FROM agg
WHERE s_state = 'CA'

UNION DISTINCT

SELECT
    s_store_name,
    p_promo_name,
    t_meal_time,
    ib_lower_bound,
    ib_upper_bound,
    total_net_paid,
    sales_cnt,
    ROW_NUMBER() OVER (ORDER BY total_net_paid DESC) AS row_num
FROM agg
WHERE s_state <> 'CA'

LIMIT 100
