WITH cust_page_agg AS (
    SELECT
        c.c_customer_sk,
        c.c_customer_id,
        d_cust.d_year AS first_sales_year,
        SUM(i.inv_quantity_on_hand) AS total_quantity,
        COUNT(DISTINCT w.wp_web_page_sk) AS distinct_pages,
        AVG(w.wp_image_count) AS avg_image_count,
        SUM(w.wp_max_ad_count) AS total_max_ad
    FROM customer c
    JOIN date_dim d_cust
        ON c.c_first_sales_date_sk = d_cust.d_date_sk
    JOIN web_page w
        ON w.wp_customer_sk = c.c_customer_sk
    JOIN date_dim d_wp
        ON w.wp_creation_date_sk = d_wp.d_date_sk
    JOIN inventory i
        ON i.inv_date_sk = d_wp.d_date_sk
    WHERE
        c.c_preferred_cust_flag = 'Y'
        AND c.c_birth_year BETWEEN 1950 AND 1990
        AND d_cust.d_year = 2002
        AND i.inv_warehouse_sk IN (12, 13, 19)
        AND i.inv_quantity_on_hand > 0
        AND w.wp_autogen_flag = 'N'
        AND w.wp_image_count >= 2
    GROUP BY
        c.c_customer_sk,
        c.c_customer_id,
        d_cust.d_year
)
SELECT DISTINCT
    ca.c_customer_id,
    ca.first_sales_year,
    ca.total_quantity,
    ca.distinct_pages,
    ca.avg_image_count,
    ca.total_max_ad,
    RANK() OVER (ORDER BY ca.total_quantity DESC) AS qty_rank,
    SUM(ca.total_quantity) OVER (PARTITION BY ca.first_sales_year) AS yearly_quantity_total,
    ca.total_quantity / NULLIF(ca.distinct_pages, 0) AS avg_qty_per_page
FROM cust_page_agg ca
WHERE EXISTS (
    SELECT 1
    FROM web_page wp_sub
    WHERE wp_sub.wp_customer_sk = ca.c_customer_sk
      AND wp_sub.wp_max_ad_count > 3
)
ORDER BY ca.total_quantity DESC
LIMIT 100
