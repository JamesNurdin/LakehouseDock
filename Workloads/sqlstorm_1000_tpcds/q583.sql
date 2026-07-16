WITH store_sales_agg AS (
  SELECT d.d_year,
         i.i_category,
         p.p_promo_name,
         sum(ss.ss_ext_sales_price) AS store_sales,
         sum(ss.ss_net_profit) AS store_profit,
         count(*) AS store_txn_count
  FROM store_sales ss
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN item i ON ss.ss_item_sk = i.i_item_sk
  LEFT JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
  WHERE d.d_year BETWEEN 1999 AND 2000
  GROUP BY d.d_year, i.i_category, p.p_promo_name
),
web_sales_agg AS (
  SELECT d.d_year,
         i.i_category,
         p.p_promo_name,
         sum(ws.ws_ext_sales_price) AS web_sales,
         sum(ws.ws_net_profit) AS web_profit,
         count(*) AS web_txn_count
  FROM web_sales ws
  JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
  JOIN item i ON ws.ws_item_sk = i.i_item_sk
  LEFT JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
  WHERE d.d_year BETWEEN 1999 AND 2000
  GROUP BY d.d_year, i.i_category, p.p_promo_name
),
catalog_sales_agg AS (
  SELECT d.d_year,
         i.i_category,
         p.p_promo_name,
         sum(cs.cs_ext_sales_price) AS catalog_sales,
         sum(cs.cs_net_profit) AS catalog_profit,
         count(*) AS catalog_txn_count
  FROM catalog_sales cs
  JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
  JOIN item i ON cs.cs_item_sk = i.i_item_sk
  LEFT JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
  WHERE d.d_year BETWEEN 1999 AND 2000
  GROUP BY d.d_year, i.i_category, p.p_promo_name
),
returns_agg AS (
  SELECT d.d_year,
         sum(sr.sr_net_loss) AS store_return_loss,
         sum(wr.wr_net_loss) AS web_return_loss,
         sum(cr.cr_net_loss) AS catalog_return_loss
  FROM date_dim d
  LEFT JOIN store_returns sr ON sr.sr_returned_date_sk = d.d_date_sk
  LEFT JOIN web_returns wr ON wr.wr_returned_date_sk = d.d_date_sk
  LEFT JOIN catalog_returns cr ON cr.cr_returned_date_sk = d.d_date_sk
  WHERE d.d_year BETWEEN 1999 AND 2000
  GROUP BY d.d_year
)
SELECT
  ss.d_year,
  ss.i_category,
  ss.p_promo_name,
  ss.store_sales,
  ss.store_profit,
  ws.web_sales,
  ws.web_profit,
  cs.catalog_sales,
  cs.catalog_profit,
  r.store_return_loss,
  r.web_return_loss,
  r.catalog_return_loss
FROM store_sales_agg ss
JOIN web_sales_agg ws ON ss.d_year = ws.d_year AND ss.i_category = ws.i_category AND ss.p_promo_name = ws.p_promo_name
JOIN catalog_sales_agg cs ON ss.d_year = cs.d_year AND ss.i_category = cs.i_category AND ss.p_promo_name = cs.p_promo_name
JOIN returns_agg r ON ss.d_year = r.d_year
ORDER BY ss.d_year, ss.i_category, ss.p_promo_name
LIMIT 100
