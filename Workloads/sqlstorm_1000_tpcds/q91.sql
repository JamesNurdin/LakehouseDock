WITH sales_agg AS (
  SELECT
    d.d_year,
    i.i_item_id,
    i.i_item_desc,
    SUM(ss.ss_ext_sales_price) AS store_sales,
    SUM(ss.ss_net_profit) AS store_profit,
    SUM(ss.ss_quantity) AS store_quantity,
    SUM(ss.ss_ext_tax) AS store_tax
  FROM store_sales ss
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN item i ON ss.ss_item_sk = i.i_item_sk
  GROUP BY d.d_year, i.i_item_id, i.i_item_desc
), catalog_sales_agg AS (
  SELECT
    d.d_year,
    i.i_item_id,
    i.i_item_desc,
    SUM(cs.cs_ext_sales_price) AS catalog_sales,
    SUM(cs.cs_net_profit) AS catalog_profit,
    SUM(cs.cs_quantity) AS catalog_quantity,
    SUM(cs.cs_ext_tax) AS catalog_tax
  FROM catalog_sales cs
  JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
  JOIN item i ON cs.cs_item_sk = i.i_item_sk
  GROUP BY d.d_year, i.i_item_id, i.i_item_desc
), web_sales_agg AS (
  SELECT
    d.d_year,
    i.i_item_id,
    i.i_item_desc,
    SUM(ws.ws_ext_sales_price) AS web_sales,
    SUM(ws.ws_net_profit) AS web_profit,
    SUM(ws.ws_quantity) AS web_quantity,
    SUM(ws.ws_ext_tax) AS web_tax
  FROM web_sales ws
  JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
  JOIN item i ON ws.ws_item_sk = i.i_item_sk
  GROUP BY d.d_year, i.i_item_id, i.i_item_desc
), returns_agg AS (
  SELECT
    d.d_year,
    i.i_item_id,
    i.i_item_desc,
    SUM(r.return_amt) AS total_return_amount,
    SUM(r.return_quantity) AS total_return_quantity
  FROM (
    SELECT sr_returned_date_sk AS date_sk, sr_item_sk AS item_sk, sr_return_amt AS return_amt, sr_return_quantity AS return_quantity
    FROM store_returns
    UNION ALL
    SELECT cr_returned_date_sk, cr_item_sk, cr_return_amount, cr_return_quantity
    FROM catalog_returns
    UNION ALL
    SELECT wr_returned_date_sk, wr_item_sk, wr_return_amt, wr_return_quantity
    FROM web_returns
  ) r
  JOIN date_dim d ON r.date_sk = d.d_date_sk
  JOIN item i ON r.item_sk = i.i_item_sk
  GROUP BY d.d_year, i.i_item_id, i.i_item_desc
), combined_items AS (
  SELECT DISTINCT
    d.d_year AS d_year,
    i.i_item_id,
    i.i_item_desc
  FROM (
    SELECT ss.ss_sold_date_sk AS date_sk, ss.ss_item_sk AS item_sk
    FROM store_sales ss
    UNION
    SELECT cs.cs_sold_date_sk, cs.cs_item_sk
    FROM catalog_sales cs
    UNION
    SELECT ws.ws_sold_date_sk, ws.ws_item_sk
    FROM web_sales ws
  ) u
  JOIN date_dim d ON u.date_sk = d.d_date_sk
  JOIN item i ON u.item_sk = i.i_item_sk
)
SELECT
  ci.d_year,
  ci.i_item_id,
  ci.i_item_desc,
  COALESCE(sa.store_sales, 0.0) + COALESCE(ca.catalog_sales, 0.0) + COALESCE(wa.web_sales, 0.0) AS total_sales,
  COALESCE(sa.store_profit, 0.0) + COALESCE(ca.catalog_profit, 0.0) + COALESCE(wa.web_profit, 0.0) AS total_profit,
  COALESCE(ra.total_return_amount, 0.0) AS total_return_amount,
  COALESCE(sa.store_quantity, 0) + COALESCE(ca.catalog_quantity, 0) + COALESCE(wa.web_quantity, 0) AS total_quantity,
  (COALESCE(sa.store_quantity, 0) + COALESCE(ca.catalog_quantity, 0) + COALESCE(wa.web_quantity, 0) - COALESCE(ra.total_return_quantity, 0)) AS net_quantity_sold,
  (COALESCE(sa.store_sales, 0.0) + COALESCE(ca.catalog_sales, 0.0) + COALESCE(wa.web_sales, 0.0) - COALESCE(ra.total_return_amount, 0.0)) AS net_sales_after_returns,
  ROUND(
    (COALESCE(sa.store_profit, 0.0) + COALESCE(ca.catalog_profit, 0.0) + COALESCE(wa.web_profit, 0.0)) /
    NULLIF(COALESCE(sa.store_sales, 0.0) + COALESCE(ca.catalog_sales, 0.0) + COALESCE(wa.web_sales, 0.0), 0.0),
    4
  ) AS overall_profit_margin,
  AVG(COALESCE(sa.store_sales, 0.0) + COALESCE(ca.catalog_sales, 0.0) + COALESCE(wa.web_sales, 0.0))
    OVER (PARTITION BY ci.i_item_id ORDER BY ci.d_year ROWS BETWEEN 2 PRECEDING AND 2 FOLLOWING) AS five_year_avg_sales
FROM combined_items ci
LEFT JOIN sales_agg sa ON ci.d_year = sa.d_year AND ci.i_item_id = sa.i_item_id
LEFT JOIN catalog_sales_agg ca ON ci.d_year = ca.d_year AND ci.i_item_id = ca.i_item_id
LEFT JOIN web_sales_agg wa ON ci.d_year = wa.d_year AND ci.i_item_id = wa.i_item_id
LEFT JOIN returns_agg ra ON ci.d_year = ra.d_year AND ci.i_item_id = ra.i_item_id
ORDER BY total_sales DESC
LIMIT 100
