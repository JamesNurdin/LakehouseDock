WITH sales_summary AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_customer_sk,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY ss.ss_customer_sk ORDER BY SUM(ss.ss_ext_sales_price) DESC) AS sales_rank
    FROM store_sales ss
    GROUP BY ss.ss_sold_date_sk, ss.ss_customer_sk
)
SELECT
    c_main.c_customer_id,
    c_main.c_first_name,
    c_main.c_last_name,
    cd_main.cd_gender,
    p.p_promo_name,
    cc.cc_name AS call_center_name,
    ss_summary.total_sales,
    ss_summary.total_profit,
    ss_summary.sales_rank,
    (
        SELECT AVG(cr_sub.cr_fee)
        FROM catalog_returns cr_sub
        WHERE cr_sub.cr_refunded_customer_sk = c_main.c_customer_sk
    ) AS avg_refund_fee,
    wp.wp_url
FROM sales_summary ss_summary
JOIN store_sales ss
    ON ss.ss_sold_date_sk = ss_summary.ss_sold_date_sk
   AND ss.ss_customer_sk = ss_summary.ss_customer_sk
JOIN customer c_main
    ON ss.ss_customer_sk = c_main.c_customer_sk
JOIN customer_demographics cd_main
    ON ss.ss_cdemo_sk = cd_main.cd_demo_sk
JOIN promotion p
    ON ss.ss_promo_sk = p.p_promo_sk
JOIN catalog_returns cr
    ON cr.cr_returning_customer_sk = c_main.c_customer_sk
JOIN call_center cc
    ON cr.cr_call_center_sk = cc.cc_call_center_sk
JOIN web_page wp
    ON wp.wp_customer_sk = c_main.c_customer_sk
JOIN customer_demographics cd_refunded
    ON cr.cr_refunded_cdemo_sk = cd_refunded.cd_demo_sk
JOIN customer c_refunded
    ON cr.cr_refunded_customer_sk = c_refunded.c_customer_sk
JOIN customer_demographics cd_current
    ON c_main.c_current_cdemo_sk = cd_current.cd_demo_sk
WHERE p.p_channel_tv = 'N'
ORDER BY ss_summary.total_sales DESC
LIMIT 100
