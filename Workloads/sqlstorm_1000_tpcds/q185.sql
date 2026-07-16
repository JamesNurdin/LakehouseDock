WITH
store_sales_agg AS (
  SELECT
    d.d_year,
    d.d_quarter_name,
    i.i_category,
    i.i_class,
    i.i_brand,
    SUM(ss.ss_net_profit) AS net_profit,
    SUM(ss.ss_ext_sales_price) AS sales_amount,
    SUM(ss.ss_quantity) AS units_sold,
    SUM(ss.ss_ext_discount_amt) AS discount_amount,
    SUM(COALESCE(p.p_cost, 0)) AS promo_cost
  FROM store_sales ss
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN item i ON ss.ss_item_sk = i.i_item_sk
  LEFT JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
  WHERE d.d_year BETWEEN 1998 AND 2002
  GROUP BY d.d_year, d.d_quarter_name, i.i_category, i.i_class, i.i_brand
),
store_returns_agg AS (
  SELECT
    d.d_year,
    d.d_quarter_name,
    i.i_category,
    i.i_class,
    i.i_brand,
    SUM(sr.sr_net_loss) AS net_loss,
    SUM(sr.sr_return_quantity) AS return_units,
    SUM(sr.sr_return_amt_inc_tax) AS return_amount
  FROM store_returns sr
  JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
  JOIN item i ON sr.sr_item_sk = i.i_item_sk
  WHERE d.d_year BETWEEN 1998 AND 2002
  GROUP BY d.d_year, d.d_quarter_name, i.i_category, i.i_class, i.i_brand
),
catalog_sales_agg AS (
  SELECT
    d.d_year,
    d.d_quarter_name,
    i.i_category,
    i.i_class,
    i.i_brand,
    SUM(cs.cs_net_profit) AS net_profit,
    SUM(cs.cs_ext_sales_price) AS sales_amount,
    SUM(cs.cs_quantity) AS units_sold,
    SUM(cs.cs_ext_discount_amt) AS discount_amount,
    SUM(COALESCE(p.p_cost, 0)) AS promo_cost
  FROM catalog_sales cs
  JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
  JOIN item i ON cs.cs_item_sk = i.i_item_sk
  LEFT JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
  WHERE d.d_year BETWEEN 1998 AND 2002
  GROUP BY d.d_year, d.d_quarter_name, i.i_category, i.i_class, i.i_brand
),
catalog_returns_agg AS (
  SELECT
    d.d_year,
    d.d_quarter_name,
    i.i_category,
    i.i_class,
    i.i_brand,
    SUM(cr.cr_net_loss) AS net_loss,
    SUM(cr.cr_return_quantity) AS return_units,
    SUM(cr.cr_return_amt_inc_tax) AS return_amount
  FROM catalog_returns cr
  JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
  JOIN item i ON cr.cr_item_sk = i.i_item_sk
  WHERE d.d_year BETWEEN 1998 AND 2002
  GROUP BY d.d_year, d.d_quarter_name, i.i_category, i.i_class, i.i_brand
),
web_sales_agg AS (
  SELECT
    d.d_year,
    d.d_quarter_name,
    i.i_category,
    i.i_class,
    i.i_brand,
    SUM(ws.ws_net_profit) AS net_profit,
    SUM(ws.ws_ext_sales_price) AS sales_amount,
    SUM(ws.ws_quantity) AS units_sold,
    SUM(ws.ws_ext_discount_amt) AS discount_amount,
    SUM(COALESCE(p.p_cost, 0)) AS promo_cost
  FROM web_sales ws
  JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
  JOIN item i ON ws.ws_item_sk = i.i_item_sk
  LEFT JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
  WHERE d.d_year BETWEEN 1998 AND 2002
  GROUP BY d.d_year, d.d_quarter_name, i.i_category, i.i_class, i.i_brand
),
web_returns_agg AS (
  SELECT
    d.d_year,
    d.d_quarter_name,
    i.i_category,
    i.i_class,
    i.i_brand,
    SUM(wr.wr_net_loss) AS net_loss,
    SUM(wr.wr_return_quantity) AS return_units,
    SUM(wr.wr_return_amt_inc_tax) AS return_amount
  FROM web_returns wr
  JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
  JOIN item i ON wr.wr_item_sk = i.i_item_sk
  WHERE d.d_year BETWEEN 1998 AND 2002
  GROUP BY d.d_year, d.d_quarter_name, i.i_category, i.i_class, i.i_brand
),
combined AS (
  SELECT
    COALESCE(ss.d_year, sr.d_year, cs.d_year, cr.d_year, ws.d_year, wr.d_year) AS sales_year,
    COALESCE(ss.d_quarter_name, sr.d_quarter_name, cs.d_quarter_name, cr.d_quarter_name, ws.d_quarter_name, wr.d_quarter_name) AS sales_quarter,
    COALESCE(ss.i_category, sr.i_category, cs.i_category, cr.i_category, ws.i_category, wr.i_category) AS category,
    COALESCE(ss.i_class, sr.i_class, cs.i_class, cr.i_class, ws.i_class, wr.i_class) AS class,
    COALESCE(ss.i_brand, sr.i_brand, cs.i_brand, cr.i_brand, ws.i_brand, wr.i_brand) AS brand,
    ss.net_profit - COALESCE(sr.net_loss, 0) AS store_net,
    ss.sales_amount - COALESCE(sr.return_amount, 0) AS store_sales,
    cs.net_profit - COALESCE(cr.net_loss, 0) AS catalog_net,
    cs.sales_amount - COALESCE(cr.return_amount, 0) AS catalog_sales,
    ws.net_profit - COALESCE(wr.net_loss, 0) AS web_net,
    ws.sales_amount - COALESCE(wr.return_amount, 0) AS web_sales,
    COALESCE(ss.promo_cost,0) + COALESCE(cs.promo_cost,0) + COALESCE(ws.promo_cost,0) AS total_promo_cost,
    (ss.net_profit - COALESCE(sr.net_loss,0)) + (cs.net_profit - COALESCE(cr.net_loss,0)) + (ws.net_profit - COALESCE(wr.net_loss,0)) AS total_net_profit
  FROM store_sales_agg ss
  FULL OUTER JOIN store_returns_agg sr
    ON ss.d_year = sr.d_year
   AND ss.d_quarter_name = sr.d_quarter_name
   AND ss.i_category = sr.i_category
   AND ss.i_class = sr.i_class
   AND ss.i_brand = sr.i_brand
  FULL OUTER JOIN catalog_sales_agg cs
    ON COALESCE(ss.d_year, sr.d_year) = cs.d_year
   AND COALESCE(ss.d_quarter_name, sr.d_quarter_name) = cs.d_quarter_name
   AND COALESCE(ss.i_category, sr.i_category) = cs.i_category
   AND COALESCE(ss.i_class, sr.i_class) = cs.i_class
   AND COALESCE(ss.i_brand, sr.i_brand) = cs.i_brand
  FULL OUTER JOIN catalog_returns_agg cr
    ON cs.d_year = cr.d_year
   AND cs.d_quarter_name = cr.d_quarter_name
   AND cs.i_category = cr.i_category
   AND cs.i_class = cr.i_class
   AND cs.i_brand = cr.i_brand
  FULL OUTER JOIN web_sales_agg ws
    ON COALESCE(ss.d_year, cs.d_year, sr.d_year, cr.d_year) = ws.d_year
   AND COALESCE(ss.d_quarter_name, cs.d_quarter_name, sr.d_quarter_name, cr.d_quarter_name) = ws.d_quarter_name
   AND COALESCE(ss.i_category, cs.i_category, sr.i_category, cr.i_category) = ws.i_category
   AND COALESCE(ss.i_class, cs.i_class, sr.i_class, cr.i_class) = ws.i_class
   AND COALESCE(ss.i_brand, cs.i_brand, sr.i_brand, cr.i_brand) = ws.i_brand
  FULL OUTER JOIN web_returns_agg wr
    ON ws.d_year = wr.d_year
   AND ws.d_quarter_name = wr.d_quarter_name
   AND ws.i_category = wr.i_category
   AND ws.i_class = wr.i_class
   AND ws.i_brand = wr.i_brand
)
SELECT
  sales_year,
  sales_quarter,
  category,
  class,
  brand,
  store_net,
  store_sales,
  catalog_net,
  catalog_sales,
  web_net,
  web_sales,
  total_promo_cost,
  total_net_profit,
  (total_promo_cost / nullif(total_net_profit, 0)) AS promo_cost_ratio,
  ROW_NUMBER() OVER (PARTITION BY sales_year ORDER BY total_net_profit DESC) AS rank_by_profit
FROM combined
WHERE total_net_profit > 0
ORDER BY sales_year, rank_by_profit
LIMIT 100
