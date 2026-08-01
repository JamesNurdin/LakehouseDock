WITH sampled_store_sales AS (
    SELECT *
    FROM store_sales
    TABLESAMPLE BERNOULLI (10)
),
sampled_web_sales AS (
    SELECT *
    FROM web_sales
    TABLESAMPLE BERNOULLI (10)
)
(
    SELECT
        d.d_date AS sale_date,
        s.s_store_id AS entity_id,
        ss.ss_ext_sales_price AS amount,
        LAG(ss.ss_ext_sales_price) OVER (PARTITION BY s.s_store_id ORDER BY d.d_date) AS prior_amount
    FROM store s
    FULL OUTER JOIN sampled_store_sales ss
        ON s.s_store_sk = ss.ss_store_sk
    LEFT JOIN date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001 OR d.d_year IS NULL
)
INTERSECT
(
    SELECT
        d.d_date AS sale_date,
        CAST(ws.ws_web_page_sk AS VARCHAR) AS entity_id,
        ws.ws_ext_sales_price AS amount,
        LAG(ws.ws_ext_sales_price) OVER (PARTITION BY ws.ws_web_page_sk ORDER BY d.d_date) AS prior_amount
    FROM sampled_web_sales ws
    JOIN date_dim d
        ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
)
ORDER BY sale_date DESC, entity_id
LIMIT 100
