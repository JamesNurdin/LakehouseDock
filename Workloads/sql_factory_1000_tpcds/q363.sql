WITH promo_sales AS (
    SELECT
        p.p_promo_sk,
        p.p_promo_name,
        p.p_discount_active,
        cd.cd_gender,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_net_profit) AS total_profit,
        AVG(ss.ss_ext_discount_amt) AS avg_discount,
        COUNT(*) AS transaction_cnt
    FROM store_sales ss
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    GROUP BY p.p_promo_sk, p.p_promo_name, p.p_discount_active, cd.cd_gender
),
ranked_promos AS (
    SELECT
        p_promo_sk,
        p_promo_name,
        cd_gender,
        total_sales,
        total_profit,
        avg_discount,
        transaction_cnt,
        RANK() OVER (PARTITION BY cd_gender ORDER BY total_profit DESC) AS profit_rank,
        CASE WHEN p_discount_active = 'Y' AND avg_discount > 5 THEN 'High Discount' ELSE 'Standard' END AS discount_category
    FROM promo_sales
)
SELECT
    p_promo_sk,
    p_promo_name,
    cd_gender,
    total_sales,
    total_profit,
    avg_discount,
    transaction_cnt,
    profit_rank,
    discount_category
FROM ranked_promos
WHERE profit_rank <= 3
ORDER BY cd_gender, profit_rank
