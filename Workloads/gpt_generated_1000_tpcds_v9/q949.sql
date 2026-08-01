WITH sales_data AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_sold_time_sk,
        ss.ss_item_sk,
        ss.ss_customer_sk,
        ss.ss_cdemo_sk,
        ss.ss_store_sk,
        ss.ss_promo_sk,
        ss.ss_quantity,
        ss.ss_net_paid,
        ss.ss_net_profit,
        d.d_year,
        d.d_month_seq,
        t.t_hour,
        c.c_customer_sk,
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_education_status,
        s.s_store_id,
        s.s_city,
        s.s_gmt_offset,
        p.p_promo_name,
        p.p_discount_active,
        i.inv_quantity_on_hand,
        w.w_warehouse_name,
        wp.wp_url,
        cr.cr_return_amount
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    LEFT JOIN catalog_returns cr
        ON cr.cr_refunded_customer_sk = c.c_customer_sk
        AND cr.cr_returned_date_sk = d.d_date_sk
        AND cr.cr_returned_time_sk = t.t_time_sk
    LEFT JOIN inventory i ON i.inv_date_sk = d.d_date_sk
    LEFT JOIN warehouse w ON i.inv_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN web_page wp ON wp.wp_customer_sk = c.c_customer_sk
        AND wp.wp_creation_date_sk = d.d_date_sk
    WHERE d.d_year = 2000
      AND s.s_city = 'Fairfield'
      AND cd.cd_gender = 'M'
      AND p.p_discount_active = 'Y'
      AND i.inv_quantity_on_hand > 0
      AND t.t_hour BETWEEN 9 AND 17
      AND ss.ss_net_paid > 50
),
agg_sales AS (
    SELECT
        c_customer_sk,
        c_customer_id,
        c_first_name,
        c_last_name,
        s_store_id,
        s_city,
        SUM(ss_quantity) AS total_quantity,
        SUM(ss_net_paid) AS total_net_paid
    FROM sales_data
    GROUP BY
        c_customer_sk,
        c_customer_id,
        c_first_name,
        c_last_name,
        s_store_id,
        s_city
)
SELECT
    c_customer_id,
    c_first_name,
    c_last_name,
    s_store_id,
    s_city,
    total_quantity,
    total_net_paid,
    CASE WHEN total_net_paid > 500 THEN 'VIP' ELSE 'Regular' END AS customer_segment,
    RANK() OVER (PARTITION BY s_store_id ORDER BY total_net_paid DESC) AS store_rank,
    ROW_NUMBER() OVER (ORDER BY total_net_paid DESC) AS global_rank
FROM agg_sales
WHERE NOT EXISTS (
    SELECT 1
    FROM catalog_returns cr2
    WHERE cr2.cr_refunded_customer_sk = agg_sales.c_customer_sk
)
ORDER BY total_net_paid DESC
LIMIT 100
