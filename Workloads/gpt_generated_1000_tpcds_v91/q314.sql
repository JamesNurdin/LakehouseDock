WITH sub_union AS (
    SELECT
        CAST('store' AS varchar) AS source,
        s.s_store_name AS store_name,
        i.i_category AS category,
        d.d_year AS year,
        d.d_month_seq AS month_seq,
        SUM(ss.ss_net_paid) AS sales_amount,
        SUM(ss.ss_quantity) AS total_quantity,
        COUNT(DISTINCT ss.ss_customer_sk) AS distinct_customers
    FROM store_sales ss
    TABLESAMPLE BERNOULLI (5)
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE d.d_year = 2001
      AND t.t_hour BETWEEN 8 AND 20
    GROUP BY s.s_store_name, i.i_category, d.d_year, d.d_month_seq

    UNION ALL

    SELECT
        CAST('catalog' AS varchar) AS source,
        CAST(NULL AS varchar) AS store_name,
        i.i_category AS category,
        d.d_year AS year,
        d.d_month_seq AS month_seq,
        SUM(cs.cs_net_paid) AS sales_amount,
        SUM(cs.cs_quantity) AS total_quantity,
        COUNT(DISTINCT cs.cs_bill_customer_sk) AS distinct_customers
    FROM catalog_sales cs
    TABLESAMPLE BERNOULLI (5)
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    WHERE d.d_year = 2001
      AND t.t_hour BETWEEN 8 AND 20
    GROUP BY i.i_category, d.d_year, d.d_month_seq
),
aggregated AS (
    SELECT
        source,
        store_name,
        category,
        year,
        month_seq,
        SUM(sales_amount) AS total_sales_amount,
        SUM(total_quantity) AS total_quantity,
        SUM(distinct_customers) AS total_distinct_customers
    FROM sub_union
    GROUP BY GROUPING SETS (
        (source, store_name, category, year, month_seq),
        (source, store_name, category, year),
        (source, store_name, category),
        (source, store_name),
        (source, category, year, month_seq),
        (source, category, year),
        (source, category),
        (source)
    )
)
SELECT
    source,
    store_name,
    category,
    year,
    month_seq,
    total_sales_amount,
    total_quantity,
    total_distinct_customers,
    ROW_NUMBER() OVER (PARTITION BY source ORDER BY total_sales_amount DESC) AS sales_rank
FROM aggregated
WHERE total_sales_amount > 0
ORDER BY total_sales_amount DESC
LIMIT 100
