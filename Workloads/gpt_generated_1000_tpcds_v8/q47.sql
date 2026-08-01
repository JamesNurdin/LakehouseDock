WITH sales_agg AS (
    SELECT
        cs.cs_catalog_page_sk,
        cs.cs_sold_date_sk,
        cs.cs_order_number,
        cs.cs_promo_sk,
        cs.cs_call_center_sk,
        cs.cs_bill_customer_sk,
        cs.cs_bill_addr_sk,
        SUM(cs.cs_net_paid) AS total_net_paid,
        COUNT(*) AS cnt_orders
    FROM catalog_sales cs
    GROUP BY
        cs.cs_catalog_page_sk,
        cs.cs_sold_date_sk,
        cs.cs_order_number,
        cs.cs_promo_sk,
        cs.cs_call_center_sk,
        cs.cs_bill_customer_sk,
        cs.cs_bill_addr_sk
), joined AS (
    SELECT
        s.s_store_id,
        s.s_city,
        s.s_state,
        cc.cc_name,
        p.p_promo_name,
        d_sold.d_year,
        sa.total_net_paid,
        CASE WHEN sa.total_net_paid > 10000 THEN 'High' ELSE 'Low' END AS sales_category,
        cr.cr_return_amount,
        sm.sm_carrier,
        w.w_warehouse_name,
        ca.ca_city AS customer_city,
        hd.hd_income_band_sk,
        inv.inv_quantity_on_hand,
        wp.wp_url
    FROM sales_agg sa
    JOIN catalog_page cp_sales
        ON sa.cs_catalog_page_sk = cp_sales.cp_catalog_page_sk
    JOIN date_dim d_sold
        ON sa.cs_sold_date_sk = d_sold.d_date_sk
    JOIN call_center cc
        ON sa.cs_call_center_sk = cc.cc_call_center_sk
    JOIN promotion p
        ON sa.cs_promo_sk = p.p_promo_sk
    JOIN customer cu
        ON sa.cs_bill_customer_sk = cu.c_customer_sk
    JOIN customer_address ca
        ON sa.cs_bill_addr_sk = ca.ca_address_sk
    LEFT JOIN catalog_returns cr
        ON cr.cr_order_number = sa.cs_order_number
    LEFT JOIN catalog_page cp_return
        ON cr.cr_catalog_page_sk = cp_return.cp_catalog_page_sk
    LEFT JOIN ship_mode sm
        ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    LEFT JOIN date_dim d_return
        ON cr.cr_returned_date_sk = d_return.d_date_sk
    LEFT JOIN store_returns sr
        ON sr.sr_returned_date_sk = d_sold.d_date_sk
    LEFT JOIN store s
        ON sr.sr_store_sk = s.s_store_sk
    LEFT JOIN household_demographics hd
        ON sr.sr_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN inventory inv
        ON inv.inv_date_sk = d_sold.d_date_sk
    LEFT JOIN warehouse w
        ON inv.inv_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN web_page wp
        ON wp.wp_customer_sk = cu.c_customer_sk
)
SELECT
    s_store_id,
    s_city,
    s_state,
    cc_name,
    p_promo_name,
    d_year,
    sales_category,
    SUM(total_net_paid) AS sum_net_paid,
    COUNT(*) AS num_records,
    ROW_NUMBER() OVER (PARTITION BY s_state ORDER BY SUM(total_net_paid) DESC) AS state_rank
FROM joined
GROUP BY
    s_store_id,
    s_city,
    s_state,
    cc_name,
    p_promo_name,
    d_year,
    sales_category
ORDER BY sum_net_paid DESC
LIMIT 100
