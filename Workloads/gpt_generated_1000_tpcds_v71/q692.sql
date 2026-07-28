WITH sales_warehouse AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_order_number,
        cs.cs_quantity,
        cs.cs_list_price,
        cs.cs_sales_price,
        cs.cs_ext_sales_price,
        cs.cs_net_profit,
        cs.cs_warehouse_sk,
        w.w_warehouse_name,
        w.w_city,
        w.w_state,
        w.w_warehouse_sq_ft,
        w.w_street_type
    FROM catalog_sales cs
    JOIN warehouse w
      ON cs.cs_warehouse_sk = w.w_warehouse_sk
    WHERE cs.cs_quantity > 1
      AND cs.cs_list_price BETWEEN 30 AND 200
      AND cs.cs_sales_price > 10
      AND w.w_warehouse_sq_ft > 500000
      AND w.w_street_type IN ('RD', 'Drive', 'ST')
      AND w.w_state = 'CA'
)
SELECT
    w_city,
    w_state,
    w_warehouse_name,
    SUM(cs_ext_sales_price) AS total_sales,
    AVG(cs_net_profit) AS avg_profit,
    COUNT(DISTINCT cs_order_number) AS order_cnt,
    RANK() OVER (PARTITION BY w_state ORDER BY SUM(cs_ext_sales_price) DESC) AS sales_rank_state,
    ROW_NUMBER() OVER (ORDER BY SUM(cs_ext_sales_price) DESC) AS overall_rank
FROM sales_warehouse
GROUP BY w_city, w_state, w_warehouse_name
HAVING SUM(cs_ext_sales_price) > 100000
ORDER BY total_sales DESC
LIMIT 100
