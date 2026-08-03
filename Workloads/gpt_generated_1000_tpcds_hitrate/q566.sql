WITH cte_sales_agg AS (
    SELECT
        cs_item_sk,
        cs_catalog_page_sk,
        SUM(cs_quantity) AS total_qty,
        SUM(cs_net_paid_inc_tax) AS total_sales,
        COUNT(*) AS order_cnt
    FROM catalog_sales
    WHERE cs_net_paid_inc_tax > 5000
      AND cs_quantity >= 1
      AND cs_ext_ship_cost < 3000
      AND cs_sold_date_sk BETWEEN 2450815 AND 2451240
    GROUP BY cs_item_sk, cs_catalog_page_sk
),
union_data AS (
    SELECT
        cp.cp_department AS cp_department,
        i.i_category AS i_category,
        i.i_size AS i_size,
        sa.total_qty,
        sa.total_sales,
        sa.order_cnt,
        (sa.total_sales / NULLIF(sa.order_cnt, 0)) AS avg_sales,
        LAG(sa.total_sales) OVER (PARTITION BY cp.cp_department ORDER BY sa.total_sales DESC) AS prev_sales,
        RANK() OVER (PARTITION BY cp.cp_department ORDER BY sa.total_sales DESC) AS dept_rank
    FROM cte_sales_agg sa
    JOIN catalog_page cp ON sa.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN item i ON sa.cs_item_sk = i.i_item_sk
    WHERE cp.cp_department = 'Electronics'
      AND i.i_size = 'large'
      AND i.i_category = 'Sports'
      AND NOT EXISTS (
          SELECT 1 FROM catalog_sales cs2
          WHERE cs2.cs_item_sk = sa.cs_item_sk
            AND cs2.cs_quantity > 100
      )

    UNION DISTINCT

    SELECT
        cp.cp_department AS cp_department,
        i.i_category AS i_category,
        i.i_size AS i_size,
        sa.total_qty,
        sa.total_sales,
        sa.order_cnt,
        (sa.total_sales / NULLIF(sa.order_cnt, 0)) AS avg_sales,
        LAG(sa.total_sales) OVER (PARTITION BY cp.cp_department ORDER BY sa.total_sales DESC) AS prev_sales,
        RANK() OVER (PARTITION BY cp.cp_department ORDER BY sa.total_sales DESC) AS dept_rank
    FROM cte_sales_agg sa
    JOIN catalog_page cp ON sa.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN item i ON sa.cs_item_sk = i.i_item_sk
    WHERE cp.cp_type = 'A'
      AND i.i_color = 'Red'
      AND i.i_size = 'small'
      AND NOT EXISTS (
          SELECT 1 FROM catalog_sales cs2
          WHERE cs2.cs_item_sk = sa.cs_item_sk
            AND cs2.cs_quantity > 100
      )
)
SELECT
    cp_department,
    i_category,
    i_size,
    total_qty,
    total_sales,
    order_cnt,
    avg_sales,
    prev_sales,
    dept_rank
FROM union_data
WHERE dept_rank <= 3
ORDER BY cp_department, dept_rank
LIMIT 100
