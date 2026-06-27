WITH promo_sales AS (
    SELECT
        ss.ss_promo_sk,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_net_profit) AS total_profit,
        SUM(ss.ss_ext_discount_amt) AS total_discount,
        COUNT(*) AS transaction_count,
        COUNT(DISTINCT ss.ss_item_sk) AS distinct_items_sold
    FROM store_sales ss
    GROUP BY ss.ss_promo_sk
)
SELECT
    p.p_promo_id,
    p.p_promo_name,
    p.p_start_date_sk,
    p.p_end_date_sk,
    ps.total_sales,
    ps.total_profit,
    ps.total_discount,
    ps.transaction_count,
    ps.distinct_items_sold,
    CASE
        WHEN p.p_cost > 0 THEN ps.total_profit / p.p_cost
        ELSE NULL
    END AS profit_per_promo_cost,
    RANK() OVER (ORDER BY ps.total_sales DESC) AS sales_rank
FROM promotion p
JOIN promo_sales ps
    ON p.p_promo_sk = ps.ss_promo_sk
ORDER BY ps.total_sales DESC
LIMIT 10
