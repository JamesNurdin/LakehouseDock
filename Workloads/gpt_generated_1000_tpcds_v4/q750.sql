WITH year_2001 AS (
    SELECT d_date_sk, d_date
    FROM date_dim
    WHERE d_year = 2001
)

SELECT
    yd.d_date AS activity_date,
    s.s_store_name AS entity_name,
    SUM(i.inv_quantity_on_hand) AS total_quantity,
    'store' AS entity_type
FROM inventory i
JOIN year_2001 yd ON i.inv_date_sk = yd.d_date_sk
JOIN store s ON s.s_closed_date_sk = yd.d_date_sk
GROUP BY yd.d_date, s.s_store_name

UNION ALL

SELECT
    yd.d_date AS activity_date,
    w.web_name AS entity_name,
    SUM(i.inv_quantity_on_hand) AS total_quantity,
    'website' AS entity_type
FROM inventory i
JOIN year_2001 yd ON i.inv_date_sk = yd.d_date_sk
JOIN web_site w ON w.web_open_date_sk = yd.d_date_sk
GROUP BY yd.d_date, w.web_name

ORDER BY activity_date DESC, entity_type, entity_name
LIMIT 100
