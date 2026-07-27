WITH
  sales AS (
    SELECT
      cs.cs_item_sk AS item_sk,
      i.i_product_name AS product_name,
      td.t_hour AS hour,
      cs.cs_net_paid AS sales_net_paid,
      0.0 AS return_amt,
      cs.cs_quantity AS sales_qty,
      0 AS return_qty
    FROM catalog_sales cs
    JOIN item i
      ON cs.cs_item_sk = i.i_item_sk
    JOIN time_dim td
      ON cs.cs_sold_time_sk = td.t_time_sk
    JOIN call_center cc
      ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN household_demographics hd_bill
      ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
    JOIN household_demographics hd_ship
      ON cs.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
    WHERE cc.cc_company = 1
  ),
  returns AS (
    SELECT
      wr.wr_item_sk AS item_sk,
      i2.i_product_name AS product_name,
      td_ret.t_hour AS hour,
      0.0 AS sales_net_paid,
      wr.wr_return_amt AS return_amt,
      0 AS sales_qty,
      wr.wr_return_quantity AS return_qty
    FROM web_returns wr
    JOIN item i2
      ON wr.wr_item_sk = i2.i_item_sk
    JOIN time_dim td_ret
      ON wr.wr_returned_time_sk = td_ret.t_time_sk
    JOIN reason r
      ON wr.wr_reason_sk = r.r_reason_sk
    JOIN household_demographics hd_ref
      ON wr.wr_refunded_hdemo_sk = hd_ref.hd_demo_sk
    JOIN household_demographics hd_ret
      ON wr.wr_returning_hdemo_sk = hd_ret.hd_demo_sk
    WHERE r.r_reason_id = 'AAAAAAAACBAAAAAA'
  ),
  combined AS (
    SELECT * FROM sales
    UNION ALL
    SELECT * FROM returns
  )
SELECT
  c.item_sk,
  c.product_name,
  c.hour,
  SUM(c.sales_net_paid) AS total_sales,
  SUM(c.return_amt) AS total_returns,
  SUM(c.sales_qty) AS total_quantity_sold,
  SUM(c.return_qty) AS total_quantity_returned
FROM combined c
WHERE c.item_sk IN (
  SELECT DISTINCT i_item_sk
  FROM item
  WHERE i_brand = 'BrandX'
)
GROUP BY c.item_sk, c.product_name, c.hour
HAVING SUM(c.sales_net_paid) > (
  SELECT AVG(cs_net_paid)
  FROM catalog_sales
)
ORDER BY total_sales DESC, total_returns DESC
LIMIT 100
