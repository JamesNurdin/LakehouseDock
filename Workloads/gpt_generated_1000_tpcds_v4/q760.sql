WITH joined AS (
  SELECT
    cs.cs_sold_date_sk,
    cs.cs_order_number,
    cs.cs_net_paid,
    cs.cs_net_profit,
    i.i_brand,
    i.i_category,
    p.p_channel_catalog,
    cc.cc_name,
    sm.sm_type,
    c.c_customer_id,
    cd.cd_gender,
    s.s_store_id,
    s.s_state,
    r.r_reason_desc,
    sr.sr_return_amt,
    wr.wr_return_amt,
    wp.wp_type,
    t.t_hour
  FROM catalog_sales cs
  JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
  JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
  JOIN item i ON cs.cs_item_sk = i.i_item_sk
  JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
  JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
  JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
  JOIN store_returns sr ON sr.sr_item_sk = i.i_item_sk
  JOIN store s ON sr.sr_store_sk = s.s_store_sk
  JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
  JOIN web_returns wr ON wr.wr_item_sk = i.i_item_sk
  JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
  JOIN time_dim t2 ON wr.wr_returned_time_sk = t2.t_time_sk
  WHERE s.s_state = 'CA'
    AND p.p_channel_catalog = 'N'
    AND t.t_hour BETWEEN 9 AND 17
)
SELECT
  i_brand,
  i_category,
  s_state,
  t_hour,
  COUNT(DISTINCT cs_order_number) AS order_cnt,
  SUM(cs_net_paid) AS total_sales,
  SUM(sr_return_amt) AS total_store_returns,
  SUM(wr_return_amt) AS total_web_returns,
  CASE WHEN SUM(cs_net_profit) > 0 THEN 'Profit' ELSE 'Loss' END AS profit_status
FROM joined
GROUP BY i_brand, i_category, s_state, t_hour
ORDER BY total_sales DESC
LIMIT 100
