SELECT
    cs.cs_order_number,
    cs.cs_net_paid,
    cs.cs_quantity,
    d0.d_year AS sold_year,
    d0.d_month_seq AS sold_month_seq,
    s.s_store_name,
    s.s_city,
    s.s_state,
    p_cs.p_promo_name AS catalog_promo_name,
    p_cs.p_discount_active AS catalog_promo_discount_active,
    d_cs_promo_start.d_year AS catalog_promo_start_year,
    d_cs_promo_end.d_year AS catalog_promo_end_year,
    ws.ws_order_number,
    ws.ws_net_paid,
    ws.ws_quantity,
    p_ws.p_promo_name AS web_promo_name,
    p_ws.p_discount_active AS web_promo_discount_active,
    d_ws_promo_start.d_year AS web_promo_start_year,
    d_ws_promo_end.d_year AS web_promo_end_year,
    (cs.cs_net_paid - ws.ws_net_paid) AS net_paid_diff
FROM date_dim d0
JOIN catalog_sales cs
  ON cs.cs_sold_date_sk = d0.d_date_sk
JOIN store s
  ON s.s_closed_date_sk = d0.d_date_sk
JOIN promotion p_cs
  ON cs.cs_promo_sk = p_cs.p_promo_sk
JOIN date_dim d_cs_promo_start
  ON p_cs.p_start_date_sk = d_cs_promo_start.d_date_sk
JOIN date_dim d_cs_promo_end
  ON p_cs.p_end_date_sk = d_cs_promo_end.d_date_sk
JOIN web_sales ws
  ON ws.ws_sold_date_sk = d0.d_date_sk
JOIN promotion p_ws
  ON ws.ws_promo_sk = p_ws.p_promo_sk
JOIN date_dim d_ws_promo_start
  ON p_ws.p_start_date_sk = d_ws_promo_start.d_date_sk
JOIN date_dim d_ws_promo_end
  ON p_ws.p_end_date_sk = d_ws_promo_end.d_date_sk
LIMIT 100
