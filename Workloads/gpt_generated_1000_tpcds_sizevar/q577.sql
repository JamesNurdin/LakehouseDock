WITH sampled_sales AS (
    SELECT *
    FROM catalog_sales
    TABLESAMPLE BERNOULLI (10)  -- sample 10% of rows
),
qualified_sales AS (
    SELECT
        cs_item_sk,
        cs_order_number,
        cs_sold_time_sk,
        cs_ext_sales_price,
        cs_list_price,
        CAST(cs_ext_sales_price AS varchar) AS ext_sales_price_str
    FROM sampled_sales
    WHERE cs_list_price BETWEEN 50 AND 200
      AND regexp_like(CAST(cs_ext_sales_price AS varchar), '^\\d{3,}\\.?\\d*$') -- at least three digits before optional decimal
),
joined_sales AS (
    SELECT
        qs.cs_item_sk,
        qs.cs_order_number,
        qs.cs_ext_sales_price,
        qs.cs_list_price,
        td.t_shift,
        td.t_sub_shift,
        td.t_time_id,
        td.t_hour
    FROM qualified_sales qs
    JOIN time_dim td
        ON qs.cs_sold_time_sk = td.t_time_sk
    WHERE td.t_shift LIKE 'second%'
      AND substring(td.t_sub_shift, 1, 3) = 'mor'
      AND regexp_like(td.t_time_id, '^t[0-9]+$')
)
SELECT
    CONCAT(j.t_shift, '-', j.t_sub_shift) AS shift_pair,
    COUNT(DISTINCT j.cs_item_sk) AS distinct_items,
    COUNT(DISTINCT j.cs_order_number) AS distinct_orders,
    SUM(j.cs_ext_sales_price) AS total_sales,
    AVG(j.cs_list_price) AS avg_list_price
FROM joined_sales j
WHERE EXISTS (
        SELECT 1
        FROM catalog_sales cs2
        WHERE cs2.cs_item_sk = j.cs_item_sk
          AND cs2.cs_ext_discount_amt > 20
    )
  AND j.cs_item_sk IN (
        SELECT cs_item_sk FROM catalog_sales WHERE cs_quantity > 5
        INTERSECT
        SELECT cs_item_sk FROM catalog_sales WHERE cs_wholesale_cost < 30
    )
GROUP BY CONCAT(j.t_shift, '-', j.t_sub_shift)
ORDER BY total_sales DESC
LIMIT 10
