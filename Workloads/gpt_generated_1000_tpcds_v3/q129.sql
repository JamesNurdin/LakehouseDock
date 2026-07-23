WITH base_sales AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_ship_date_sk,
        cs.cs_bill_customer_sk,
        cs.cs_ship_mode_sk,
        cs.cs_item_sk,
        cs.cs_quantity,
        cs.cs_sales_price,
        cs.cs_ext_discount_amt,
        cs.cs_net_paid,
        cs.cs_net_profit,
        cs.cs_order_number
    FROM catalog_sales cs
    WHERE cs.cs_quantity > 5
      AND cs.cs_sales_price > 50
      AND cs.cs_ext_discount_amt > 10
)
SELECT
    d_sold.d_year,
    i.i_category,
    i.i_container,
    sm.sm_type,
    c.c_preferred_cust_flag,
    COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
    SUM(cs.cs_net_paid) AS total_net_paid,
    AVG(cs.cs_sales_price) AS avg_sales_price,
    MIN(cs.cs_net_profit) AS min_net_profit,
    MAX(cs.cs_net_profit) AS max_net_profit,
    SUM(wr.wr_return_amt) AS total_return_amount
FROM base_sales cs
JOIN date_dim d_sold
    ON cs.cs_sold_date_sk = d_sold.d_date_sk
JOIN customer c
    ON cs.cs_bill_customer_sk = c.c_customer_sk
JOIN ship_mode sm
    ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN item i
    ON cs.cs_item_sk = i.i_item_sk
JOIN web_returns wr
    ON wr.wr_item_sk = i.i_item_sk
JOIN date_dim d_return
    ON wr.wr_returned_date_sk = d_return.d_date_sk
WHERE d_sold.d_year = 2001
  AND i.i_category = 'Electronics'
  AND i.i_container = 'Unknown'
  AND sm.sm_type = 'AIR'
  AND c.c_preferred_cust_flag = 'Y'
  AND d_return.d_year = 2001
GROUP BY
    d_sold.d_year,
    i.i_category,
    i.i_container,
    sm.sm_type,
    c.c_preferred_cust_flag
HAVING SUM(cs.cs_net_paid) > 10000
   AND COUNT(DISTINCT cs.cs_order_number) >= 10
ORDER BY total_net_paid DESC
LIMIT 100
