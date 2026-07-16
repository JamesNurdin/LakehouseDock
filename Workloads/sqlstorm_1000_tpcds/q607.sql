WITH combined_sales AS (
  SELECT
    d.d_year AS year,
    d.d_moy AS month,
    cc.cc_state AS state,
    i.i_category AS category,
    cs.cs_net_profit AS profit,
    cs.cs_ext_sales_price AS revenue,
    cs.cs_order_number AS order_id
  FROM catalog_sales cs
  JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
  JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
  JOIN item i ON cs.cs_item_sk = i.i_item_sk
  UNION ALL
  SELECT
    d.d_year AS year,
    d.d_moy AS month,
    s.s_state AS state,
    i.i_category AS category,
    ss.ss_net_profit AS profit,
    ss.ss_ext_sales_price AS revenue,
    ss.ss_ticket_number AS order_id
  FROM store_sales ss
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN store s ON ss.ss_store_sk = s.s_store_sk
  JOIN item i ON ss.ss_item_sk = i.i_item_sk
  UNION ALL
  SELECT
    d.d_year AS year,
    d.d_moy AS month,
    wsite.web_state AS state,
    i.i_category AS category,
    ws.ws_net_profit AS profit,
    ws.ws_ext_sales_price AS revenue,
    ws.ws_order_number AS order_id
  FROM web_sales ws
  JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
  JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
  JOIN item i ON ws.ws_item_sk = i.i_item_sk
)
SELECT
  year,
  month,
  state,
  category,
  sum(profit) AS total_profit,
  sum(revenue) AS total_revenue,
  count(distinct order_id) AS distinct_orders
FROM combined_sales
GROUP BY year, month, state, category
ORDER BY total_profit DESC
LIMIT 200
