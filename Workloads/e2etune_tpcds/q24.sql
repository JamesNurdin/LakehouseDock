WITH store_agg AS (
  SELECT
    ss.ss_promo_sk,
    hd.hd_income_band_sk,
    hd.hd_vehicle_count,
    SUM(ss.ss_net_profit) AS store_net_profit,
    SUM(ss.ss_quantity) AS store_units,
    COUNT(DISTINCT ss.ss_ticket_number) AS store_transactions
  FROM store_sales ss
  JOIN household_demographics hd
    ON ss.ss_hdemo_sk = hd.hd_demo_sk
  GROUP BY ss.ss_promo_sk, hd.hd_income_band_sk, hd.hd_vehicle_count
),
web_agg AS (
  SELECT
    ws.ws_promo_sk,
    hd.hd_income_band_sk,
    hd.hd_vehicle_count,
    SUM(ws.ws_net_profit) AS web_net_profit,
    SUM(ws.ws_quantity) AS web_units,
    COUNT(DISTINCT ws.ws_order_number) AS web_transactions,
    AVG(wp.wp_char_count) AS avg_page_char_count
  FROM web_sales ws
  JOIN household_demographics hd
    ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
  JOIN web_page wp
    ON ws.ws_web_page_sk = wp.wp_web_page_sk
  GROUP BY ws.ws_promo_sk, hd.hd_income_band_sk, hd.hd_vehicle_count
)
SELECT
    t.p_promo_id,
    t.p_promo_name,
    t.income_band_sk,
    t.vehicle_count,
    t.total_net_profit,
    t.total_units,
    t.total_transactions,
    t.avg_page_char_count
FROM (
  SELECT
    p.p_promo_id,
    p.p_promo_name,
    COALESCE(sa.hd_income_band_sk, wa.hd_income_band_sk) AS income_band_sk,
    COALESCE(sa.hd_vehicle_count, wa.hd_vehicle_count) AS vehicle_count,
    COALESCE(sa.store_net_profit, 0) + COALESCE(wa.web_net_profit, 0) AS total_net_profit,
    COALESCE(sa.store_units, 0) + COALESCE(wa.web_units, 0) AS total_units,
    COALESCE(sa.store_transactions, 0) + COALESCE(wa.web_transactions, 0) AS total_transactions,
    COALESCE(wa.avg_page_char_count, 0) AS avg_page_char_count
  FROM promotion p
  LEFT JOIN store_agg sa
    ON p.p_promo_sk = sa.ss_promo_sk
  LEFT JOIN web_agg wa
    ON p.p_promo_sk = wa.ws_promo_sk
  WHERE p.p_discount_active = 'N'
    AND (COALESCE(sa.hd_income_band_sk, wa.hd_income_band_sk) IN (3,4,5))
    AND (COALESCE(sa.hd_vehicle_count, wa.hd_vehicle_count) >= 2)
) t
WHERE t.total_net_profit > 20000
ORDER BY t.total_net_profit DESC
LIMIT 100
