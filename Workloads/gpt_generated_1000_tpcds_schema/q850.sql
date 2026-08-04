WITH base AS (
  SELECT
    ws.ws_order_number,
    ws.ws_item_sk,
    i.i_category,
    i.i_current_price,
    ws.ws_quantity,
    ws.ws_net_paid,
    ws.ws_net_profit,
    ws.ws_warehouse_sk,
    w.w_warehouse_name,
    w.w_warehouse_sq_ft,
    w.w_state,
    ws.ws_web_site_sk,
    s.web_name,
    s.web_state,
    s.web_country,
    ws.ws_promo_sk,
    p.p_discount_active,
    hd.hd_buy_potential,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    lt.line_total,
    (SELECT SUM(p2.p_cost) FROM promotion p2 WHERE p2.p_promo_sk = ws.ws_promo_sk) AS total_promo_cost
  FROM web_sales ws
  JOIN item i ON ws.ws_item_sk = i.i_item_sk
  JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
  JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
  RIGHT OUTER JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
  JOIN web_site s ON ws.ws_web_site_sk = s.web_site_sk
  LEFT JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
  LEFT JOIN store_returns sr ON sr.sr_item_sk = i.i_item_sk AND sr.sr_hdemo_sk = hd.hd_demo_sk
  CROSS JOIN LATERAL (SELECT ws.ws_quantity * i.i_current_price AS line_total) AS lt
)
SELECT
  category,
  warehouse,
  buy_potential,
  total_net_paid,
  total_net_profit,
  orders_count,
  total_discounted_promo_cost
FROM (
  SELECT
    COALESCE(i_category, 'ALL') AS category,
    COALESCE(w_warehouse_name, 'ALL') AS warehouse,
    COALESCE(hd_buy_potential, 'ALL') AS buy_potential,
    SUM(ws_net_paid) AS total_net_paid,
    SUM(ws_net_profit) AS total_net_profit,
    COUNT(DISTINCT ws_order_number) AS orders_count,
    0.0 AS total_discounted_promo_cost
  FROM base
  WHERE ib_lower_bound >= 50000
    AND i_current_price > 20
    AND ws_quantity BETWEEN 1 AND 10
    AND w_warehouse_sq_ft > 50000
    AND web_state = 'CA'
    AND i_current_price > (SELECT MAX(i2.i_current_price) FROM item i2 WHERE i2.i_brand_id = 1)
  GROUP BY CUBE(i_category, w_warehouse_name, hd_buy_potential)

  UNION DISTINCT

  SELECT
    COALESCE(i_category, 'ALL') AS category,
    COALESCE(w_warehouse_name, 'ALL') AS warehouse,
    COALESCE(hd_buy_potential, 'ALL') AS buy_potential,
    SUM(ws_net_paid) AS total_net_paid,
    SUM(ws_net_profit) AS total_net_profit,
    COUNT(DISTINCT ws_order_number) AS orders_count,
    SUM(CASE WHEN p_discount_active = 'Y' THEN total_promo_cost ELSE 0 END) AS total_discounted_promo_cost
  FROM base
  WHERE ib_upper_bound <= 150000
    AND i_current_price < 100
    AND ws_quantity >= 5
    AND w_state = 'TX'
    AND web_country = 'United States'
    AND i_current_price > (SELECT MIN(i2.i_current_price) FROM item i2 WHERE i2.i_brand_id = 2)
  GROUP BY CUBE(i_category, w_warehouse_name, hd_buy_potential)
) AS combined
ORDER BY total_net_paid DESC
LIMIT 100
