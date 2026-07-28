WITH joined_data AS (
    SELECT
        s.s_store_name,
        s.s_state,
        p.p_promo_name,
        d_sales.d_year AS sales_year,
        ss.ss_net_paid,
        ss.ss_quantity,
        i.inv_quantity_on_hand,
        hd.hd_vehicle_count,
        cp.cp_catalog_number,
        cc.cc_market_manager
    FROM store_sales ss
    JOIN date_dim d_sales ON ss.ss_sold_date_sk = d_sales.d_date_sk
    JOIN time_dim t_sales ON ss.ss_sold_time_sk = t_sales.t_time_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN inventory i ON i.inv_date_sk = d_sales.d_date_sk
    JOIN call_center cc ON cc.cc_closed_date_sk = d_sales.d_date_sk
    JOIN catalog_returns cr ON cr.cr_returned_date_sk = d_sales.d_date_sk
    JOIN date_dim d_return ON cr.cr_returned_date_sk = d_return.d_date_sk
    JOIN time_dim t_return ON cr.cr_returned_time_sk = t_return.t_time_sk
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN date_dim d_cp_start ON cp.cp_start_date_sk = d_cp_start.d_date_sk
    JOIN date_dim d_cp_end ON cp.cp_end_date_sk = d_cp_end.d_date_sk
    JOIN date_dim d_store ON s.s_closed_date_sk = d_store.d_date_sk
    JOIN date_dim d_cc_open ON cc.cc_open_date_sk = d_cc_open.d_date_sk
    JOIN date_dim d_promo_start ON p.p_start_date_sk = d_promo_start.d_date_sk
    JOIN date_dim d_promo_end ON p.p_end_date_sk = d_promo_end.d_date_sk
    WHERE
        d_sales.d_year = 2001
        AND s.s_state = 'CA'
        AND p.p_channel_press = 'N'
        AND cp.cp_catalog_number IN (5, 13)
        AND cc.cc_market_manager LIKE '%Smith%'
        AND i.inv_quantity_on_hand > 500
        AND hd.hd_vehicle_count > 1
        AND EXISTS (
            SELECT 1 FROM web_page wp
            WHERE wp.wp_customer_sk = ss.ss_customer_sk
              AND wp.wp_url LIKE '%example%'
        )
),
agg_summary AS (
    SELECT
        s_store_name,
        p_promo_name,
        sales_year,
        SUM(ss_net_paid) AS total_net_paid,
        SUM(ss_quantity) AS total_quantity,
        COUNT(*) AS transaction_count,
        CASE WHEN SUM(ss_quantity) > 100 THEN 'High Volume' ELSE 'Low Volume' END AS volume_category
    FROM (
        SELECT
            s_store_name,
            p_promo_name,
            sales_year,
            ss_net_paid,
            ss_quantity
        FROM joined_data
    ) jd
    GROUP BY s_store_name, p_promo_name, sales_year
)
SELECT
    s_store_name,
    p_promo_name,
    sales_year,
    total_net_paid,
    transaction_count,
    volume_category,
    total_net_paid / NULLIF(transaction_count, 0) AS avg_net_per_txn,
    (SELECT MAX(d_year) FROM date_dim) AS max_year_in_dim
FROM agg_summary
WHERE total_net_paid > 10000
ORDER BY total_net_paid DESC
LIMIT 100
