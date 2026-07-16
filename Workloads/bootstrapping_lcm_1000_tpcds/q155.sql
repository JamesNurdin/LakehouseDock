WITH sales_agg AS (
    SELECT
        cc.cc_company_name,
        cc.cc_manager,
        d_sold.d_year,
        d_sold.d_month_seq,
        s.s_store_name,
        s.s_city,
        wp.wp_url,
        wp.wp_type,
        SUM(ss.ss_net_paid_inc_tax) AS total_net_paid_inc_tax,
        SUM(ss.ss_net_profit) AS total_net_profit,
        COUNT(*) AS transaction_cnt
    FROM store_sales ss
    JOIN date_dim d_sold
        ON ss.ss_sold_date_sk = d_sold.d_date_sk
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    JOIN date_dim d_store_closed
        ON s.s_closed_date_sk = d_store_closed.d_date_sk
    JOIN call_center cc
        ON cc.cc_closed_date_sk = d_store_closed.d_date_sk
    JOIN date_dim d_cc_open
        ON cc.cc_open_date_sk = d_cc_open.d_date_sk
    JOIN web_page wp
        ON wp.wp_creation_date_sk = d_cc_open.d_date_sk
    JOIN date_dim d_wp_access
        ON wp.wp_access_date_sk = d_wp_access.d_date_sk
    WHERE d_sold.d_year = 2022
    GROUP BY
        cc.cc_company_name,
        cc.cc_manager,
        d_sold.d_year,
        d_sold.d_month_seq,
        s.s_store_name,
        s.s_city,
        wp.wp_url,
        wp.wp_type
)
SELECT
    cc_company_name,
    cc_manager,
    d_year,
    d_month_seq,
    s_store_name,
    s_city,
    wp_url,
    wp_type,
    total_net_paid_inc_tax,
    total_net_profit,
    transaction_cnt,
    ROW_NUMBER() OVER (ORDER BY total_net_paid_inc_tax DESC) AS sales_rank
FROM sales_agg
ORDER BY total_net_paid_inc_tax DESC
LIMIT 50
