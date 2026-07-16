WITH sales_agg AS (
  SELECT
    cs.cs_call_center_sk,
    d.d_year,
    d.d_quarter_name,
    cs.cs_item_sk,
    SUM(cs.cs_net_profit) AS total_profit,
    SUM(cs.cs_quantity) AS total_quantity,
    SUM(cs.cs_net_paid) AS total_sales
  FROM catalog_sales cs
  JOIN date_dim d
    ON cs.cs_sold_date_sk = d.d_date_sk
  JOIN call_center cc
    ON cs.cs_call_center_sk = cc.cc_call_center_sk
  WHERE cc.cc_state IN ('TN', 'GA')
    AND d.d_year BETWEEN 2001 AND 2003
  GROUP BY cs.cs_call_center_sk, d.d_year, d.d_quarter_name, cs.cs_item_sk
),
returns_agg AS (
  SELECT
    cr.cr_call_center_sk,
    d.d_year,
    d.d_quarter_name,
    cr.cr_item_sk,
    SUM(cr.cr_net_loss) AS total_return_loss,
    SUM(cr.cr_return_quantity) AS total_return_qty,
    SUM(cr.cr_return_amount) AS total_return_amount
  FROM catalog_returns cr
  JOIN date_dim d
    ON cr.cr_returned_date_sk = d.d_date_sk
  JOIN call_center cc
    ON cr.cr_call_center_sk = cc.cc_call_center_sk
  WHERE cc.cc_state IN ('TN', 'GA')
    AND d.d_year BETWEEN 2001 AND 2003
  GROUP BY cr.cr_call_center_sk, d.d_year, d.d_quarter_name, cr.cr_item_sk
),
inventory_agg AS (
  SELECT
    inv.inv_item_sk,
    AVG(inv.inv_quantity_on_hand) AS avg_inventory
  FROM inventory inv
  JOIN date_dim d
    ON inv.inv_date_sk = d.d_date_sk
  WHERE d.d_year BETWEEN 2001 AND 2003
  GROUP BY inv.inv_item_sk
)
SELECT
  cc.cc_name,
  s.d_year,
  s.d_quarter_name,
  i.i_category,
  i.i_brand,
  s.total_quantity,
  s.total_sales,
  s.total_profit,
  COALESCE(r.total_return_loss, 0) AS total_return_loss,
  s.total_profit - COALESCE(r.total_return_loss, 0) AS net_profit_after_returns,
  inv.avg_inventory,
  (s.total_profit - COALESCE(r.total_return_loss, 0)) / NULLIF(inv.avg_inventory, 0) AS profit_per_inventory,
  RANK() OVER (PARTITION BY s.d_year, s.d_quarter_name ORDER BY (s.total_profit - COALESCE(r.total_return_loss, 0)) DESC) AS profit_rank
FROM sales_agg s
LEFT JOIN returns_agg r
  ON s.cs_call_center_sk = r.cr_call_center_sk
  AND s.d_year = r.d_year
  AND s.d_quarter_name = r.d_quarter_name
  AND s.cs_item_sk = r.cr_item_sk
JOIN call_center cc
  ON s.cs_call_center_sk = cc.cc_call_center_sk
JOIN item i
  ON s.cs_item_sk = i.i_item_sk
LEFT JOIN inventory_agg inv
  ON s.cs_item_sk = inv.inv_item_sk
WHERE s.total_quantity > 0
ORDER BY net_profit_after_returns DESC
LIMIT 50
