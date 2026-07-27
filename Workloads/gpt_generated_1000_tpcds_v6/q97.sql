WITH ss_agg AS (
    SELECT
        ss_store_sk,
        ss_promo_sk,
        ss_hdemo_sk,
        SUM(ss_net_profit) AS total_net_profit,
        SUM(ss_quantity) AS total_quantity
    FROM tpcds.store_sales
    WHERE ss_coupon_amt > 100
      AND ss_list_price BETWEEN 10 AND 200
      AND ss_ext_tax > 0
    GROUP BY ss_store_sk, ss_promo_sk, ss_hdemo_sk
)
SELECT
    s.s_store_id,
    s.s_city,
    p.p_promo_id,
    cp.cp_catalog_page_id,
    hd.hd_income_band_sk,
    agg.total_net_profit,
    agg.total_quantity,
    (
        SELECT AVG(inner_agg.total_net_profit)
        FROM ss_agg inner_agg
        WHERE inner_agg.ss_store_sk = s.s_store_sk
    ) AS avg_store_profit,
    COUNT(DISTINCT cr.cr_order_number) AS distinct_return_orders
FROM ss_agg agg
JOIN tpcds.household_demographics hd
    ON agg.ss_hdemo_sk = hd.hd_demo_sk
JOIN tpcds.store s
    ON agg.ss_store_sk = s.s_store_sk
JOIN tpcds.promotion p
    ON agg.ss_promo_sk = p.p_promo_sk
JOIN tpcds.catalog_returns cr
    ON hd.hd_demo_sk = cr.cr_returning_hdemo_sk
JOIN tpcds.catalog_page cp
    ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
WHERE p.p_channel_dmail = 'Y'
  AND p.p_discount_active = 'Y'
  AND hd.hd_vehicle_count >= 2
  AND s.s_state = 'CA'
  AND cr.cr_return_quantity > 1
  AND cp.cp_type = 'A'
GROUP BY
    s.s_store_id,
    s.s_city,
    p.p_promo_id,
    cp.cp_catalog_page_id,
    hd.hd_income_band_sk,
    agg.total_net_profit,
    agg.total_quantity,
    s.s_store_sk
HAVING agg.total_net_profit > (
    SELECT AVG(inner_agg.total_net_profit)
    FROM ss_agg inner_agg
    WHERE inner_agg.ss_store_sk = s.s_store_sk
)
ORDER BY agg.total_net_profit DESC
LIMIT 100
