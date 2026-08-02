/*
Goal: Identify the most valuable product categories per department during mid‑day hours, filtered by brand and catalog page, and rank them by total sales. Only keep groups where the items have at least one other sale of quantity ≥ 5 (correlated EXISTS). The query pre‑aggregates catalog_sales, joins all four tables, applies multiple predicates, uses a HAVING filter, and orders the final ranked result.
*/
WITH cs_agg AS (
    SELECT
        cs.cs_item_sk,
        cs.cs_catalog_page_sk,
        cs.cs_sold_time_sk,
        SUM(cs.cs_ext_sales_price) AS total_ext_sales_price,
        SUM(cs.cs_quantity) AS total_quantity,
        COUNT(*) AS sales_cnt
    FROM catalog_sales cs
    WHERE cs.cs_sales_price > 50
      AND cs.cs_quantity > 1
      AND cs.cs_ext_discount_amt > 0
    GROUP BY cs.cs_item_sk, cs.cs_catalog_page_sk, cs.cs_sold_time_sk
),
joined AS (
    SELECT
        cp.cp_department,
        i.i_category,
        i.i_brand_id,
        td.t_hour,
        td.t_meal_time,
        cs_agg.cs_item_sk,
        cs_agg.cs_sold_time_sk,
        cs_agg.total_ext_sales_price,
        cs_agg.total_quantity,
        cs_agg.sales_cnt
    FROM cs_agg
    JOIN catalog_page cp
        ON cs_agg.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN item i
        ON cs_agg.cs_item_sk = i.i_item_sk
    JOIN time_dim td
        ON cs_agg.cs_sold_time_sk = td.t_time_sk
    WHERE cp.cp_catalog_page_number BETWEEN 3 AND 19
      AND i.i_brand_id IN (2004002, 1003001)
      AND td.t_hour BETWEEN 10 AND 14
)
SELECT
    cp_department,
    i_category,
    i_brand_id,
    t_hour,
    t_meal_time,
    cs_item_sk,
    cs_sold_time_sk,
    SUM(total_ext_sales_price) AS sum_sales_price,
    SUM(total_quantity) AS sum_quantity,
    COUNT(*) AS num_rows,
    RANK() OVER (PARTITION BY cp_department ORDER BY SUM(total_ext_sales_price) DESC) AS sales_rank
FROM joined
WHERE EXISTS (
    SELECT 1
    FROM catalog_sales cs2
    WHERE cs2.cs_item_sk = joined.cs_item_sk
      AND cs2.cs_sold_time_sk = joined.cs_sold_time_sk
      AND cs2.cs_quantity >= 5
)
GROUP BY cp_department, i_category, i_brand_id, t_hour, t_meal_time, cs_item_sk, cs_sold_time_sk
HAVING SUM(total_ext_sales_price) > 1000
ORDER BY cp_department, sales_rank, sum_sales_price DESC
