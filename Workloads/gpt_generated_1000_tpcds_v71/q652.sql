WITH joined AS (
  SELECT
    cs.cs_order_number,
    cs.cs_ext_sales_price,
    cs.cs_ext_discount_amt,
    cs.cs_quantity,
    cs.cs_sold_time_sk,
    cs.cs_item_sk,
    cr.cr_return_amount,
    cr.cr_return_quantity,
    cr.cr_reason_sk,
    cr.cr_returned_time_sk,
    i.i_brand,
    i.i_category,
    r.r_reason_desc,
    t.t_hour,
    ws.ws_ext_sales_price AS ws_ext_sales_price,
    ws.ws_quantity AS ws_quantity,
    ws.ws_sold_time_sk
  FROM catalog_sales cs
  JOIN time_dim t
    ON cs.cs_sold_time_sk = t.t_time_sk
  JOIN item i
    ON cs.cs_item_sk = i.i_item_sk
  JOIN catalog_returns cr
    ON cs.cs_order_number = cr.cr_order_number
   AND cs.cs_item_sk = cr.cr_item_sk
  JOIN reason r
    ON cr.cr_reason_sk = r.r_reason_sk
  JOIN web_sales ws
    ON ws.ws_item_sk = i.i_item_sk
   AND ws.ws_sold_time_sk = t.t_time_sk
  JOIN inventory inv
    ON inv.inv_item_sk = i.i_item_sk
  JOIN customer c
    ON cs.cs_bill_customer_sk = c.c_customer_sk
  JOIN time_dim t_ret
    ON cr.cr_returned_time_sk = t_ret.t_time_sk
)
SELECT
  i_brand,
  i_category,
  r_reason_desc,
  t_hour,
  SUM(cs_ext_sales_price) AS total_catalog_sales,
  SUM(ws_ext_sales_price) AS total_web_sales,
  SUM(cr_return_amount) AS total_returns,
  AVG(cs_ext_discount_amt) AS avg_discount,
  COUNT(DISTINCT cs_order_number) AS distinct_orders,
  CASE
    WHEN SUM(cr_return_quantity) > 0 THEN 'Returned'
    ELSE 'No Returns'
  END AS return_status
FROM joined
WHERE i_category = 'Sports'
  AND t_hour BETWEEN 8 AND 12
  AND cs_ext_sales_price > 500
GROUP BY GROUPING SETS (
  (i_brand, i_category, r_reason_desc, t_hour),
  (i_brand, i_category, r_reason_desc),
  (i_brand, i_category),
  (i_brand)
)
HAVING SUM(cs_ext_sales_price) > 5000
ORDER BY total_catalog_sales DESC
LIMIT 100
