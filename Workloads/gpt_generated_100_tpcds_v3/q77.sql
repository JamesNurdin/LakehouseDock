WITH joined_data AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_sold_time_sk,
        ss.ss_customer_sk,
        ss.ss_cdemo_sk,
        ss.ss_hdemo_sk,
        ss.ss_addr_sk,
        ss.ss_store_sk,
        ss.ss_promo_sk,
        ss.ss_net_paid,
        ss.ss_quantity,
        ss.ss_ticket_number,
        cs.cs_order_number,
        cs.cs_net_paid,
        cr.cr_return_amount,
        d.d_year,
        d.d_month_seq,
        p.p_promo_id,
        p.p_discount_active,
        st.s_store_id,
        st.s_state,
        cc.cc_name,
        sm.sm_ship_mode_id,
        inv.inv_quantity_on_hand,
        t.t_hour
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN store st ON ss.ss_store_sk = st.s_store_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN catalog_sales cs ON cs.cs_sold_date_sk = d.d_date_sk
        AND cs.cs_sold_time_sk = t.t_time_sk
        AND cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    LEFT JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
    LEFT JOIN inventory inv ON inv.inv_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND st.s_state = 'CA'
      AND p.p_discount_active = 'Y'
      AND t.t_hour BETWEEN 8 AND 12
)
SELECT
    jd.s_store_id,
    jd.d_year,
    jd.d_month_seq,
    jd.p_promo_id,
    jd.cc_name,
    jd.sm_ship_mode_id,
    SUM(jd.ss_net_paid) AS total_store_sales,
    SUM(jd.cs_net_paid) AS total_catalog_sales,
    SUM(jd.cr_return_amount) AS total_returns,
    COUNT(DISTINCT jd.ss_ticket_number) AS transaction_count,
    AVG(jd.ss_quantity) AS avg_store_quantity,
    MAX(jd.inv_quantity_on_hand) AS max_inventory_on_hand,
    (SELECT AVG(ss2.ss_net_paid) FROM store_sales ss2) AS avg_store_net_paid_overall
FROM joined_data jd
GROUP BY
    jd.s_store_id,
    jd.d_year,
    jd.d_month_seq,
    jd.p_promo_id,
    jd.cc_name,
    jd.sm_ship_mode_id
ORDER BY total_store_sales DESC
LIMIT 100
