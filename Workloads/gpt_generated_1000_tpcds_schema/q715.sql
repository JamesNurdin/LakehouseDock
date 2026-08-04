WITH agg_cat AS (
    SELECT
        cs_promo_sk,
        cs_warehouse_sk,
        cs_ship_mode_sk,
        sum(cs_net_paid) AS total_net_paid,
        count(*) AS cat_sales_cnt
    FROM catalog_sales TABLESAMPLE BERNOULLI (10)
    WHERE cs_quantity > 2
      AND cs_net_profit > 0
      AND cs_ship_mode_sk IS NOT NULL
    GROUP BY cs_promo_sk, cs_warehouse_sk, cs_ship_mode_sk
)
SELECT
    p.p_promo_name,
    w.w_warehouse_name,
    sm.sm_ship_mode_id,
    ca.ca_city,
    hd.hd_vehicle_count,
    ib.ib_lower_bound,
    agg.total_net_paid,
    agg.cat_sales_cnt,
    ss.ss_net_paid AS store_net_paid,
    RANK() OVER (ORDER BY agg.total_net_paid DESC) AS revenue_rank
FROM promotion p
FULL OUTER JOIN store_sales ss
    ON p.p_promo_sk = ss.ss_promo_sk
LEFT JOIN household_demographics hd
    ON ss.ss_hdemo_sk = hd.hd_demo_sk
LEFT JOIN income_band ib
    ON hd.hd_income_band_sk = ib.ib_income_band_sk
LEFT JOIN customer_address ca
    ON ss.ss_addr_sk = ca.ca_address_sk
LEFT JOIN agg_cat agg
    ON p.p_promo_sk = agg.cs_promo_sk
LEFT JOIN warehouse w
    ON agg.cs_warehouse_sk = w.w_warehouse_sk
LEFT JOIN ship_mode sm
    ON agg.cs_ship_mode_sk = sm.sm_ship_mode_sk
WHERE ca.ca_state = 'CA'
  AND w.w_state = 'CA'
  AND ib.ib_upper_bound <= 100000
  AND NOT EXISTS (
        SELECT 1
        FROM income_band ib2
        WHERE ib2.ib_income_band_sk = hd.hd_income_band_sk
          AND ib2.ib_lower_bound > 50000
    )
ORDER BY revenue_rank
LIMIT 100
