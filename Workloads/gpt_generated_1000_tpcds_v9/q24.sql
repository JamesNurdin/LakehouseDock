SELECT
  cs.cs_order_number,
  cs.cs_item_sk,
  cs.cs_promo_sk,
  cs.cs_net_profit,
  hd.hd_income_band_sk,
  hd.hd_dep_count,
  hd.hd_vehicle_count,
  sm.sm_type,
  sm.sm_carrier,
  wp.wp_web_page_id,
  wp.wp_char_count,
  CASE
    WHEN cs.cs_net_profit > (SELECT AVG(cs2.cs_net_profit) FROM catalog_sales cs2) THEN 'HIGH'
    ELSE 'LOW'
  END AS profit_category,
  ROW_NUMBER() OVER (PARTITION BY sm.sm_type ORDER BY cs.cs_net_profit DESC) AS profit_rank_by_ship_type
FROM catalog_sales cs
INNER JOIN household_demographics hd
  ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
INNER JOIN ship_mode sm
  ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
LEFT JOIN web_returns wr
  ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
LEFT JOIN web_page wp
  ON wr.wr_web_page_sk = wp.wp_web_page_sk
     AND wp.wp_rec_end_date >= DATE '1999-09-01'
     AND wp.wp_char_count > 1500
WHERE cs.cs_item_sk IN (126625, 97993)
  AND cs.cs_promo_sk BETWEEN 1000 AND 1700
  AND sm.sm_type = 'EXPRESS'
  AND sm.sm_carrier = 'UPS'
  AND hd.hd_dep_count >= 2
ORDER BY profit_rank_by_ship_type, cs.cs_net_profit DESC
LIMIT 100
