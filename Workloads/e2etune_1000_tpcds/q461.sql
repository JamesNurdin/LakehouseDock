WITH sales_returns AS (
  SELECT
    i.i_category,
    i.i_brand,
    SUM(cs.cs_net_paid_inc_ship_tax) AS total_sales,
    SUM(cr.cr_return_amount) AS total_returns,
    SUM(cs.cs_net_profit) - SUM(cr.cr_net_loss) AS net_profit_adj,
    SUM(cs.cs_quantity) AS total_quantity_sold,
    SUM(cr.cr_return_quantity) AS total_quantity_returned,
    AVG(cs.cs_ext_discount_amt) AS avg_discount
  FROM catalog_sales cs
  JOIN catalog_returns cr
    ON cs.cs_order_number = cr.cr_order_number
   AND cs.cs_item_sk = cr.cr_item_sk
  JOIN customer c
    ON cs.cs_bill_customer_sk = c.c_customer_sk
  JOIN item i
    ON cs.cs_item_sk = i.i_item_sk
  WHERE c.c_preferred_cust_flag = 'Y'
    AND cr.cr_returned_time_sk BETWEEN 30000 AND 60000
    AND cs.cs_sold_date_sk BETWEEN 2450000 AND 2451000
  GROUP BY i.i_category, i.i_brand
  HAVING SUM(cs.cs_quantity) > 100
)
SELECT
  i_category,
  i_brand,
  total_sales,
  total_returns,
  net_profit_adj,
  total_quantity_sold,
  total_quantity_returned,
  CASE WHEN total_quantity_sold = 0 THEN 0
       ELSE CAST(total_quantity_returned AS double) / total_quantity_sold END AS return_rate,
  avg_discount,
  RANK() OVER (ORDER BY net_profit_adj DESC) AS profit_rank
FROM sales_returns
ORDER BY net_profit_adj DESC
LIMIT 50
