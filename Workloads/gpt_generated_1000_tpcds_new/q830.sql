/*
Goal: Calculate sales and return performance by store, item category and sale hour, break down item metrics via UNNEST of a map, include per‑store total return amount from a correlated subquery, filter to a specific tax rate, unit type and state, and paginate the result set.
*/
WITH cs_with_map AS (
    SELECT
        cs.*, 
        map(
            array['quantity','sales_price'],
            array[cs.cs_quantity, cs.cs_ext_sales_price]
        ) AS metric_map
    FROM catalog_sales cs
)
SELECT
    s.s_store_name,
    i.i_category,
    t_sold.t_hour AS sale_hour,
    SUM(cs.cs_ext_sales_price) AS total_sales,
    SUM(sr.sr_return_amt) AS total_returns,
    COUNT(DISTINCT cs.cs_order_number) AS order_cnt,
    AVG(cs.cs_net_profit) AS avg_profit,
    MIN(cs.cs_sold_date_sk) AS first_sale_date_sk,
    metric_key,
    metric_value,
    (
        SELECT SUM(sr2.sr_return_amt)
        FROM store_returns sr2
        WHERE sr2.sr_store_sk = s.s_store_sk
    ) AS store_total_return_amount
FROM cs_with_map cs
JOIN time_dim t_sold
  ON cs.cs_sold_time_sk = t_sold.t_time_sk
JOIN item i
  ON cs.cs_item_sk = i.i_item_sk
JOIN store_returns sr
  ON sr.sr_item_sk = i.i_item_sk
JOIN store s
  ON sr.sr_store_sk = s.s_store_sk
JOIN time_dim t_return
  ON sr.sr_return_time_sk = t_return.t_time_sk
JOIN customer_address ca
  ON sr.sr_addr_sk = ca.ca_address_sk
CROSS JOIN UNNEST(cs.metric_map) AS u(metric_key, metric_value)
WHERE s.s_tax_percentage = 0.07
  AND i.i_units = 'Box'
  AND ca.ca_state = 'CA'
GROUP BY
    s.s_store_name,
    i.i_category,
    t_sold.t_hour,
    metric_key,
    metric_value,
    s.s_store_sk
HAVING SUM(cs.cs_ext_sales_price) > 100000
ORDER BY total_sales DESC
OFFSET 10 ROWS FETCH NEXT 20 ROWS ONLY
