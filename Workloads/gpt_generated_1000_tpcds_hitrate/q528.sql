WITH
  sales_agg AS (
    SELECT
      cs.cs_item_sk,
      i.i_product_name,
      d.d_year,
      SUM(cs.cs_net_profit) AS total_profit,
      COUNT(*) AS sale_cnt
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    WHERE d.d_year = 2001
      AND cs.cs_item_sk IN (
        SELECT inv_item_sk
        FROM inventory
        WHERE inv_quantity_on_hand > 500
      )
    GROUP BY cs.cs_item_sk, i.i_product_name, d.d_year
  ),
  sales_with_inventory AS (
    SELECT
      s.*, 
      inv.latest_qty
    FROM sales_agg s
    CROSS JOIN LATERAL (
      SELECT inv_quantity_on_hand AS latest_qty
      FROM inventory inv
      WHERE inv.inv_item_sk = s.cs_item_sk
      ORDER BY inv.inv_date_sk DESC
      LIMIT 1
    ) inv
  ),
  sales_ranked AS (
    SELECT
      s.cs_item_sk,
      s.i_product_name,
      s.d_year,
      s.total_profit,
      s.sale_cnt,
      s.latest_qty,
      CASE
        WHEN s.total_profit > 10000 THEN 'High'
        WHEN s.total_profit > 5000  THEN 'Medium'
        ELSE 'Low'
      END AS profit_category,
      ROW_NUMBER() OVER (PARTITION BY s.d_year ORDER BY s.total_profit DESC) AS profit_rank,
      (SELECT AVG(ib_lower_bound) FROM income_band) AS avg_income_lower
    FROM sales_with_inventory s
  ),
  returns_agg AS (
    SELECT
      cr.cr_item_sk,
      i.i_product_name,
      d.d_year,
      SUM(cr.cr_return_amount) AS total_return_amount,
      COUNT(*) AS return_cnt
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    WHERE d.d_year = 2001
      AND EXISTS (
        SELECT 1
        FROM reason r
        WHERE r.r_reason_sk = cr.cr_reason_sk
          AND r.r_reason_desc LIKE '%damage%'
      )
    GROUP BY cr.cr_item_sk, i.i_product_name, d.d_year
  ),
  returns_ranked AS (
    SELECT
      ra.cr_item_sk,
      ra.i_product_name,
      ra.d_year,
      ra.total_return_amount,
      ra.return_cnt,
      CASE
        WHEN ra.total_return_amount > 5000 THEN 'High'
        WHEN ra.total_return_amount > 2000 THEN 'Medium'
        ELSE 'Low'
      END AS profit_category,
      ROW_NUMBER() OVER (PARTITION BY ra.d_year ORDER BY ra.total_return_amount DESC) AS profit_rank,
      (SELECT AVG(ib_lower_bound) FROM income_band) AS avg_income_lower
    FROM returns_agg ra
  )
SELECT
  combined.item_sk,
  combined.product_name,
  combined.d_year,
  combined.metric_value,
  combined.profit_category,
  combined.profit_rank,
  combined.latest_qty,
  combined.avg_income_lower,
  combined.source_type
FROM (
  SELECT
    sr.cs_item_sk      AS item_sk,
    sr.i_product_name  AS product_name,
    sr.d_year,
    sr.total_profit    AS metric_value,
    sr.profit_category,
    sr.profit_rank,
    sr.latest_qty,
    sr.avg_income_lower,
    'sales'            AS source_type
  FROM sales_ranked sr

  UNION ALL

  SELECT
    rr.cr_item_sk      AS item_sk,
    rr.i_product_name  AS product_name,
    rr.d_year,
    rr.total_return_amount AS metric_value,
    rr.profit_category,
    rr.profit_rank,
    NULL               AS latest_qty,
    rr.avg_income_lower,
    'returns'          AS source_type
  FROM returns_ranked rr
) combined
ORDER BY combined.d_year DESC, combined.metric_value DESC
LIMIT 100
