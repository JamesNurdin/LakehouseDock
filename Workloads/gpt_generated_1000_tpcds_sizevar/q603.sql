WITH sales_store_year AS (
    SELECT DISTINCT s.s_store_id AS store_id, d.d_year
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
      AND ss.ss_quantity > 0
),
returns_store_year AS (
    SELECT DISTINCT s.s_store_id AS store_id, d.d_year
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
      AND sr.sr_return_quantity > 0
),
intersected AS (
    SELECT store_id, d_year
    FROM sales_store_year
    INTERSECT
    SELECT store_id, d_year
    FROM returns_store_year
)
SELECT
    i.store_id,
    i.d_year,
    ROW_NUMBER() OVER (PARTITION BY i.store_id ORDER BY i.d_year) AS year_rank,
    (
        SELECT SUM(ss2.ss_net_paid)
        FROM store_sales ss2
        WHERE ss2.ss_store_sk = s.s_store_sk
    ) AS total_net_paid
FROM intersected i
JOIN store s ON i.store_id = s.s_store_id
ORDER BY total_net_paid DESC
LIMIT 100
