WITH sales AS (
  SELECT
    cs.cs_order_number,
    cs.cs_ext_sales_price,
    cs.cs_net_profit,
    d_sales.d_year,
    hd_bill.hd_buy_potential,
    hd_bill.hd_vehicle_count,
    CASE WHEN cs.cs_ext_sales_price > 1000 THEN 'High' ELSE 'Low' END AS sales_category,
    ROW_NUMBER() OVER (PARTITION BY d_sales.d_year ORDER BY cs.cs_ext_sales_price DESC) AS rn_sales_year
  FROM catalog_sales cs
  JOIN date_dim d_sales ON cs.cs_sold_date_sk = d_sales.d_date_sk
  JOIN household_demographics hd_bill ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
  WHERE d_sales.d_year BETWEEN 2000 AND 2002
    AND cs.cs_quantity > 5
    AND cs.cs_wholesale_cost > 20
    AND hd_bill.hd_vehicle_count >= 2
),
returns AS (
  SELECT
    sr.sr_ticket_number,
    sr.sr_return_amt,
    d_returns.d_year AS return_year,
    hd_ret.hd_buy_potential,
    store.s_store_name,
    CASE WHEN sr.sr_return_amt > 200 THEN 'Big' ELSE 'Small' END AS return_category,
    ROW_NUMBER() OVER (ORDER BY sr.sr_return_amt DESC) AS rn_return_global
  FROM store_returns sr
  JOIN date_dim d_returns ON sr.sr_returned_date_sk = d_returns.d_date_sk
  JOIN household_demographics hd_ret ON sr.sr_hdemo_sk = hd_ret.hd_demo_sk
  JOIN store ON sr.sr_store_sk = store.s_store_sk
  WHERE d_returns.d_year = 2001
    AND sr.sr_return_quantity > 1
    AND sr.sr_fee > 10
    AND store.s_state = 'CA'
),
combined AS (
  SELECT
    s.cs_order_number AS id,
    s.sales_category AS category,
    s.rn_sales_year AS rank_in_year,
    NULL AS return_amt,
    s.d_year AS year,
    'sale' AS type
  FROM sales s
  UNION
  SELECT
    r.sr_ticket_number AS id,
    r.return_category AS category,
    r.rn_return_global AS rank_in_year,
    r.sr_return_amt AS return_amt,
    r.return_year AS year,
    'return' AS type
  FROM returns r
),
filtered_excluded AS (
  SELECT id FROM combined WHERE type = 'sale'
  EXCEPT
  SELECT id FROM combined WHERE category = 'Low' AND type = 'sale'
)
SELECT
  c.id,
  c.category,
  c.year,
  c.type,
  CASE WHEN EXISTS (SELECT 1 FROM sales s WHERE s.cs_order_number = c.id) THEN 'Sale' ELSE 'Return' END AS source_flag,
  ROW_NUMBER() OVER (ORDER BY c.year, c.rank_in_year) AS global_row_num
FROM combined c
WHERE c.id IN (SELECT id FROM filtered_excluded)
ORDER BY c.year, global_row_num
LIMIT 100
