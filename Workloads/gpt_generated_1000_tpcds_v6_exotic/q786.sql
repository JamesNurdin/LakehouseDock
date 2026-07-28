WITH filtered_sales AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_sold_time_sk,
        ss.ss_item_sk,
        ss.ss_customer_sk,
        ss.ss_cdemo_sk,
        ss.ss_hdemo_sk,
        ss.ss_addr_sk,
        ss.ss_store_sk,
        ss.ss_promo_sk,
        ss.ss_ticket_number,
        ss.ss_quantity,
        ss.ss_wholesale_cost,
        ss.ss_list_price,
        ss.ss_sales_price,
        ss.ss_ext_discount_amt,
        ss.ss_ext_sales_price,
        ss.ss_ext_wholesale_cost,
        ss.ss_ext_list_price,
        ss.ss_ext_tax,
        ss.ss_coupon_amt,
        ss.ss_net_paid,
        ss.ss_net_paid_inc_tax,
        ss.ss_net_profit,
        cd.cd_gender,
        cd.cd_education_status,
        cd.cd_dep_count,
        p.p_channel_demo,
        p.p_discount_active,
        t.t_meal_time,
        t.t_shift,
        s.s_store_name,
        s.s_state
    FROM store_sales ss
    JOIN time_dim t
        ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN promotion p
        ON ss.ss_promo_sk = p.p_promo_sk
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    JOIN customer_demographics cd
        ON ss.ss_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_gender = 'M'
      AND cd.cd_education_status = 'College'
      AND p.p_channel_demo = 'Y'
      AND t.t_meal_time = 'lunch'
      AND s.s_state = 'CA'
)
SELECT
    s_store_name,
    s_state,
    t_shift,
    CASE
        WHEN cd_dep_count = 0 THEN 'No Dependents'
        WHEN cd_dep_count <= 2 THEN 'Few Dependents'
        ELSE 'Many Dependents'
    END AS dep_category,
    COUNT(DISTINCT ss_customer_sk) AS unique_customers,
    SUM(ss_ext_sales_price) AS total_sales,
    AVG(ss_net_profit) AS avg_profit,
    MIN(ss_ext_sales_price) AS min_sale,
    MAX(ss_ext_sales_price) AS max_sale
FROM filtered_sales
GROUP BY
    s_store_name,
    s_state,
    t_shift,
    CASE
        WHEN cd_dep_count = 0 THEN 'No Dependents'
        WHEN cd_dep_count <= 2 THEN 'Few Dependents'
        ELSE 'Many Dependents'
    END
ORDER BY total_sales DESC
LIMIT 50
