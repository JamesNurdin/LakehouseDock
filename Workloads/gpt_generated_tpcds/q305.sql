WITH promo_stats AS (
    SELECT
        p.p_promo_id,
        p.p_promo_name,
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT c.c_customer_sk) AS distinct_customers,
        SUM(ss.ss_quantity) AS total_quantity,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_ext_discount_amt) AS total_discount,
        SUM(ss.ss_net_profit) AS total_profit,
        AVG(ss.ss_ext_discount_amt) AS avg_discount_per_transaction
    FROM store_sales ss
    JOIN promotion p
        ON ss.ss_promo_sk = p.p_promo_sk
    JOIN customer c
        ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd
        ON ss.ss_cdemo_sk = cd.cd_demo_sk
    WHERE p.p_discount_active = 'Y'
    GROUP BY p.p_promo_id, p.p_promo_name, cd.cd_gender, cd.cd_marital_status
)
SELECT
    p_promo_id,
    p_promo_name,
    cd_gender,
    cd_marital_status,
    distinct_customers,
    total_quantity,
    total_sales,
    total_discount,
    total_profit,
    avg_discount_per_transaction
FROM promo_stats
ORDER BY total_profit DESC
LIMIT 10
