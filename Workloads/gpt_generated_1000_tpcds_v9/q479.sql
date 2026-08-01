WITH ss_sample AS (
    SELECT
        ss_item_sk,
        ss_customer_sk,
        ss_addr_sk,
        ss_store_sk,
        ss_net_paid
    FROM store_sales
    TABLESAMPLE BERNOULLI (10)
),
cr_cc AS (
    SELECT
        cr.cr_item_sk,
        cr.cr_reason_sk,
        cr.cr_warehouse_sk,
        cr.cr_call_center_sk,
        cr.cr_return_quantity,
        cr.cr_return_amount,
        cc.cc_call_center_sk,
        cc.cc_name,
        cc.cc_state
    FROM catalog_returns cr
    FULL OUTER JOIN call_center cc
        ON cr.cr_call_center_sk = cc.cc_call_center_sk
),
joined AS (
    SELECT
        i.i_item_id,
        i.i_current_price,
        i.i_product_name,
        c.c_customer_id,
        c.c_birth_month,
        s.s_store_name,
        s.s_state,
        cc.cc_name AS call_center_name,
        cc.cc_state,
        w.w_warehouse_name,
        r.r_reason_desc,
        wp.wp_url,
        ss.ss_net_paid,
        CASE
            WHEN i.i_current_price > 1000 THEN 'High'
            WHEN i.i_current_price > 500 THEN 'Medium'
            ELSE 'Low'
        END AS price_category
    FROM ss_sample ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    LEFT JOIN cr_cc cc ON i.i_item_sk = cc.cr_item_sk
    LEFT JOIN reason r ON cc.cr_reason_sk = r.r_reason_sk
    LEFT JOIN warehouse w ON cc.cr_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN web_page wp ON wp.wp_customer_sk = c.c_customer_sk
    WHERE
        i.i_current_price > 500
        AND c.c_birth_month = 5
        AND s.s_state = 'CA'
        AND r.r_reason_desc LIKE '%service%'
        AND cc.cc_state = 'TX'
        AND ss.ss_net_paid > 1000
),
distinct_items AS (
    SELECT DISTINCT
        i_item_id,
        i_current_price,
        price_category
    FROM joined
),
aggregated AS (
    SELECT
        di.i_item_id,
        di.price_category,
        j.r_reason_desc,
        SUM(j.ss_net_paid) AS total_net_paid,
        COUNT(*) AS transaction_cnt
    FROM joined j
    JOIN distinct_items di
        ON j.i_item_id = di.i_item_id
        AND j.price_category = di.price_category
    GROUP BY di.i_item_id, di.price_category, j.r_reason_desc
)
SELECT
    i_item_id,
    price_category,
    r_reason_desc,
    total_net_paid,
    transaction_cnt,
    ROW_NUMBER() OVER (PARTITION BY price_category ORDER BY total_net_paid DESC) AS price_cat_rank
FROM aggregated
ORDER BY total_net_paid DESC
LIMIT 100
