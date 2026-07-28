WITH joined AS (
  SELECT
    i.i_item_sk,
    i.i_manufact_id,
    cp.cp_department,
    cd.cd_gender,
    cs.cs_order_number,
    cs.cs_ext_sales_price,
    cs.cs_net_paid,
    ss.ss_quantity,
    ss.ss_net_paid,
    wr.wr_return_amt,
    wr.wr_return_ship_cost
  FROM catalog_sales cs
  JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
  JOIN item i ON cs.cs_item_sk = i.i_item_sk
  JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
  JOIN store_sales ss ON ss.ss_item_sk = i.i_item_sk
  JOIN web_returns wr ON wr.wr_item_sk = i.i_item_sk
  WHERE i.i_manufact_id IN (264, 214)
    AND i.i_rec_end_date >= DATE '1999-01-01'
    AND cp.cp_department = 'Electronics'
    AND cs.cs_ship_date_sk BETWEEN 2450845 AND 2450899
    AND cd.cd_gender = 'M'
    AND ss.ss_quantity > 2
    AND wr.wr_return_ship_cost > 100
)
SELECT
  i_item_sk,
  i_manufact_id,
  cp_department,
  cd_gender,
  COUNT(DISTINCT cs_order_number) AS distinct_orders,
  SUM(cs_net_paid) AS total_cs_net_paid,
  SUM(ss_net_paid) AS total_ss_net_paid,
  SUM(wr_return_amt) AS total_wr_return_amt,
  AVG(cs_ext_sales_price) AS avg_cs_ext_sales_price,
  CASE
    WHEN SUM(cs_ext_sales_price) > (
      SELECT AVG(cs2.cs_ext_sales_price)
      FROM catalog_sales cs2
      WHERE cs2.cs_item_sk = j.i_item_sk
    ) THEN 'Above Avg'
    ELSE 'Below Avg'
  END AS sales_price_category
FROM joined j
GROUP BY
  i_item_sk,
  i_manufact_id,
  cp_department,
  cd_gender
ORDER BY total_cs_net_paid DESC
LIMIT 100
