WITH sales_agg AS (
   SELECT
       i.i_category,
       sm.sm_type,
       wsit.web_state,
       SUM(ws.ws_ext_sales_price) AS total_sales,
       SUM(ws.ws_ext_discount_amt) AS total_discount,
       SUM(ws.ws_quantity) AS total_quantity,
       SUM(ws.ws_net_profit) AS total_net_profit,
       COUNT(DISTINCT ws.ws_order_number) AS distinct_orders
   FROM web_sales ws
   JOIN item i ON ws.ws_item_sk = i.i_item_sk
   JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
   JOIN web_site wsit ON ws.ws_web_site_sk = wsit.web_site_sk
   WHERE ws.ws_sold_date_sk BETWEEN 2450000 AND 2455000
     AND i.i_category IN ('Women', 'Men')
   GROUP BY i.i_category, sm.sm_type, wsit.web_state
),
returns_agg AS (
   SELECT
       i.i_category,
       sm.sm_type,
       wsit.web_state,
       SUM(wr.wr_return_amt_inc_tax) AS total_return_amount,
       SUM(wr.wr_return_quantity) AS total_return_quantity,
       COUNT(DISTINCT wr.wr_order_number) AS distinct_return_orders
   FROM web_returns wr
   JOIN web_sales ws ON wr.wr_order_number = ws.ws_order_number
                     AND wr.wr_item_sk = ws.ws_item_sk
   JOIN item i ON ws.ws_item_sk = i.i_item_sk
   JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
   JOIN web_site wsit ON ws.ws_web_site_sk = wsit.web_site_sk
   WHERE ws.ws_sold_date_sk BETWEEN 2450000 AND 2455000
     AND i.i_category IN ('Women', 'Men')
   GROUP BY i.i_category, sm.sm_type, wsit.web_state
)
SELECT
    s.i_category,
    s.sm_type,
    s.web_state,
    s.total_sales,
    COALESCE(r.total_return_amount, 0) AS total_return_amount,
    s.total_sales - COALESCE(r.total_return_amount, 0) AS net_sales_after_returns,
    s.total_net_profit - COALESCE(r.total_return_amount, 0) AS net_profit_after_returns,
    s.total_discount,
    s.total_quantity,
    s.total_discount / NULLIF(s.total_quantity,0) AS avg_discount_per_item,
    s.distinct_orders,
    COALESCE(r.distinct_return_orders, 0) AS distinct_return_orders,
    COALESCE(r.total_return_quantity, 0) AS total_return_quantity,
    (COALESCE(r.total_return_quantity,0) * 1.0) / NULLIF(s.total_quantity,0) AS return_rate,
    ROW_NUMBER() OVER (ORDER BY (s.total_sales - COALESCE(r.total_return_amount,0)) DESC) AS sales_rank
FROM sales_agg s
LEFT JOIN returns_agg r
  ON s.i_category = r.i_category AND s.sm_type = r.sm_type AND s.web_state = r.web_state
ORDER BY net_sales_after_returns DESC
LIMIT 20
