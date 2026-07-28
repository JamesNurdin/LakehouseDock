WITH cat_sales AS (
    SELECT
        d.d_year AS year,
        i.i_category AS category,
        SUM(cs.cs_ext_sales_price) AS sales_amount,
        COUNT(*) AS sales_cnt,
        CAST(NULL AS decimal(7,2)) AS profit_amount
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
    GROUP BY d.d_year, i.i_category
),
store_sales_agg AS (
    SELECT
        d.d_year AS year,
        i.i_category AS category,
        CAST(NULL AS decimal(7,2)) AS sales_amount,
        CAST(NULL AS integer) AS sales_cnt,
        SUM(ss.ss_net_profit) AS profit_amount
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
    GROUP BY d.d_year, i.i_category
),
union_all AS (
    SELECT * FROM cat_sales
    UNION ALL
    SELECT * FROM store_sales_agg
),
agg AS (
    SELECT
        year,
        category,
        SUM(sales_amount) AS total_sales,
        SUM(profit_amount) AS total_profit,
        SUM(sales_cnt) AS total_transactions
    FROM union_all
    GROUP BY ROLLUP (year, category)
)
SELECT
    year,
    category,
    total_sales,
    total_profit,
    total_transactions,
    SUM(total_sales) OVER (PARTITION BY category ORDER BY year) AS cumulative_sales_by_category
FROM agg
ORDER BY year, category
LIMIT 100
