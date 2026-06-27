WITH store_sales_agg AS (
  SELECT
    ss.ss_item_sk AS item_sk,
    d.d_year AS year,
    d.d_month_seq AS month_seq,
    SUM(ss.ss_quantity) AS quantity_sold,
    SUM(ss.ss_net_profit) AS net_profit
  FROM store_sales ss
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  WHERE d.d_date BETWEEN DATE '2000-01-01' AND DATE '2000-12-31'
  GROUP BY ss.ss_item_sk, d.d_year, d.d_month_seq
),
catalog_sales_agg AS (
  SELECT
    cs.cs_item_sk AS item_sk,
    d.d_year AS year,
    d.d_month_seq AS month_seq,
    SUM(cs.cs_quantity) AS quantity_sold,
    SUM(cs.cs_net_profit) AS net_profit
  FROM catalog_sales cs
  JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
  WHERE d.d_date BETWEEN DATE '2000-01-01' AND DATE '2000-12-31'
  GROUP BY cs.cs_item_sk, d.d_year, d.d_month_seq
),
web_sales_agg AS (
  SELECT
    ws.ws_item_sk AS item_sk,
    d.d_year AS year,
    d.d_month_seq AS month_seq,
    SUM(ws.ws_quantity) AS quantity_sold,
    SUM(ws.ws_net_profit) AS net_profit
  FROM web_sales ws
  JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
  WHERE d.d_date BETWEEN DATE '2000-01-01' AND DATE '2000-12-31'
  GROUP BY ws.ws_item_sk, d.d_year, d.d_month_seq
),
sales_all AS (
  SELECT * FROM store_sales_agg
  UNION ALL
  SELECT * FROM catalog_sales_agg
  UNION ALL
  SELECT * FROM web_sales_agg
),
sales_agg AS (
  SELECT
    item_sk,
    year,
    month_seq,
    SUM(quantity_sold) AS total_quantity_sold,
    SUM(net_profit) AS total_net_profit
  FROM sales_all
  GROUP BY item_sk, year, month_seq
),
store_returns_agg AS (
  SELECT
    sr.sr_item_sk AS item_sk,
    d.d_year AS year,
    d.d_month_seq AS month_seq,
    SUM(sr.sr_return_quantity) AS return_quantity
  FROM store_returns sr
  JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
  WHERE d.d_date BETWEEN DATE '2000-01-01' AND DATE '2000-12-31'
  GROUP BY sr.sr_item_sk, d.d_year, d.d_month_seq
),
catalog_returns_agg AS (
  SELECT
    cr.cr_item_sk AS item_sk,
    d.d_year AS year,
    d.d_month_seq AS month_seq,
    SUM(cr.cr_return_quantity) AS return_quantity
  FROM catalog_returns cr
  JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
  WHERE d.d_date BETWEEN DATE '2000-01-01' AND DATE '2000-12-31'
  GROUP BY cr.cr_item_sk, d.d_year, d.d_month_seq
),
web_returns_agg AS (
  SELECT
    wr.wr_item_sk AS item_sk,
    d.d_year AS year,
    d.d_month_seq AS month_seq,
    SUM(wr.wr_return_quantity) AS return_quantity
  FROM web_returns wr
  JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
  WHERE d.d_date BETWEEN DATE '2000-01-01' AND DATE '2000-12-31'
  GROUP BY wr.wr_item_sk, d.d_year, d.d_month_seq
),
returns_all AS (
  SELECT * FROM store_returns_agg
  UNION ALL
  SELECT * FROM catalog_returns_agg
  UNION ALL
  SELECT * FROM web_returns_agg
),
returns_agg AS (
  SELECT
    item_sk,
    year,
    month_seq,
    SUM(return_quantity) AS total_return_quantity
  FROM returns_all
  GROUP BY item_sk, year, month_seq
),
inventory_agg AS (
  SELECT
    inv.inv_item_sk AS item_sk,
    d.d_year AS year,
    d.d_month_seq AS month_seq,
    SUM(inv.inv_quantity_on_hand) AS total_inventory_on_hand
  FROM inventory inv
  JOIN date_dim d ON inv.inv_date_sk = d.d_date_sk
  WHERE d.d_date BETWEEN DATE '2000-01-01' AND DATE '2000-12-31'
  GROUP BY inv.inv_item_sk, d.d_year, d.d_month_seq
)
SELECT
  i.i_category AS category,
  i.i_category_id AS category_id,
  s.year,
  s.month_seq,
  s.total_quantity_sold,
  s.total_net_profit,
  COALESCE(r.total_return_quantity, 0) AS total_return_quantity,
  CASE WHEN s.total_quantity_sold = 0 THEN 0
       ELSE COALESCE(r.total_return_quantity, 0) * 1.0 / s.total_quantity_sold
  END AS return_rate,
  COALESCE(inv.total_inventory_on_hand, 0) AS total_inventory_on_hand
FROM sales_agg s
JOIN item i ON s.item_sk = i.i_item_sk
LEFT JOIN returns_agg r
  ON s.item_sk = r.item_sk
 AND s.year = r.year
 AND s.month_seq = r.month_seq
LEFT JOIN inventory_agg inv
  ON s.item_sk = inv.item_sk
 AND s.year = inv.year
 AND s.month_seq = inv.month_seq
ORDER BY return_rate DESC
LIMIT 100
