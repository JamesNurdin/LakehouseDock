WITH
store_dates AS (
    SELECT
        s.s_store_sk,
        s.s_store_name,
        d.d_date AS closed_date
    FROM store s
    JOIN date_dim d ON s.s_closed_date_sk = d.d_date_sk
    WHERE d.d_year = 2000
),
website_dates AS (
    SELECT
        w.web_site_sk,
        w.web_name,
        d.d_date AS open_date
    FROM web_site w
    JOIN date_dim d ON w.web_open_date_sk = d.d_date_sk
    WHERE d.d_year = 2000
),
full_join AS (
    SELECT
        s.s_store_sk AS entity_id,
        s.s_store_name,
        w.web_site_sk,
        w.web_name,
        s.closed_date,
        w.open_date
    FROM store_dates s
    FULL OUTER JOIN website_dates w
        ON s.closed_date = w.open_date
),
high_return_orders AS (
    SELECT cr.cr_order_number
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2000
      AND cr.cr_return_amount > 5000
),
large_quantity_orders AS (
    SELECT cr.cr_order_number
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2000
      AND cr.cr_return_quantity > 10
),
intersect_orders AS (
    SELECT cr_order_number
    FROM high_return_orders
    INTERSECT
    SELECT cr_order_number
    FROM large_quantity_orders
),
except_orders AS (
    SELECT cr_order_number
    FROM high_return_orders
    EXCEPT
    SELECT cr_order_number
    FROM large_quantity_orders
)

SELECT
    'full' AS src,
    f.entity_id,
    f.s_store_name,
    f.web_site_sk,
    f.web_name,
    f.closed_date,
    f.open_date,
    CAST(NULL AS integer) AS order_number
FROM full_join f

UNION ALL

SELECT
    'intersect' AS src,
    CAST(NULL AS integer) AS entity_id,
    CAST(NULL AS varchar) AS s_store_name,
    CAST(NULL AS integer) AS web_site_sk,
    CAST(NULL AS varchar) AS web_name,
    CAST(NULL AS date) AS closed_date,
    CAST(NULL AS date) AS open_date,
    io.cr_order_number AS order_number
FROM intersect_orders io

UNION ALL

SELECT
    'except' AS src,
    CAST(NULL AS integer) AS entity_id,
    CAST(NULL AS varchar) AS s_store_name,
    CAST(NULL AS integer) AS web_site_sk,
    CAST(NULL AS varchar) AS web_name,
    CAST(NULL AS date) AS closed_date,
    CAST(NULL AS date) AS open_date,
    eo.cr_order_number AS order_number
FROM except_orders eo

ORDER BY src, order_number
LIMIT 100
