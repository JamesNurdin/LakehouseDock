WITH hourly_item_sales AS (
    SELECT
        i.i_item_id,
        i.i_product_name,
        t.t_hour,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_quantity) AS total_quantity
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    WHERE i.i_brand LIKE 'brandnameless #5%'
      AND t.t_minute IN (13, 1, 14)
      AND ss.ss_quantity > 30
    GROUP BY i.i_item_id, i.i_product_name, t.t_hour
)
SELECT
    i_item_id,
    i_product_name,
    t_hour,
    total_sales,
    total_quantity,
    DENSE_RANK() OVER (PARTITION BY t_hour ORDER BY total_sales DESC) AS sales_rank_in_hour,
    SUM(total_sales) OVER (
        PARTITION BY i_item_id
        ORDER BY t_hour
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cumulative_sales_by_item,
    CASE
        WHEN total_sales >= 5000 THEN 'High'
        WHEN total_sales >= 2000 THEN 'Medium'
        ELSE 'Low'
    END AS sales_category
FROM hourly_item_sales
ORDER BY t_hour, sales_rank_in_hour
