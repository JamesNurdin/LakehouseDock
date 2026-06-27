SELECT
    i.i_category,
    p.p_channel_email,
    sm.sm_type,
    cc.cc_name,
    sum(cs.cs_net_paid) AS total_net_paid,
    sum(cr.cr_return_amount) AS total_return_amount,
    sum(cs.cs_net_profit) AS total_net_profit,
    sum(cr.cr_net_loss) AS total_net_loss,
    sum(cs.cs_net_profit) - sum(cr.cr_net_loss) AS net_profit_after_returns,
    count(distinct cs.cs_order_number) AS order_count,
    (sum(cs.cs_net_profit) - sum(cr.cr_net_loss)) / nullif(count(distinct cs.cs_order_number), 0) AS avg_profit_per_order
FROM catalog_sales cs
JOIN catalog_returns cr
  ON cs.cs_order_number = cr.cr_order_number
JOIN item i
  ON cs.cs_item_sk = i.i_item_sk
JOIN promotion p
  ON cs.cs_promo_sk = p.p_promo_sk
JOIN ship_mode sm
  ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN call_center cc
  ON cs.cs_call_center_sk = cc.cc_call_center_sk
WHERE p.p_channel_email = 'Y'
GROUP BY
    i.i_category,
    p.p_channel_email,
    sm.sm_type,
    cc.cc_name
ORDER BY net_profit_after_returns DESC
LIMIT 100
