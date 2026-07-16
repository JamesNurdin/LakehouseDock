WITH store_profit AS (
  SELECT
    d.d_year,
    s.s_state AS region,
    i.i_class AS item_class,
    SUM(ss.ss_net_profit) AS profit
  FROM store_sales ss
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN store s ON ss.ss_store_sk = s.s_store_sk
  JOIN item i ON ss.ss_item_sk = i.i_item_sk
  WHERE d.d_year BETWEEN 1999 AND 2001
  GROUP BY d.d_year, s.s_state, i.i_class
),
store_loss AS (
  SELECT
    d.d_year,
    s.s_state AS region,
    i.i_class AS item_class,
    SUM(sr.sr_net_loss) AS loss
  FROM store_returns sr
  JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
  JOIN store s ON sr.sr_store_sk = s.s_store_sk
  JOIN item i ON sr.sr_item_sk = i.i_item_sk
  WHERE d.d_year BETWEEN 1999 AND 2001
  GROUP BY d.d_year, s.s_state, i.i_class
),
catalog_profit AS (
  SELECT
    d.d_year,
    cc.cc_state AS region,
    i.i_class AS item_class,
    SUM(cs.cs_net_profit) AS profit
  FROM catalog_sales cs
  JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
  JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
  JOIN item i ON cs.cs_item_sk = i.i_item_sk
  WHERE d.d_year BETWEEN 1999 AND 2001
  GROUP BY d.d_year, cc.cc_state, i.i_class
),
catalog_loss AS (
  SELECT
    d.d_year,
    cc.cc_state AS region,
    i.i_class AS item_class,
    SUM(cr.cr_net_loss) AS loss
  FROM catalog_returns cr
  JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
  JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
  JOIN item i ON cr.cr_item_sk = i.i_item_sk
  WHERE d.d_year BETWEEN 1999 AND 2001
  GROUP BY d.d_year, cc.cc_state, i.i_class
),
web_profit AS (
  SELECT
    d.d_year,
    w.w_state AS region,
    i.i_class AS item_class,
    SUM(ws.ws_net_profit) AS profit
  FROM web_sales ws
  JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
  JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
  JOIN item i ON ws.ws_item_sk = i.i_item_sk
  WHERE d.d_year BETWEEN 1999 AND 2001
  GROUP BY d.d_year, w.w_state, i.i_class
),
web_loss AS (
  SELECT
    d.d_year,
    w.w_state AS region,
    i.i_class AS item_class,
    SUM(wr.wr_net_loss) AS loss
  FROM web_returns wr
  JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
  JOIN (
    SELECT ws.ws_web_page_sk, ws.ws_sold_date_sk, ws.ws_warehouse_sk,
           ROW_NUMBER() OVER (PARTITION BY ws.ws_web_page_sk, ws.ws_sold_date_sk ORDER BY ws.ws_sold_date_sk) AS rn
    FROM web_sales ws
  ) ws_map
    ON ws_map.ws_web_page_sk = wr.wr_web_page_sk
    AND ws_map.ws_sold_date_sk = d.d_date_sk
    AND ws_map.rn = 1
  JOIN warehouse w ON ws_map.ws_warehouse_sk = w.w_warehouse_sk
  JOIN item i ON wr.wr_item_sk = i.i_item_sk
  WHERE d.d_year BETWEEN 1999 AND 2001
  GROUP BY d.d_year, w.w_state, i.i_class
),
combined AS (
  SELECT
    sp.d_year,
    sp.region,
    sp.item_class,
    'store' AS channel,
    sp.profit,
    COALESCE(sl.loss, 0) AS loss
  FROM store_profit sp
  LEFT JOIN store_loss sl
    ON sp.d_year = sl.d_year
    AND sp.region = sl.region
    AND sp.item_class = sl.item_class
  UNION ALL
  SELECT
    cp.d_year,
    cp.region,
    cp.item_class,
    'catalog' AS channel,
    cp.profit,
    COALESCE(cl.loss, 0) AS loss
  FROM catalog_profit cp
  LEFT JOIN catalog_loss cl
    ON cp.d_year = cl.d_year
    AND cp.region = cl.region
    AND cp.item_class = cl.item_class
  UNION ALL
  SELECT
    wp.d_year,
    wp.region,
    wp.item_class,
    'web' AS channel,
    wp.profit,
    COALESCE(wl.loss, 0) AS loss
  FROM web_profit wp
  LEFT JOIN web_loss wl
    ON wp.d_year = wl.d_year
    AND wp.region = wl.region
    AND wp.item_class = wl.item_class
)
SELECT
  d_year,
  region,
  item_class,
  channel,
  total_profit,
  total_loss,
  net_profit,
  ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY net_profit DESC) AS rank_by_net_profit
FROM (
  SELECT
    d_year,
    region,
    item_class,
    channel,
    SUM(profit) AS total_profit,
    SUM(loss) AS total_loss,
    SUM(profit) - SUM(loss) AS net_profit
  FROM combined
  GROUP BY d_year, region, item_class, channel
) t
ORDER BY d_year, net_profit DESC
LIMIT 100
