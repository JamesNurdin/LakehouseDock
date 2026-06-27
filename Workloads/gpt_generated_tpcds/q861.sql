SELECT
  ds.d_year,
  ds.d_quarter_seq,
  cc.cc_state,
  i.i_category,
  SUM(cs.cs_net_profit) AS total_net_profit,
  SUM(cs.cs_net_paid) AS total_net_paid,
  AVG(cs.cs_ext_discount_amt) AS avg_discount_amount
FROM catalog_sales cs
JOIN date_dim ds ON cs.cs_sold_date_sk = ds.d_date_sk
JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
JOIN date_dim dp_start ON p.p_start_date_sk = dp_start.d_date_sk
JOIN date_dim dp_end ON p.p_end_date_sk = dp_end.d_date_sk
JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN item i ON cs.cs_item_sk = i.i_item_sk
WHERE sm.sm_type = 'AIR'
  AND ds.d_date >= DATE '2000-01-01'
  AND ds.d_date <= DATE '2000-12-31'
  AND ds.d_date >= dp_start.d_date
  AND ds.d_date <= dp_end.d_date
GROUP BY ds.d_year, ds.d_quarter_seq, cc.cc_state, i.i_category
ORDER BY total_net_profit DESC
LIMIT 20
