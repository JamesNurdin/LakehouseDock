/* Goal: Analyze the financial impact of product returns and web sales by item category and shipping mode, applying string pattern filters on item descriptions and website names. The query uses regex, LIKE, concatenation, a CASE expression, a scalar subquery, a window function, and hierarchical grouping (ROLLUP and CUBE). */
WITH
  -- Aggregate catalog returns with string filters and hierarchical grouping
  returns_agg AS (
    SELECT
      i.i_category AS category,
      sm.sm_ship_mode_id AS ship_mode,
      SUM(cr.cr_return_amount) AS total_return_amount,
      SUM(cr.cr_net_loss) AS total_net_loss,
      COUNT(*) AS return_cnt,
      CASE WHEN SUM(cr.cr_net_loss) > 10000 THEN 'HIGH' ELSE 'LOW' END AS loss_level
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE regexp_like(i.i_item_desc, '(?i)^(.*\b(Premium|Deluxe)\b.*)')
      AND i.i_color LIKE 'Red%'
    GROUP BY ROLLUP (i.i_category, sm.sm_ship_mode_id)
  ),

  -- Aggregate web sales with different string filters and hierarchical grouping
  sales_agg AS (
    SELECT
      i.i_category AS category,
      sm.sm_ship_mode_id AS ship_mode,
      SUM(ws.ws_ext_sales_price) AS total_sales,
      COUNT(*) AS sales_cnt,
      MAX(ws.ws_net_profit) AS max_profit
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
    WHERE wsite.web_name LIKE '%Outlet%'
      AND regexp_extract(i.i_product_name, '(\\d{4})', 1) = CAST(YEAR(current_date) AS VARCHAR)
    GROUP BY CUBE (i.i_category, sm.sm_ship_mode_id)
  )

SELECT
  r.category,
  r.ship_mode,
  r.total_return_amount,
  r.total_net_loss,
  r.return_cnt,
  r.loss_level,
  s.total_sales,
  s.sales_cnt,
  s.max_profit,
  -- scalar subquery: average return amount for the same category across all ship modes
  (SELECT AVG(r2.total_return_amount)
     FROM returns_agg r2
     WHERE r2.category = r.category) AS avg_return_by_category,
  -- window function: rank categories by combined financial impact
  ROW_NUMBER() OVER (PARTITION BY r.category ORDER BY (r.total_net_loss + COALESCE(s.total_sales,0)) DESC) AS rank_by_category
FROM returns_agg r
LEFT JOIN sales_agg s
  ON r.category = s.category
  AND r.ship_mode = s.ship_mode
WHERE r.category IS NOT NULL
ORDER BY r.category, r.ship_mode
LIMIT 100
