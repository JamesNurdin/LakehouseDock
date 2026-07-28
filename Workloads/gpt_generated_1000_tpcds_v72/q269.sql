WITH base AS (
  SELECT
    i.i_brand,
    sm.sm_type,
    ws.ws_ext_sales_price,
    ws.ws_net_profit,
    cr.cr_return_amount,
    cr.cr_return_quantity,
    cr.cr_returning_customer_sk,
    sr.sr_return_amt,
    sr.sr_return_quantity,
    ws.ws_quantity,
    web_site.web_company_id,
    i.i_current_price,
    r.r_reason_desc
  FROM web_sales ws
  JOIN item i ON ws.ws_item_sk = i.i_item_sk
  JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN web_site ON ws.ws_web_site_sk = web_site.web_site_sk
  LEFT JOIN catalog_returns cr ON cr.cr_item_sk = i.i_item_sk
  LEFT JOIN store_returns sr ON sr.sr_item_sk = i.i_item_sk
  LEFT JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
  WHERE i.i_current_price > 5.00
    AND web_site.web_company_id = 3
),
sales_agg AS (
  SELECT
    i_brand,
    sm_type,
    'sales' AS metric,
    SUM(ws_ext_sales_price) AS metric_value,
    ROW_NUMBER() OVER (PARTITION BY i_brand ORDER BY SUM(ws_ext_sales_price) DESC) AS brand_rank
  FROM base
  GROUP BY GROUPING SETS ((i_brand, sm_type), (i_brand))
),
returns_agg AS (
  SELECT
    i_brand,
    sm_type,
    'return' AS metric,
    SUM(COALESCE(cr_return_amount, 0) + COALESCE(sr_return_amt, 0)) AS metric_value,
    NULL AS brand_rank
  FROM base
  WHERE cr_returning_customer_sk IN (5381710, 2452686)
  GROUP BY GROUPING SETS ((i_brand, sm_type), (i_brand))
  HAVING SUM(COALESCE(cr_return_amount, 0) + COALESCE(sr_return_amt, 0)) > 100
)
SELECT *
FROM sales_agg
UNION ALL
SELECT *
FROM returns_agg
ORDER BY i_brand, sm_type, metric DESC
LIMIT 100
