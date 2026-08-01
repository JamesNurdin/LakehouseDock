SELECT
    year,
    month,
    store_name,
    category,
    sales_type,
    total_sales,
    total_quantity,
    SUM(total_sales) OVER (
        PARTITION BY store_name
        ORDER BY year, month
        ROWS UNBOUNDED PRECEDING
    ) AS cumulative_sales
FROM (
    SELECT
        d.d_year AS year,
        d.d_moy AS month,
        s.s_store_name AS store_name,
        i.i_category AS category,
        SUM(ss.ss_net_paid) AS total_sales,
        SUM(ss.ss_quantity) AS total_quantity,
        'Promotional' AS sales_type
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE p.p_discount_active = 'Y'
      AND d.d_year = 2002
    GROUP BY
        d.d_year,
        d.d_moy,
        s.s_store_name,
        i.i_category

    UNION ALL

    SELECT
        d.d_year AS year,
        d.d_moy AS month,
        s.s_store_name AS store_name,
        i.i_category AS category,
        SUM(ss.ss_net_paid) AS total_sales,
        SUM(ss.ss_quantity) AS total_quantity,
        'Regular' AS sales_type
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE (p.p_discount_active <> 'Y' OR p.p_discount_active IS NULL)
      AND d.d_year = 2002
    GROUP BY
        d.d_year,
        d.d_moy,
        s.s_store_name,
        i.i_category
) AS combined
ORDER BY cumulative_sales DESC
LIMIT 100
