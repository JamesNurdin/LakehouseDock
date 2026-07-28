WITH sales_enriched AS (
    SELECT
        ss.ss_store_sk,
        ss.ss_sold_date_sk,
        ss.ss_sold_time_sk,
        ss.ss_item_sk,
        ss.ss_quantity,
        ss.ss_net_paid,
        ss.ss_net_profit,
        t.t_shift,
        t.t_time,
        p.p_promo_id,
        p.p_channel_catalog,
        p.p_purpose,
        p.p_discount_active
    FROM store_sales ss
    INNER JOIN time_dim t
        ON ss.ss_sold_time_sk = t.t_time_sk
    LEFT JOIN promotion p
        ON ss.ss_promo_sk = p.p_promo_sk
    WHERE ss.ss_store_sk IN (235, 338, 688, 535)
      AND ss.ss_wholesale_cost > 10.00
      AND t.t_shift IN ('second', 'third')
      AND (p.p_channel_catalog = 'N' OR p.p_channel_catalog IS NULL)
      AND (p.p_purpose = 'Unknown' OR p.p_purpose IS NULL)
)
SELECT
    ss_enriched.ss_store_sk,
    ss_enriched.t_shift,
    COUNT(DISTINCT ss_enriched.p_promo_id) AS distinct_promos,
    SUM(ss_enriched.ss_quantity) AS total_quantity,
    SUM(ss_enriched.ss_net_paid) AS total_net_paid,
    SUM(ss_enriched.ss_net_profit) AS total_net_profit,
    RANK() OVER (PARTITION BY ss_enriched.t_shift ORDER BY SUM(ss_enriched.ss_net_profit) DESC) AS profit_rank_per_shift
FROM sales_enriched ss_enriched
GROUP BY ss_enriched.ss_store_sk, ss_enriched.t_shift
HAVING SUM(ss_enriched.ss_net_paid) > 5000
ORDER BY profit_rank_per_shift
LIMIT 100
