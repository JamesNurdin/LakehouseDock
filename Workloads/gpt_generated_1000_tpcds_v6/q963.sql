WITH
joined_data AS (
  SELECT
    cs.cs_order_number,
    cs.cs_item_sk,
    cs.cs_net_profit AS catalog_net_profit,
    cs.cs_quantity,
    cc.cc_state,
    cp.cp_department,
    cp.cp_catalog_page_number,
    i.i_category,
    i.i_units,
    i.i_wholesale_cost,
    ws.ws_order_number,
    ws.ws_net_profit AS web_net_profit,
    ws.ws_net_paid_inc_ship_tax,
    wsite.web_state,
    wr.wr_net_loss,
    cust.c_customer_sk
  FROM catalog_sales cs
  JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
  JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
  JOIN item i ON cs.cs_item_sk = i.i_item_sk
  JOIN customer cust ON cs.cs_bill_customer_sk = cust.c_customer_sk
  LEFT JOIN web_sales ws ON cs.cs_order_number = ws.ws_order_number
      AND cs.cs_item_sk = ws.ws_item_sk
  LEFT JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
  LEFT JOIN web_returns wr ON ws.ws_order_number = wr.wr_order_number
      AND ws.ws_item_sk = wr.wr_item_sk
  WHERE cc.cc_state = 'CA'
    AND wsite.web_state = 'CA'
    AND i.i_units = 'Each'
    AND i.i_wholesale_cost > 0.5
    AND cp.cp_catalog_page_number = 16
    AND ws.ws_net_paid_inc_ship_tax > 1000
),
catalog_agg AS (
  SELECT
    i_category,
    cp_department,
    SUM(catalog_net_profit) AS profit,
    COUNT(*) AS cnt
  FROM joined_data
  WHERE catalog_net_profit IS NOT NULL
  GROUP BY ROLLUP(i_category, cp_department)
),
web_agg AS (
  SELECT
    i_category,
    web_state AS cp_department,
    SUM(web_net_profit) AS profit,
    COUNT(*) AS cnt
  FROM joined_data
  WHERE web_net_profit IS NOT NULL
  GROUP BY CUBE(i_category, web_state)
),
union_agg AS (
  SELECT i_category, cp_department, profit, cnt, 'catalog' AS src FROM catalog_agg
  UNION ALL
  SELECT i_category, cp_department, profit, cnt, 'web' AS src FROM web_agg
)
SELECT
  i_category,
  cp_department,
  SUM(profit) AS total_profit,
  SUM(cnt) AS total_cnt,
  ROW_NUMBER() OVER (PARTITION BY i_category ORDER BY SUM(profit) DESC) AS rank_within_category,
  (SELECT AVG(cs.cs_net_profit) FROM catalog_sales cs) AS avg_catalog_profit
FROM union_agg
WHERE profit IS NOT NULL
GROUP BY GROUPING SETS ((i_category, cp_department), (i_category), ())
HAVING SUM(profit) > 5000
ORDER BY total_profit DESC
LIMIT 100
