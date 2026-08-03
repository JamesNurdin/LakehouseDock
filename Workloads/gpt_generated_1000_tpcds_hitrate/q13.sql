WITH cs_data AS (
    SELECT
        cs.cs_order_number AS order_number,
        d.d_year,
        cp.cp_department AS category,
        cs.cs_net_paid AS net_paid,
        CASE WHEN cs.cs_quantity > 5 THEN 'Bulk' ELSE 'Regular' END AS order_type
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    WHERE d.d_year = 2001
      AND cs.cs_net_paid > 100
),
ws_data AS (
    SELECT
        ws.ws_order_number AS order_number,
        d.d_year,
        wp.wp_type AS category,
        ws.ws_net_paid AS net_paid,
        CASE WHEN ws.ws_quantity > 5 THEN 'Bulk' ELSE 'Regular' END AS order_type
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE d.d_year = 2001
      AND ws.ws_net_paid > 100
)
SELECT *
FROM (
    SELECT
        cs.order_number,
        cs.d_year,
        cs.category,
        cs.net_paid,
        cs.order_type
    FROM cs_data cs
    WHERE cs.order_number NOT IN (
        SELECT wd.order_number
        FROM ws_data wd
        WHERE wd.category = 'M'
    )
    UNION ALL
    SELECT
        wd.order_number,
        wd.d_year,
        wd.category,
        wd.net_paid,
        wd.order_type
    FROM ws_data wd
) combined
ORDER BY combined.d_year DESC, combined.net_paid DESC
LIMIT 100
