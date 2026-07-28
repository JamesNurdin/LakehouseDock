WITH promo_sales AS (
    SELECT
        p.p_promo_id AS p_id,
        p.p_promo_name AS p_name,
        p.p_purpose AS purpose,
        d.d_year AS year,
        SUM(cs.cs_net_profit) AS total_profit,
        COUNT(DISTINCT cs.cs_order_number) AS distinct_orders
    FROM
        promotion p
        JOIN catalog_sales cs ON cs.cs_promo_sk = p.p_promo_sk
        JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE
        regexp_like(p.p_promo_name, '[A-Z]{3}[0-9]{2}')
        AND p.p_purpose LIKE '%Unknown%'
        AND d.d_year BETWEEN 1999 AND 2001
    GROUP BY
        p.p_promo_id,
        p.p_promo_name,
        p.p_purpose,
        d.d_year
),
filtered AS (
    SELECT
        p_id,
        p_name,
        purpose,
        year,
        total_profit,
        distinct_orders,
        regexp_extract(p_name, '([A-Z]{3}[0-9]{2})', 1) AS promo_code,
        CONCAT(p_name, ' - ', CAST(year AS VARCHAR)) AS name_year
    FROM promo_sales
    WHERE regexp_like(purpose, '^Unknown$')
)
SELECT DISTINCT
    p_id,
    promo_code,
    name_year,
    total_profit,
    distinct_orders
FROM filtered
ORDER BY total_profit DESC
LIMIT 100
