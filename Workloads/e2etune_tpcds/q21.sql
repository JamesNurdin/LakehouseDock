WITH sales_agg AS (
    SELECT
        ss.ss_sold_time_sk AS sold_time_sk,
        ss.ss_hdemo_sk AS hdemo_sk,
        ss.ss_promo_sk AS promo_sk,
        SUM(ss.ss_net_profit) AS total_net_profit,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        COUNT(*) AS txn_count,
        AVG(ss.ss_quantity) AS avg_quantity
    FROM store_sales ss
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE p.p_discount_active = 'Y'
      AND p.p_response_target = 1
      AND ss.ss_quantity > 0
    GROUP BY ss.ss_sold_time_sk, ss.ss_hdemo_sk, ss.ss_promo_sk
    HAVING SUM(ss.ss_net_profit) > 500
)
SELECT
    t.t_hour,
    hd.hd_income_band_sk,
    hd.hd_buy_potential,
    p.p_promo_name,
    sa.total_net_profit,
    sa.total_sales,
    sa.txn_count,
    sa.avg_quantity,
    RANK() OVER (PARTITION BY hd.hd_income_band_sk ORDER BY sa.total_net_profit DESC) AS profit_rank
FROM sales_agg sa
JOIN time_dim t ON sa.sold_time_sk = t.t_time_sk
JOIN household_demographics hd ON sa.hdemo_sk = hd.hd_demo_sk
JOIN promotion p ON sa.promo_sk = p.p_promo_sk
WHERE t.t_hour BETWEEN 9 AND 21
ORDER BY hd.hd_income_band_sk, profit_rank, t.t_hour
