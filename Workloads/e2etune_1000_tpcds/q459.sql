WITH sales_agg AS (
  SELECT
    cp.cp_catalog_page_sk,
    cp.cp_department,
    cp.cp_catalog_page_number,
    i.i_brand,
    SUM(cs.cs_quantity) AS total_quantity,
    SUM(cs.cs_ext_sales_price) AS total_sales,
    SUM(cs.cs_net_profit) AS total_net_profit,
    AVG(cs.cs_ext_discount_amt) AS avg_discount
  FROM catalog_sales cs
  JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
  JOIN item i ON cs.cs_item_sk = i.i_item_sk
  WHERE cp.cp_start_date_sk BETWEEN 2450906 AND 2451088
    AND cp.cp_type = 'monthly'
  GROUP BY cp.cp_catalog_page_sk, cp.cp_department, cp.cp_catalog_page_number, i.i_brand
),
returns_agg AS (
  SELECT
    cr.cr_catalog_page_sk,
    i.i_brand,
    SUM(cr.cr_return_quantity) AS total_return_qty,
    SUM(cr.cr_net_loss) AS total_return_loss
  FROM catalog_returns cr
  JOIN item i ON cr.cr_item_sk = i.i_item_sk
  WHERE cr.cr_returned_date_sk BETWEEN 2450906 AND 2451088
  GROUP BY cr.cr_catalog_page_sk, i.i_brand
),
combined AS (
  SELECT
    sa.cp_department,
    sa.cp_catalog_page_number,
    sa.i_brand,
    sa.total_quantity,
    sa.total_sales,
    sa.total_net_profit,
    COALESCE(ra.total_return_qty, 0) AS total_return_qty,
    COALESCE(ra.total_return_loss, 0) AS total_return_loss,
    (sa.total_net_profit - COALESCE(ra.total_return_loss, 0)) AS net_profit_after_returns,
    sa.avg_discount
  FROM sales_agg sa
  LEFT JOIN returns_agg ra
    ON sa.cp_catalog_page_sk = ra.cr_catalog_page_sk
   AND sa.i_brand = ra.i_brand
)
SELECT
  cp_department,
  cp_catalog_page_number,
  i_brand,
  total_quantity,
  total_sales,
  total_net_profit,
  total_return_qty,
  total_return_loss,
  net_profit_after_returns,
  avg_discount,
  ROW_NUMBER() OVER (PARTITION BY cp_department ORDER BY net_profit_after_returns DESC) AS dept_rank
FROM combined
ORDER BY net_profit_after_returns DESC
LIMIT 10
