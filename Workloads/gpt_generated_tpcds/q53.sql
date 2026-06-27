WITH monthly_category_profit AS (
  SELECT
    d_sales.d_year,
    d_sales.d_month_seq,
    i.i_category,
    i.i_brand,
    sum(cs.cs_quantity) AS total_quantity_sold,
    sum(cs.cs_net_profit) AS total_net_profit,
    sum(coalesce(cr.cr_return_quantity, 0)) AS total_quantity_returned,
    sum(coalesce(cr.cr_net_loss, 0)) AS total_return_loss,
    sum(cs.cs_ext_discount_amt) AS total_discount,
    count(DISTINCT cs.cs_bill_customer_sk) AS distinct_customers
  FROM catalog_sales cs
  JOIN date_dim d_sales
    ON cs.cs_sold_date_sk = d_sales.d_date_sk
  LEFT JOIN catalog_returns cr
    ON cs.cs_order_number = cr.cr_order_number
   AND cs.cs_item_sk = cr.cr_item_sk
  JOIN item i
    ON cs.cs_item_sk = i.i_item_sk
  JOIN customer c
    ON cs.cs_bill_customer_sk = c.c_customer_sk
  WHERE d_sales.d_year = 2001
  GROUP BY d_sales.d_year, d_sales.d_month_seq, i.i_category, i.i_brand
)
SELECT
  d_year,
  d_month_seq,
  i_category,
  i_brand,
  total_quantity_sold,
  total_net_profit,
  total_quantity_returned,
  total_return_loss,
  total_discount,
  distinct_customers,
  rank() OVER (PARTITION BY d_year, d_month_seq ORDER BY total_net_profit DESC) AS profit_rank
FROM monthly_category_profit
ORDER BY d_year, d_month_seq, profit_rank
