WITH
sales AS (
    SELECT
        ss.ss_store_sk,
        ss.ss_customer_sk,
        ss.ss_net_paid,
        c.c_first_name,
        c.c_last_name,
        c.c_email_address,
        i.i_category,
        i.i_product_name
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE d.d_year = 2002
),
customer_totals AS (
    SELECT
        ss_store_sk,
        ss_customer_sk,
        SUM(ss_net_paid) AS total_net_paid,
        MAX(c_first_name) AS c_first_name,
        MAX(c_last_name) AS c_last_name,
        MAX(c_email_address) AS c_email_address
    FROM sales
    GROUP BY ss_store_sk, ss_customer_sk
),
top_customers AS (
    SELECT
        ss_store_sk,
        c_first_name,
        c_last_name,
        c_email_address,
        total_net_paid,
        ROW_NUMBER() OVER (PARTITION BY ss_store_sk ORDER BY total_net_paid DESC) AS rn
    FROM customer_totals
),
store_category_sales AS (
    SELECT
        ss_store_sk,
        i_category,
        SUM(ss_net_paid) AS category_net_paid
    FROM sales
    GROUP BY ss_store_sk, i_category
)
SELECT
    s.s_store_id,
    s.s_store_name,
    array_join(
        array_agg(
            CONCAT(
                UPPER(c.c_first_name), ' ', UPPER(c.c_last_name),
                ' (', LOWER(split(c.c_email_address, '@')[2]), ')'
            )
            ORDER BY c.total_net_paid DESC
        ) FILTER (WHERE c.rn <= 5), ', '
    ) AS top_customers,
    cat.top_categories,
    prod.cleaned_product_names
FROM store s
LEFT JOIN top_customers c ON s.s_store_sk = c.ss_store_sk
LEFT JOIN (
    SELECT
        ss_store_sk,
        array_join(array_agg(i_category ORDER BY category_net_paid DESC), ', ') AS top_categories
    FROM (
        SELECT
            ss_store_sk,
            i_category,
            category_net_paid,
            ROW_NUMBER() OVER (PARTITION BY ss_store_sk ORDER BY category_net_paid DESC) AS rn
        FROM store_category_sales
    ) ranked_cat
    WHERE rn <= 3
    GROUP BY ss_store_sk
) cat ON s.s_store_sk = cat.ss_store_sk
LEFT JOIN (
    SELECT
        ss_store_sk,
        array_join(array_agg(DISTINCT regexp_replace(i_product_name, '[^A-Za-z0-9]', '')), ', ') AS cleaned_product_names
    FROM sales
    GROUP BY ss_store_sk
) prod ON s.s_store_sk = prod.ss_store_sk
GROUP BY
    s.s_store_id,
    s.s_store_name,
    cat.top_categories,
    prod.cleaned_product_names
