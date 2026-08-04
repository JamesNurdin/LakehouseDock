WITH sales_data AS (
  SELECT
    d.d_year,
    i.i_category,
    SUM(ss.ss_ext_sales_price) AS sales_amount,
    SUM(ss.ss_net_profit) AS profit_amount,
    0.0 AS returns_amount,
    0.0 AS loss_amount,
    ARRAY_AGG(DISTINCT i.i_item_sk) AS item_array
  FROM store_sales ss
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN item i ON ss.ss_item_sk = i.i_item_sk
  JOIN inventory inv TABLESAMPLE BERNOULLI (10) ON inv.inv_date_sk = d.d_date_sk
                                       AND inv.inv_item_sk = i.i_item_sk
  WHERE d.d_year = 2020
    AND inv.inv_quantity_on_hand > 0
  GROUP BY d.d_year, i.i_category
),
sales_expanded AS (
  SELECT
    sd.d_year,
    sd.i_category,
    sd.sales_amount,
    sd.profit_amount,
    sd.returns_amount,
    sd.loss_amount,
    i_sk AS item_sk
  FROM sales_data sd
  CROSS JOIN UNNEST(sd.item_array) AS t(i_sk)
),
returns_data AS (
  SELECT
    d.d_year,
    i.i_category,
    0.0 AS sales_amount,
    0.0 AS profit_amount,
    SUM(cr.cr_return_amount) AS returns_amount,
    SUM(cr.cr_net_loss) AS loss_amount,
    ARRAY_AGG(DISTINCT i.i_item_sk) AS item_array
  FROM catalog_returns cr
  JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
  JOIN item i ON cr.cr_item_sk = i.i_item_sk
  JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
  WHERE d.d_year = 2020
  GROUP BY d.d_year, i.i_category
),
returns_expanded AS (
  SELECT
    rd.d_year,
    rd.i_category,
    rd.sales_amount,
    rd.profit_amount,
    rd.returns_amount,
    rd.loss_amount,
    i_sk AS item_sk
  FROM returns_data rd
  CROSS JOIN UNNEST(rd.item_array) AS t(i_sk)
),
combined AS (
  SELECT * FROM sales_expanded
  UNION ALL
  SELECT * FROM returns_expanded
)
SELECT
  c.d_year,
  c.i_category,
  c.item_sk,
  c.sales_amount,
  c.profit_amount,
  c.returns_amount,
  c.loss_amount,
  CASE WHEN c.profit_amount > 0 THEN 'Profitable' ELSE 'Unprofitable' END AS profit_flag,
  SUM(c.sales_amount) OVER (
    PARTITION BY c.i_category
    ORDER BY c.d_year
    ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
  ) AS running_sales
FROM combined c
WHERE c.item_sk IS NOT NULL
ORDER BY c.d_year DESC, c.i_category
OFFSET 0 LIMIT 100
