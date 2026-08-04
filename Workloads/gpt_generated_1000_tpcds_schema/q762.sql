WITH agg AS (
    SELECT
        s.s_store_id,
        p.p_promo_id,
        ib.ib_income_band_sk,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_net_profit) AS total_profit,
        COUNT(*) AS txn_count
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE i.i_units IN ('Gram', 'Lb')
      AND p.p_channel_press = 'N'
      AND p.p_channel_radio = 'N'
      AND ib.ib_lower_bound >= 50000
      AND ib.ib_upper_bound <= 150000
      AND s.s_state = 'TX'
      AND ss.ss_ext_tax > 5
    GROUP BY s.s_store_id, p.p_promo_id, ib.ib_income_band_sk
), final AS (
    SELECT
        a.s_store_id,
        a.p_promo_id,
        a.ib_income_band_sk,
        a.total_sales,
        a.total_profit,
        a.txn_count,
        ROW_NUMBER() OVER (ORDER BY a.total_sales DESC) AS rn,
        (SELECT AVG(total_sales) FROM agg) AS avg_sales_all
    FROM agg a
    WHERE a.total_sales > (SELECT AVG(total_sales) FROM agg)
)
SELECT
    s_store_id,
    p_promo_id,
    ib_income_band_sk,
    total_sales,
    total_profit,
    txn_count,
    rn
FROM final
WHERE total_profit > 0
UNION
SELECT
    s_store_id,
    p_promo_id,
    ib_income_band_sk,
    total_sales,
    total_profit,
    txn_count,
    rn
FROM final
WHERE total_profit < 0
ORDER BY rn
OFFSET 0 LIMIT 100
