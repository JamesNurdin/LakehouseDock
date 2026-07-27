WITH customer_sales AS (
  SELECT
    c.c_customer_sk,
    c.c_customer_id,
    SUM(cs.cs_ext_sales_price) AS catalog_sales_total,
    SUM(ws.ws_ext_sales_price) AS web_sales_total,
    COALESCE(SUM(sr.sr_return_amt), 0) AS returns_total,
    COUNT(DISTINCT cs.cs_item_sk) AS distinct_items_purchased
  FROM
    customer c
    INNER JOIN catalog_sales cs
      ON cs.cs_bill_customer_sk = c.c_customer_sk
    INNER JOIN web_sales ws
      ON ws.ws_bill_customer_sk = c.c_customer_sk
    INNER JOIN call_center cc
      ON cs.cs_call_center_sk = cc.cc_call_center_sk
    INNER JOIN ship_mode sm
      ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    INNER JOIN item i
      ON cs.cs_item_sk = i.i_item_sk
    LEFT JOIN store_returns sr
      ON sr.sr_customer_sk = c.c_customer_sk
      AND sr.sr_item_sk = i.i_item_sk
  WHERE
    cc.cc_state = 'CA'
    AND i.i_class = 'shirts'
    AND sm.sm_type = 'AIR'
    AND cs.cs_quantity > 1
    AND ws.ws_sales_price > 10
    AND cs.cs_sold_date_sk BETWEEN 2450000 AND 2459999
  GROUP BY
    c.c_customer_sk,
    c.c_customer_id
)
SELECT
  AVG(total_sales) AS avg_total_sales_per_customer,
  SUM(total_returns) AS total_returns_all_customers,
  COUNT(*) AS customer_count
FROM (
  SELECT
    c_customer_sk,
    c_customer_id,
    (catalog_sales_total + web_sales_total) AS total_sales,
    returns_total AS total_returns
  FROM customer_sales
  WHERE (catalog_sales_total + web_sales_total) > 1000
) t
LIMIT 100
