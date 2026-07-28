WITH avg_sales AS (
    SELECT AVG(cs.cs_ext_sales_price) AS avg_price
    FROM catalog_sales cs
)
SELECT item_id,
       category,
       total_sales,
       order_cnt,
       period
FROM (
    SELECT i.i_item_id AS item_id,
           i.i_category AS category,
           SUM(cs.cs_ext_sales_price) AS total_sales,
           COUNT(*) AS order_cnt,
           'Lunch' AS period
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
    WHERE td.t_meal_time = 'lunch'
      AND NOT EXISTS (
          SELECT 1 FROM promotion p WHERE p.p_item_sk = i.i_item_sk
      )
    GROUP BY i.i_item_id, i.i_category
    HAVING SUM(cs.cs_ext_sales_price) > (SELECT avg_price FROM avg_sales)

    UNION ALL

    SELECT i.i_item_id AS item_id,
           i.i_category AS category,
           SUM(cs.cs_ext_sales_price) AS total_sales,
           COUNT(*) AS order_cnt,
           'Dinner' AS period
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
    WHERE td.t_meal_time = 'dinner'
      AND NOT EXISTS (
          SELECT 1 FROM promotion p WHERE p.p_item_sk = i.i_item_sk
      )
    GROUP BY i.i_item_id, i.i_category
    HAVING SUM(cs.cs_ext_sales_price) > (SELECT avg_price FROM avg_sales)
) AS combined
ORDER BY total_sales DESC
LIMIT 100
