WITH sales_agg AS (
    SELECT
        ss.ss_item_sk,
        i.i_category,
        i.i_product_name,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        COUNT(*) AS sales_cnt,
        MAX(ss.ss_sold_date_sk) AS max_date_sk
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    WHERE regexp_like(i.i_product_name, '[0-9]{3}')
      AND s.s_city LIKE 'San%'
      AND t.t_hour BETWEEN 9 AND 17
    GROUP BY ss.ss_item_sk, i.i_category, i.i_product_name
)
SELECT
    sa.i_category,
    sa.i_product_name,
    sa.total_sales,
    sa.sales_cnt,
    regexp_extract(sa.i_product_name, '([A-Z]+[0-9]{3})', 1) AS product_code,
    ROW_NUMBER() OVER (PARTITION BY sa.i_category ORDER BY sa.total_sales DESC) AS rn,
    (SELECT AVG(total_sales) FROM sales_agg) AS avg_sales_all_items
FROM sales_agg sa
WHERE sa.total_sales > (SELECT AVG(total_sales) FROM sales_agg)
  AND EXISTS (
        SELECT 1
        FROM catalog_sales cs
        WHERE cs.cs_item_sk = sa.ss_item_sk
          AND cs.cs_quantity > 10
    )
ORDER BY sa.i_category, rn
LIMIT 100
