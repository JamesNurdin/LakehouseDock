WITH
sales AS (
  SELECT 
    ss.ss_sold_date_sk AS date_sk,
    s.s_state AS state,
    s.s_city AS city,
    'store' AS channel,
    ss.ss_item_sk AS item_sk,
    ss.ss_net_profit AS net_profit,
    ss.ss_net_paid AS net_paid
  FROM store_sales ss
  JOIN store s ON ss.ss_store_sk = s.s_store_sk
  UNION ALL
  SELECT 
    ws.ws_sold_date_sk,
    ws_site.web_state,
    ws_site.web_city,
    'web' AS channel,
    ws.ws_item_sk,
    ws.ws_net_profit,
    ws.ws_net_paid
  FROM web_sales ws
  JOIN web_site ws_site ON ws.ws_web_site_sk = ws_site.web_site_sk
  UNION ALL
  SELECT 
    cs.cs_sold_date_sk,
    cc.cc_state,
    cc.cc_city,
    'catalog' AS channel,
    cs.cs_item_sk,
    cs.cs_net_profit,
    cs.cs_net_paid
  FROM catalog_sales cs
  JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
),
sales_agg AS (
  SELECT 
    d.d_year,
    s.state,
    s.city,
    s.channel,
    COUNT(DISTINCT s.item_sk) AS distinct_items_sold,
    SUM(s.net_profit) AS total_profit,
    SUM(s.net_paid) AS total_sales
  FROM sales s
  JOIN date_dim d ON s.date_sk = d.d_date_sk
  GROUP BY d.d_year, s.state, s.city, s.channel
),
returns AS (
  SELECT 
    sr.sr_returned_date_sk AS date_sk,
    s.s_state AS state,
    s.s_city AS city,
    'store' AS channel,
    sr.sr_item_sk AS item_sk,
    sr.sr_net_loss AS net_loss
  FROM store_returns sr
  JOIN store s ON sr.sr_store_sk = s.s_store_sk
  UNION ALL
  SELECT 
    wr.wr_returned_date_sk,
    NULL AS state,
    NULL AS city,
    'web' AS channel,
    wr.wr_item_sk,
    wr.wr_net_loss
  FROM web_returns wr
  UNION ALL
  SELECT 
    cr.cr_returned_date_sk,
    cc.cc_state,
    cc.cc_city,
    'catalog' AS channel,
    cr.cr_item_sk,
    cr.cr_net_loss
  FROM catalog_returns cr
  JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
),
returns_agg AS (
  SELECT 
    d.d_year,
    r.state,
    r.city,
    r.channel,
    SUM(r.net_loss) AS total_loss
  FROM returns r
  JOIN date_dim d ON r.date_sk = d.d_date_sk
  GROUP BY d.d_year, r.state, r.city, r.channel
),
combined AS (
  SELECT 
    sa.d_year,
    sa.state,
    sa.city,
    sa.channel,
    sa.total_profit,
    sa.total_sales,
    COALESCE(ra.total_loss, 0) AS total_loss,
    sa.total_profit - COALESCE(ra.total_loss, 0) AS net_profit_after_losses,
    CASE WHEN sa.total_profit = 0 THEN NULL ELSE COALESCE(ra.total_loss, 0) / sa.total_profit END AS loss_to_profit_ratio,
    sa.distinct_items_sold,
    ROW_NUMBER() OVER (PARTITION BY sa.state, sa.d_year ORDER BY sa.total_profit DESC) AS profit_rank
  FROM sales_agg sa
  LEFT JOIN returns_agg ra
    ON sa.d_year = ra.d_year
   AND sa.state = ra.state
   AND sa.city = ra.city
   AND sa.channel = ra.channel
)
SELECT 
  d_year,
  state,
  city,
  channel,
  total_profit,
  total_sales,
  total_loss,
  net_profit_after_losses,
  loss_to_profit_ratio,
  distinct_items_sold
FROM combined
WHERE profit_rank <= 5
ORDER BY d_year DESC, total_profit DESC
LIMIT 200
