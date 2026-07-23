WITH sub_a AS (
    SELECT
        s.s_store_id,
        d.d_date_id,
        SUM(i.inv_quantity_on_hand) AS total_quantity,
        COUNT(DISTINCT c.c_customer_sk) AS distinct_customers
    FROM store s
    JOIN date_dim d ON s.s_closed_date_sk = d.d_date_sk
    JOIN inventory i ON i.inv_date_sk = d.d_date_sk
    JOIN web_page wp ON wp.wp_creation_date_sk = d.d_date_sk
    JOIN customer c ON wp.wp_customer_sk = c.c_customer_sk
    WHERE d.d_fy_week_seq = 12
      AND wp.wp_image_count >= 5
    GROUP BY s.s_store_id, d.d_date_id
),
sub_b AS (
    SELECT
        s.s_store_id,
        d.d_date_id,
        SUM(i.inv_quantity_on_hand) AS total_quantity,
        COUNT(DISTINCT c.c_customer_sk) AS distinct_customers
    FROM store s
    JOIN date_dim d ON s.s_closed_date_sk = d.d_date_sk
    JOIN inventory i ON i.inv_date_sk = d.d_date_sk
    JOIN web_page wp ON wp.wp_creation_date_sk = d.d_date_sk
    JOIN customer c ON wp.wp_customer_sk = c.c_customer_sk
    WHERE d.d_fy_week_seq = 3
      AND wp.wp_image_count <= 4
    GROUP BY s.s_store_id, d.d_date_id
),
combined AS (
    SELECT * FROM sub_a
    UNION ALL
    SELECT * FROM sub_b
)
SELECT
    s_store_id,
    d_date_id,
    total_quantity,
    distinct_customers,
    ROW_NUMBER() OVER (PARTITION BY s_store_id ORDER BY total_quantity DESC) AS store_rank
FROM combined
ORDER BY total_quantity DESC
LIMIT 100
