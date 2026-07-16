WITH sales_by_channel AS (
  SELECT
    d.d_date,
    i.i_category,
    i.i_category_id,
    'store' AS channel,
    SUM(ss.ss_net_profit) AS net_profit,
    SUM(ss.ss_quantity) AS total_quantity,
    COUNT(DISTINCT ss.ss_ticket_number) AS order_count
  FROM store_sales ss
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN item i ON ss.ss_item_sk = i.i_item_sk
  GROUP BY d.d_date, i.i_category, i.i_category_id
  UNION ALL
  SELECT
    d.d_date,
    i.i_category,
    i.i_category_id,
    'catalog' AS channel,
    SUM(cs.cs_net_profit) AS net_profit,
    SUM(cs.cs_quantity) AS total_quantity,
    COUNT(DISTINCT cs.cs_order_number) AS order_count
  FROM catalog_sales cs
  JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
  JOIN item i ON cs.cs_item_sk = i.i_item_sk
  GROUP BY d.d_date, i.i_category, i.i_category_id
  UNION ALL
  SELECT
    d.d_date,
    i.i_category,
    i.i_category_id,
    'web' AS channel,
    SUM(ws.ws_net_profit) AS net_profit,
    SUM(ws.ws_quantity) AS total_quantity,
    COUNT(DISTINCT ws.ws_order_number) AS order_count
  FROM web_sales ws
  JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
  JOIN item i ON ws.ws_item_sk = i.i_item_sk
  GROUP BY d.d_date, i.i_category, i.i_category_id
),
returns_by_channel AS (
  SELECT
    d.d_date,
    i.i_category,
    i.i_category_id,
    'store' AS channel,
    SUM(sr.sr_net_loss) AS net_loss,
    SUM(sr.sr_return_quantity) AS return_quantity
  FROM store_returns sr
  JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
  JOIN item i ON sr.sr_item_sk = i.i_item_sk
  GROUP BY d.d_date, i.i_category, i.i_category_id
  UNION ALL
  SELECT
    d.d_date,
    i.i_category,
    i.i_category_id,
    'catalog' AS channel,
    SUM(cr.cr_net_loss) AS net_loss,
    SUM(cr.cr_return_quantity) AS return_quantity
  FROM catalog_returns cr
  JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
  JOIN item i ON cr.cr_item_sk = i.i_item_sk
  GROUP BY d.d_date, i.i_category, i.i_category_id
  UNION ALL
  SELECT
    d.d_date,
    i.i_category,
    i.i_category_id,
    'web' AS channel,
    SUM(wr.wr_net_loss) AS net_loss,
    SUM(wr.wr_return_quantity) AS return_quantity
  FROM web_returns wr
  JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
  JOIN item i ON wr.wr_item_sk = i.i_item_sk
  GROUP BY d.d_date, i.i_category, i.i_category_id
),
combined AS (
  SELECT
    sbc.d_date,
    sbc.i_category,
    sbc.channel,
    sbc.net_profit,
    COALESCE(rbc.net_loss, 0) AS net_loss,
    sbc.total_quantity,
    COALESCE(rbc.return_quantity, 0) AS return_quantity,
    (sbc.net_profit - COALESCE(rbc.net_loss, 0)) AS net_contribution,
    CONCAT(sbc.channel, '_', sbc.i_category) AS channel_category_key,
    CASE 
      WHEN (sbc.net_profit - COALESCE(rbc.net_loss, 0)) > 100000 THEN 'HIGH'
      WHEN (sbc.net_profit - COALESCE(rbc.net_loss, 0)) BETWEEN 0 AND 100000 THEN 'MEDIUM'
      ELSE 'LOW'
    END AS profit_tier
  FROM sales_by_channel sbc
  LEFT JOIN returns_by_channel rbc
    ON sbc.d_date = rbc.d_date
    AND sbc.i_category = rbc.i_category
    AND sbc.channel = rbc.channel
),
ranked AS (
  SELECT
    *,
    ROW_NUMBER() OVER (PARTITION BY channel ORDER BY net_contribution DESC) AS rank_by_channel,
    RANK() OVER (PARTITION BY i_category ORDER BY net_contribution DESC) AS rank_by_category
  FROM combined
),
final AS (
  SELECT
    r.d_date,
    r.i_category,
    r.channel,
    r.net_contribution,
    r.profit_tier,
    r.rank_by_channel,
    r.rank_by_category,
    (SELECT MAX(net_contribution) FROM combined c2 WHERE c2.d_date = r.d_date) AS max_contribution_same_day,
    cc.cc_name AS call_center_name,
    COALESCE(cc.cc_gmt_offset, 0) AS call_center_gmt_offset,
    CONCAT(CAST(r.d_date AS varchar), '_', r.channel) AS date_channel_token
  FROM ranked r
  LEFT JOIN call_center cc
    ON (r.channel = 'store' AND cc.cc_call_center_sk = (SELECT MAX(cc_call_center_sk) FROM call_center WHERE cc_closed_date_sk IS NULL))
     OR (r.channel = 'catalog' AND cc.cc_call_center_sk = (SELECT MIN(cc_call_center_sk) FROM call_center WHERE cc_open_date_sk IS NOT NULL))
     OR (r.channel = 'web' AND cc.cc_call_center_sk = CAST((SELECT AVG(cc_call_center_sk) FROM call_center) AS integer))
)
SELECT
  f.d_date,
  f.i_category,
  f.channel,
  f.net_contribution,
  f.profit_tier,
  f.rank_by_channel,
  f.rank_by_category,
  f.max_contribution_same_day,
  f.call_center_name,
  f.call_center_gmt_offset,
  f.date_channel_token,
  CASE
    WHEN f.call_center_name IS NULL THEN 'NO_CC'
    WHEN f.profit_tier = 'HIGH' THEN 'ALERT_HIGH'
    ELSE 'NORMAL'
  END AS status_flag
FROM final f
WHERE f.net_contribution IS NOT NULL
ORDER BY f.d_date DESC, f.net_contribution DESC
LIMIT 100
