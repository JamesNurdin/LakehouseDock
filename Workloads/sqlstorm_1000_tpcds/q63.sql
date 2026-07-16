WITH
store_sales_agg AS (
 SELECT d.d_year,
        d.d_moy,
        i.i_category,
        s.s_state AS region,
        'store' AS channel,
        SUM(ss.ss_net_paid) AS total_sales,
        SUM(ss.ss_net_profit) AS total_profit
 FROM store_sales ss
 JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
 JOIN item i ON ss.ss_item_sk = i.i_item_sk
 JOIN store s ON ss.ss_store_sk = s.s_store_sk
 WHERE d.d_year BETWEEN 1999 AND 2000
 GROUP BY d.d_year, d.d_moy, i.i_category, s.s_state
),
store_returns_agg AS (
 SELECT d.d_year,
        d.d_moy,
        i.i_category,
        s.s_state AS region,
        'store' AS channel,
        SUM(sr.sr_net_loss) AS total_returns
 FROM store_returns sr
 JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
 JOIN item i ON sr.sr_item_sk = i.i_item_sk
 JOIN store s ON sr.sr_store_sk = s.s_store_sk
 WHERE d.d_year BETWEEN 1999 AND 2000
 GROUP BY d.d_year, d.d_moy, i.i_category, s.s_state
),
catalog_sales_agg AS (
 SELECT d.d_year,
        d.d_moy,
        i.i_category,
        cc.cc_state AS region,
        'catalog' AS channel,
        SUM(cs.cs_net_paid) AS total_sales,
        SUM(cs.cs_net_profit) AS total_profit
 FROM catalog_sales cs
 JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
 JOIN item i ON cs.cs_item_sk = i.i_item_sk
 JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
 WHERE d.d_year BETWEEN 1999 AND 2000
 GROUP BY d.d_year, d.d_moy, i.i_category, cc.cc_state
),
catalog_returns_agg AS (
 SELECT d.d_year,
        d.d_moy,
        i.i_category,
        cc.cc_state AS region,
        'catalog' AS channel,
        SUM(cr.cr_net_loss) AS total_returns
 FROM catalog_returns cr
 JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
 JOIN item i ON cr.cr_item_sk = i.i_item_sk
 JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
 WHERE d.d_year BETWEEN 1999 AND 2000
 GROUP BY d.d_year, d.d_moy, i.i_category, cc.cc_state
),
web_sales_agg AS (
 SELECT d.d_year,
        d.d_moy,
        i.i_category,
        ws_site.web_state AS region,
        'web' AS channel,
        SUM(ws.ws_net_paid) AS total_sales,
        SUM(ws.ws_net_profit) AS total_profit
 FROM web_sales ws
 JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
 JOIN item i ON ws.ws_item_sk = i.i_item_sk
 JOIN web_site ws_site ON ws.ws_web_site_sk = ws_site.web_site_sk
 WHERE d.d_year BETWEEN 1999 AND 2000
 GROUP BY d.d_year, d.d_moy, i.i_category, ws_site.web_state
),
web_returns_agg AS (
 SELECT d.d_year,
        d.d_moy,
        i.i_category,
        ws_site.web_state AS region,
        'web' AS channel,
        SUM(wr.wr_net_loss) AS total_returns
 FROM web_returns wr
 LEFT JOIN web_sales ws ON wr.wr_order_number = ws.ws_order_number AND wr.wr_item_sk = ws.ws_item_sk
 LEFT JOIN web_site ws_site ON ws.ws_web_site_sk = ws_site.web_site_sk
 JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
 JOIN item i ON wr.wr_item_sk = i.i_item_sk
 WHERE d.d_year BETWEEN 1999 AND 2000
 GROUP BY d.d_year, d.d_moy, i.i_category, ws_site.web_state
),
combined_sales AS (
 SELECT * FROM store_sales_agg
 UNION ALL
 SELECT * FROM catalog_sales_agg
 UNION ALL
 SELECT * FROM web_sales_agg
),
combined_returns AS (
 SELECT * FROM store_returns_agg
 UNION ALL
 SELECT * FROM catalog_returns_agg
 UNION ALL
 SELECT * FROM web_returns_agg
),
merged AS (
 SELECT s.d_year,
        s.d_moy,
        s.i_category,
        s.region,
        s.channel,
        s.total_sales,
        s.total_profit,
        COALESCE(r.total_returns, 0) AS total_returns,
        s.total_sales - COALESCE(r.total_returns, 0) AS net_sales,
        CASE WHEN s.total_sales > 0 THEN COALESCE(r.total_returns, 0) / s.total_sales ELSE 0 END AS return_rate
 FROM combined_sales s
 LEFT JOIN combined_returns r
   ON s.d_year = r.d_year
  AND s.d_moy = r.d_moy
  AND s.i_category = r.i_category
  AND (s.region = r.region OR (s.region IS NULL AND r.region IS NULL))
  AND s.channel = r.channel
)
SELECT
  CAST(d_year AS varchar) || '-' || lpad(CAST(d_moy AS varchar), 2, '0') AS year_month,
  channel,
  COALESCE(region, 'UNKNOWN') AS region,
  i_category,
  total_sales,
  total_returns,
  net_sales,
  total_profit,
  return_rate,
  profit_rank
FROM (
  SELECT
    d_year,
    d_moy,
    i_category,
    region,
    channel,
    total_sales,
    total_returns,
    net_sales,
    total_profit,
    return_rate,
    ROW_NUMBER() OVER (PARTITION BY d_year, d_moy, channel ORDER BY total_profit DESC) AS profit_rank
  FROM merged
) t
WHERE profit_rank <= 5
ORDER BY year_month, channel, profit_rank
