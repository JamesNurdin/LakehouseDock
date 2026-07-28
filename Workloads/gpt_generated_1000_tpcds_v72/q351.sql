-- Goal: compare store‑level net loss from catalog returns with inventory quantity on hand for the same stores and years, and surface the count of web pages created or accessed in that year that have a high image count.
WITH store_returns AS (
    SELECT
        s.s_store_id,
        d.d_year,
        SUM(cr.cr_net_loss) AS total_net_loss
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN store s ON s.s_closed_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 2000 AND 2001
      AND cr.cr_return_amount > 20.00
    GROUP BY s.s_store_id, d.d_year
)
SELECT
    combined.store_id,
    combined.year,
    combined.metric,
    combined.metric_value,
    combined.high_image_page_cnt
FROM (
    -- Returns net‑loss per store per year
    SELECT
        sr.s_store_id AS store_id,
        sr.d_year AS year,
        'net_loss' AS metric,
        CAST(sr.total_net_loss AS decimal(15,2)) AS metric_value,
        (
            SELECT COUNT(*)
            FROM web_page wp
            JOIN date_dim wd ON wp.wp_creation_date_sk = wd.d_date_sk
            WHERE wd.d_year = sr.d_year
              AND wp.wp_image_count > 3
        ) AS high_image_page_cnt
    FROM store_returns sr

    UNION ALL

    -- Inventory quantity on hand per store per year
    SELECT
        st.s_store_id AS store_id,
        dt.d_year AS year,
        'inventory_qty' AS metric,
        CAST(SUM(i.inv_quantity_on_hand) AS decimal(15,2)) AS metric_value,
        (
            SELECT COUNT(*)
            FROM web_page wp
            JOIN date_dim wd ON wp.wp_access_date_sk = wd.d_date_sk
            WHERE wd.d_year = dt.d_year
              AND wp.wp_image_count > 3
        ) AS high_image_page_cnt
    FROM inventory i
    JOIN date_dim dt ON i.inv_date_sk = dt.d_date_sk
    JOIN store st ON st.s_closed_date_sk = dt.d_date_sk
    WHERE dt.d_year BETWEEN 2000 AND 2001
      AND i.inv_quantity_on_hand > 0
    GROUP BY st.s_store_id, dt.d_year
) AS combined
LIMIT 100
