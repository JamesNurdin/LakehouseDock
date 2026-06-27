WITH sales_agg AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        p.p_promo_id,
        p.p_promo_name,
        t.t_hour,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_ext_discount_amt) AS total_discount,
        SUM(ss.ss_net_profit) AS total_profit,
        COUNT(*) AS transaction_cnt
    FROM store_sales ss
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    JOIN promotion p
        ON ss.ss_promo_sk = p.p_promo_sk
    JOIN time_dim t
        ON ss.ss_sold_time_sk = t.t_time_sk
    WHERE ss.ss_quantity > 0
    GROUP BY
        s.s_store_id,
        s.s_store_name,
        p.p_promo_id,
        p.p_promo_name,
        t.t_hour
)
SELECT
    s_store_id,
    s_store_name,
    p_promo_id,
    p_promo_name,
    t_hour,
    total_sales,
    total_discount,
    total_profit,
    transaction_cnt,
    total_profit / NULLIF(total_sales, 0) AS profit_margin,
    ROW_NUMBER() OVER (PARTITION BY p_promo_id ORDER BY total_profit DESC) AS profit_rank_by_promo
FROM sales_agg
WHERE total_sales > 1000
ORDER BY p_promo_id, profit_rank_by_promo
