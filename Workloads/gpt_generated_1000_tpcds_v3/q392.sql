WITH sales_by_hour AS (
    SELECT
        td.t_hour AS hour,
        td.t_shift AS shift,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        SUM(cs.cs_quantity) AS total_quantity,
        AVG(cs.cs_ext_discount_amt) AS avg_discount,
        COUNT(*) AS order_count
    FROM catalog_sales cs
    JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
    WHERE cs.cs_ext_list_price > 1000
      AND cs.cs_wholesale_cost BETWEEN 30 AND 100
      AND cs.cs_ext_tax < 50
      AND cs.cs_quantity >= 2
      AND td.t_second IN (1, 2, 3, 8)
    GROUP BY td.t_hour, td.t_shift
)
SELECT
    hour,
    shift,
    total_sales,
    total_quantity,
    avg_discount,
    order_count,
    ROW_NUMBER() OVER (ORDER BY total_sales DESC) AS sales_rank,
    AVG(total_sales) OVER () AS avg_sales_all
FROM sales_by_hour
WHERE total_sales > 5000
ORDER BY sales_rank
LIMIT 100
