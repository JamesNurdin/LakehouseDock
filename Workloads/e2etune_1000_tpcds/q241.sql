WITH sales AS (
  SELECT
    i.i_category,
    i.i_brand,
    w.w_city,
    cd.cd_gender,
    SUM(cs.cs_net_paid_inc_tax) AS total_sales,
    SUM(cs.cs_net_profit) AS total_profit,
    COUNT(*) AS sales_cnt
  FROM catalog_sales cs
  JOIN item i ON cs.cs_item_sk = i.i_item_sk
  JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
  JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
  WHERE cs.cs_quantity > 1
    AND i.i_current_price > 50
    AND cd.cd_gender = 'M'
  GROUP BY i.i_category, i.i_brand, w.w_city, cd.cd_gender
  UNION ALL
  SELECT
    i.i_category,
    i.i_brand,
    w.w_city,
    cd.cd_gender,
    SUM(ws.ws_net_paid_inc_tax) AS total_sales,
    SUM(ws.ws_net_profit) AS total_profit,
    COUNT(*) AS sales_cnt
  FROM web_sales ws
  JOIN item i ON ws.ws_item_sk = i.i_item_sk
  JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
  JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
  WHERE ws.ws_quantity > 2
    AND i.i_current_price > 50
    AND cd.cd_gender = 'M'
  GROUP BY i.i_category, i.i_brand, w.w_city, cd.cd_gender
),
sales_agg AS (
  SELECT
    i_category,
    i_brand,
    w_city,
    cd_gender,
    SUM(total_sales) AS total_sales,
    SUM(total_profit) AS total_profit,
    SUM(sales_cnt) AS sales_cnt
  FROM sales
  GROUP BY i_category, i_brand, w_city, cd_gender
),
returns AS (
  SELECT
    i.i_category,
    i.i_brand,
    cd.cd_gender,
    SUM(sr.sr_return_amt_inc_tax) AS total_returns,
    COUNT(*) AS returns_cnt
  FROM store_returns sr
  JOIN item i ON sr.sr_item_sk = i.i_item_sk
  JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
  WHERE sr.sr_return_quantity > 0
    AND cd.cd_gender = 'M'
  GROUP BY i.i_category, i.i_brand, cd.cd_gender
)
SELECT
  s.i_category,
  s.i_brand,
  s.w_city,
  s.cd_gender,
  s.total_sales,
  COALESCE(r.total_returns, 0) AS total_returns,
  (s.total_sales - COALESCE(r.total_returns, 0)) AS net_sales,
  s.total_profit,
  CASE WHEN s.sales_cnt > 0 THEN s.total_profit / s.sales_cnt ELSE 0 END AS avg_profit_per_sale,
  s.sales_cnt,
  COALESCE(r.returns_cnt, 0) AS returns_cnt
FROM sales_agg s
LEFT JOIN returns r
  ON s.i_category = r.i_category
  AND s.i_brand = r.i_brand
  AND s.cd_gender = r.cd_gender
WHERE (s.total_sales - COALESCE(r.total_returns, 0)) > 1000
ORDER BY net_sales DESC
LIMIT 100
