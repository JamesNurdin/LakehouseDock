WITH catalog_agg AS (
  SELECT
    cr.cr_item_sk,
    cr.cr_reason_sk,
    cc.cc_name,
    cc.cc_state,
    p.p_channel_email,
    sm.sm_type AS ship_mode_type,
    SUM(cr.cr_return_amount) AS catalog_return_amount,
    SUM(cr.cr_net_loss) AS catalog_net_loss,
    COUNT(DISTINCT cr.cr_order_number) AS catalog_orders
  FROM catalog_returns cr
  JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
  JOIN item i ON cr.cr_item_sk = i.i_item_sk
  LEFT JOIN promotion p ON i.i_item_sk = p.p_item_sk
  JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
  WHERE cc.cc_state IN ('TN','GA')
    AND i.i_category = 'Electronics'
    AND (p.p_discount_active = 'Y' OR p.p_discount_active IS NULL)
    AND sm.sm_type = 'AIR'
  GROUP BY
    cr.cr_item_sk,
    cr.cr_reason_sk,
    cc.cc_name,
    cc.cc_state,
    p.p_channel_email,
    sm.sm_type
),
web_agg AS (
  SELECT
    wr.wr_item_sk,
    wr.wr_reason_sk,
    SUM(wr.wr_return_amt) AS web_return_amount,
    SUM(wr.wr_net_loss) AS web_net_loss,
    COUNT(DISTINCT wr.wr_order_number) AS web_orders
  FROM web_returns wr
  JOIN item i ON wr.wr_item_sk = i.i_item_sk
  WHERE i.i_category = 'Electronics'
  GROUP BY wr.wr_item_sk, wr.wr_reason_sk
)
SELECT
  ca.cc_name AS call_center_name,
  ca.cc_state,
  ca.p_channel_email AS promo_email_channel,
  ca.ship_mode_type,
  r.r_reason_desc AS return_reason,
  ca.catalog_return_amount,
  wa.web_return_amount,
  ca.catalog_net_loss + COALESCE(wa.web_net_loss, 0) AS total_net_loss,
  ca.catalog_orders,
  wa.web_orders
FROM catalog_agg ca
LEFT JOIN web_agg wa
  ON ca.cr_item_sk = wa.wr_item_sk
  AND ca.cr_reason_sk = wa.wr_reason_sk
JOIN reason r ON ca.cr_reason_sk = r.r_reason_sk
WHERE (ca.catalog_return_amount > 0 OR wa.web_return_amount > 0)
ORDER BY total_net_loss DESC
LIMIT 200
