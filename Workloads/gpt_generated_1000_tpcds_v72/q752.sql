WITH sales_agg AS (
    SELECT
        s.s_store_id,
        p.p_promo_id,
        SUM(ss.ss_net_paid_inc_tax) AS store_promo_sales,
        SUM(ss.ss_net_profit) AS store_promo_profit,
        COUNT(*) AS txn_count
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN catalog_sales cs ON cs.cs_promo_sk = p.p_promo_sk
    WHERE ss.ss_net_paid_inc_tax > 100
      AND ss.ss_quantity >= 1
      AND p.p_purpose <> 'Unknown'
      AND p.p_channel_email = 'Y'
      AND cs.cs_ext_wholesale_cost < 5000
      AND ss.ss_promo_sk IN (SELECT DISTINCT p2.p_promo_sk FROM promotion p2 WHERE p2.p_channel_tv = 'Y')
      AND EXISTS (
          SELECT 1
          FROM ship_mode sm
          WHERE sm.sm_ship_mode_sk = cs.cs_ship_mode_sk
            AND sm.sm_type = 'AIR'
      )
    GROUP BY s.s_store_id, p.p_promo_id
)
SELECT
    s_store_id,
    p_promo_id,
    store_promo_sales,
    store_promo_profit,
    txn_count,
    DENSE_RANK() OVER (ORDER BY store_promo_profit DESC) AS profit_rank,
    CASE
        WHEN store_promo_sales > (SELECT AVG(store_promo_sales) FROM sales_agg) THEN 'Above Avg'
        ELSE 'Below Avg'
    END AS sales_category
FROM sales_agg
WHERE store_promo_profit > 1000
ORDER BY profit_rank
LIMIT 50
