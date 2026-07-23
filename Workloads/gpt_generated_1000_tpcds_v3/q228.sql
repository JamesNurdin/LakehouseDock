WITH ws_agg AS (
  SELECT
    i.i_item_sk,
    i.i_category,
    i.i_category_id,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    SUM(ws.ws_quantity) AS total_quantity,
    COUNT(DISTINCT ws.ws_order_number) AS distinct_orders,
    MAX(ws.ws_sold_date_sk) AS last_sold_date_sk
  FROM web_sales ws
  JOIN item i ON ws.ws_item_sk = i.i_item_sk
  LEFT JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
  WHERE ws.ws_sold_date_sk BETWEEN 2450815 AND 2450941
    AND inv.inv_quantity_on_hand > 0
  GROUP BY i.i_item_sk, i.i_category, i.i_category_id
),

sr_agg AS (
  SELECT
    i.i_item_sk,
    i.i_category,
    i.i_category_id,
    SUM(sr.sr_return_amt_inc_tax) AS total_returns,
    SUM(sr.sr_return_quantity) AS total_return_qty,
    COUNT(DISTINCT sr.sr_ticket_number) AS distinct_returns,
    MAX(sr.sr_returned_date_sk) AS last_return_date_sk
  FROM store_returns sr
  JOIN item i ON sr.sr_item_sk = i.i_item_sk
  LEFT JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
  WHERE sr.sr_returned_date_sk BETWEEN 2450815 AND 2450941
    AND inv.inv_quantity_on_hand > 0
  GROUP BY i.i_item_sk, i.i_category, i.i_category_id
),

combined AS (
  SELECT
    i_item_sk,
    i_category,
    i_category_id,
    total_sales,
    total_quantity,
    CAST(NULL AS decimal(7,2)) AS total_returns,
    CAST(NULL AS integer) AS total_return_qty,
    'sales' AS source
  FROM ws_agg
  UNION ALL
  SELECT
    i_item_sk,
    i_category,
    i_category_id,
    CAST(NULL AS decimal(7,2)) AS total_sales,
    CAST(NULL AS integer) AS total_quantity,
    total_returns,
    total_return_qty,
    'returns' AS source
  FROM sr_agg
)

SELECT
  i_item_sk,
  i_category,
  i_category_id,
  source,
  net_revenue,
  CASE WHEN net_revenue > 5000.0 THEN 'High' ELSE 'Low' END AS revenue_category,
  ROW_NUMBER() OVER (PARTITION BY i_category ORDER BY net_revenue DESC) AS category_rank
FROM (
  SELECT
    i_item_sk,
    i_category,
    i_category_id,
    source,
    COALESCE(total_sales, 0.0) - COALESCE(total_returns, 0.0) AS net_revenue
  FROM combined
) AS nr
ORDER BY i_category, category_rank
LIMIT 100
