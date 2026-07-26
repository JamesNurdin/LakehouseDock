WITH daily_promo_sales AS (
    SELECT
        ss.ss_sold_date_sk,
        p.p_promo_sk,
        p.p_promo_name,
        SUM(ss.ss_ext_sales_price) AS daily_sales,
        SUM(ss.ss_net_profit) AS daily_profit,
        COUNT(*) AS txn_cnt
    FROM store_sales ss
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    GROUP BY ss.ss_sold_date_sk, p.p_promo_sk, p.p_promo_name
),
ranked_days AS (
    SELECT
        ss_sold_date_sk,
        p_promo_sk,
        p_promo_name,
        daily_sales,
        daily_profit,
        txn_cnt,
        DENSE_RANK() OVER (PARTITION BY p_promo_sk ORDER BY daily_sales DESC) AS sales_day_rank,
        CASE 
            WHEN daily_sales > 10000 THEN 'Big Day'
            ELSE 'Normal Day'
        END AS sales_day_category
    FROM daily_promo_sales
)
SELECT
    ss_sold_date_sk,
    p_promo_sk,
    p_promo_name,
    daily_sales,
    daily_profit,
    txn_cnt,
    sales_day_rank,
    sales_day_category
FROM ranked_days
WHERE sales_day_rank <= 3
ORDER BY p_promo_sk, sales_day_rank
