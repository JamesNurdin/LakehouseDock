WITH base AS (
    SELECT
        ss.ss_ticket_number,
        ss.ss_quantity,
        ss.ss_net_paid,
        ss.ss_net_profit,
        d.d_year,
        i.i_category,
        i.i_brand,
        cc.cc_name,
        cc.cc_state,
        wp.wp_type,
        wp.wp_max_ad_count,
        ROW_NUMBER() OVER (ORDER BY ss.ss_net_paid DESC) AS rn
    FROM store_sales ss
    JOIN date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i
        ON ss.ss_item_sk = i.i_item_sk
    JOIN customer_demographics cd
        ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN catalog_returns cr
        ON ss.ss_item_sk = cr.cr_item_sk
       AND ss.ss_sold_date_sk = cr.cr_returned_date_sk
       AND ss.ss_cdemo_sk = cr.cr_refunded_cdemo_sk
    JOIN call_center cc
        ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN web_page wp
        ON wp.wp_creation_date_sk = d.d_date_sk
    WHERE
        d.d_year = 2002
        AND i.i_category = 'Electronics'
        AND i.i_brand = 'BrandA'
        AND cc.cc_state = 'CA'
        AND wp.wp_type = 'Home'
        AND wp.wp_max_ad_count >= 2
        AND ss.ss_quantity > 1
        AND ss.ss_net_paid > 100.00
        AND EXISTS (
            SELECT 1 FROM web_page wp2
            WHERE wp2.wp_customer_sk = ss.ss_customer_sk
        )
        AND NOT EXISTS (
            SELECT 1 FROM catalog_returns cr2
            WHERE cr2.cr_order_number = ss.ss_ticket_number
        )
)
SELECT
    d_year,
    i_category,
    i_brand,
    cc_name,
    cc_state,
    wp_type,
    wp_max_ad_count,
    COUNT(DISTINCT ss_ticket_number) AS num_sales,
    SUM(ss_quantity) AS total_quantity,
    SUM(ss_net_paid) AS total_net_paid,
    AVG(ss_net_profit) AS avg_net_profit,
    MIN(ss_net_paid) AS min_net_paid,
    MAX(ss_net_paid) AS max_net_paid,
    MAX(rn) AS max_row_number
FROM base
GROUP BY
    d_year,
    i_category,
    i_brand,
    cc_name,
    cc_state,
    wp_type,
    wp_max_ad_count
ORDER BY total_net_paid DESC
LIMIT 100
