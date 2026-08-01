WITH
  sales_agg AS (
    SELECT
      d.d_year,
      i.i_item_id,
      i.i_category,
      SUM(cs.cs_ext_sales_price) AS total_sales,
      SUM(cs.cs_net_profit)      AS total_profit
    FROM catalog_sales cs
    JOIN date_dim d           ON cs.cs_sold_date_sk   = d.d_date_sk
    JOIN item i               ON cs.cs_item_sk        = i.i_item_sk
    JOIN call_center cc       ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN warehouse w          ON cs.cs_warehouse_sk   = w.w_warehouse_sk
    JOIN customer_demographics cd  ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca       ON cs.cs_bill_addr_sk  = ca.ca_address_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
      AND cc.cc_employees > 1000000
      AND w.w_warehouse_sq_ft > 1000000
      AND i.i_current_price > 50
      AND cd.cd_gender = 'M'
      AND hd.hd_vehicle_count >= 1
    GROUP BY GROUPING SETS (
      (d.d_year, i.i_item_id, i.i_category),
      (d.d_year, i.i_item_id),
      (d.d_year)
    )
  ),
  returns_agg AS (
    SELECT
      d.d_year,
      i.i_item_id,
      i.i_category,
      SUM(sr.sr_return_amt) AS total_return_amt,
      SUM(sr.sr_net_loss)   AS total_net_loss
    FROM store_returns sr
    JOIN date_dim d        ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN time_dim t        ON sr.sr_return_time_sk   = t.t_time_sk
    JOIN item i            ON sr.sr_item_sk          = i.i_item_sk
    JOIN reason r          ON sr.sr_reason_sk        = r.r_reason_sk
    JOIN customer_address ca ON sr.sr_addr_sk        = ca.ca_address_sk
    JOIN customer_demographics cd ON sr.sr_cdemo_sk   = cd.cd_demo_sk
    JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
      AND r.r_reason_desc LIKE '%defect%'
      AND ca.ca_state = 'CA'
      AND cd.cd_marital_status = 'M'
      AND hd.hd_buy_potential = '1001-5000'
      AND i.i_color = 'Red'
    GROUP BY GROUPING SETS (
      (d.d_year, i.i_item_id, i.i_category),
      (d.d_year, i.i_item_id),
      (d.d_year)
    )
  ),
  inventory_agg AS (
    SELECT
      d.d_year,
      i.i_item_id,
      SUM(inv.inv_quantity_on_hand) AS qty_on_hand
    FROM inventory inv
    JOIN date_dim d       ON inv.inv_date_sk     = d.d_date_sk
    JOIN item i           ON inv.inv_item_sk     = i.i_item_sk
    JOIN warehouse w     ON inv.inv_warehouse_sk = w.w_warehouse_sk
    WHERE d.d_year = 2001
      AND w.w_state = 'TX'
      AND i.i_size = 'M'
    GROUP BY d.d_year, i.i_item_id
  ),
  web_returns_agg AS (
    SELECT
      d.d_year,
      i.i_item_id,
      SUM(wr.wr_return_amt) AS web_return_amt,
      SUM(wr.wr_net_loss)   AS web_net_loss
    FROM web_returns wr
    JOIN date_dim d          ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN time_dim t          ON wr.wr_returned_time_sk = t.t_time_sk
    JOIN item i              ON wr.wr_item_sk          = i.i_item_sk
    JOIN reason r            ON wr.wr_reason_sk        = r.r_reason_sk
    WHERE d.d_year = 2001
      AND r.r_reason_desc = 'Customer not happy'
      AND i.i_brand = 'Brand#12'
    GROUP BY d.d_year, i.i_item_id
  )
SELECT
  sa.d_year,
  sa.i_item_id,
  sa.i_category,
  sa.total_sales,
  ra.total_return_amt,
  (sa.total_sales - COALESCE(ra.total_return_amt, 0)) AS net_sales,
  ROW_NUMBER() OVER (PARTITION BY sa.d_year ORDER BY (sa.total_sales - COALESCE(ra.total_return_amt, 0)) DESC) AS sales_rank,
  CASE
    WHEN (sa.total_sales - COALESCE(ra.total_return_amt, 0)) > (
      SELECT AVG(total_sales) FROM sales_agg WHERE d_year = sa.d_year
    ) THEN 'Above Avg'
    ELSE 'Below Avg'
  END AS performance
FROM sales_agg sa
LEFT JOIN returns_agg ra
  ON sa.d_year = ra.d_year AND sa.i_item_id = ra.i_item_id
WHERE sa.total_sales > 10000
  AND EXISTS (
    SELECT 1 FROM inventory_agg inv
    WHERE inv.d_year = sa.d_year
      AND inv.i_item_id = sa.i_item_id
      AND inv.qty_on_hand > 0
  )
UNION
SELECT
  wr.d_year,
  wr.i_item_id,
  NULL AS i_category,
  NULL AS total_sales,
  wr.web_return_amt AS total_return_amt,
  NULL AS net_sales,
  ROW_NUMBER() OVER (PARTITION BY wr.d_year ORDER BY wr.web_return_amt DESC) AS sales_rank,
  'WebReturn' AS performance
FROM web_returns_agg wr
WHERE wr.web_return_amt > 5000
LIMIT 100
