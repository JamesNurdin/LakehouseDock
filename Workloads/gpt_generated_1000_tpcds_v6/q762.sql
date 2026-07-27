WITH sales_summary AS (
    SELECT i.i_manager_id AS manager_id,
           SUM(cs.cs_ext_sales_price) AS total_amount,
           SUM(cs.cs_quantity) AS total_quantity,
           'sales' AS source
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
    WHERE cs.cs_ext_ship_cost > 1000
      AND t.t_hour BETWEEN 9 AND 17
    GROUP BY i.i_manager_id
    HAVING SUM(cs.cs_ext_sales_price) > 5000
),
returns_summary AS (
    SELECT i.i_manager_id AS manager_id,
           -SUM(wr.wr_return_amt) AS total_amount,
           SUM(wr.wr_return_quantity) AS total_quantity,
           'returns' AS source
    FROM web_returns wr
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    JOIN customer c ON wr.wr_refunded_customer_sk = c.c_customer_sk
    JOIN time_dim t ON wr.wr_returned_time_sk = t.t_time_sk
    WHERE wr.wr_return_amt > 100
      AND t.t_hour BETWEEN 9 AND 17
    GROUP BY i.i_manager_id
    HAVING SUM(wr.wr_return_amt) > 500
)
SELECT manager_id,
       total_amount,
       total_quantity,
       source
FROM sales_summary
UNION ALL
SELECT manager_id,
       total_amount,
       total_quantity,
       source
FROM returns_summary
ORDER BY total_amount DESC, manager_id
LIMIT 100
