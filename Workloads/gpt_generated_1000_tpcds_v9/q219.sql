WITH sales_fy1910 AS (
    SELECT
        s.s_store_id AS store_id,
        s.s_store_name AS store_name,
        d.d_fy_year AS fy_year,
        SUM(ss.ss_net_paid) AS total_net_paid,
        AVG(ss.ss_ext_discount_amt) AS avg_discount,
        MAX(p.p_cost) AS max_promo_cost
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE d.d_fy_year = 1910
      AND ss.ss_promo_sk IN (SELECT p2.p_promo_sk FROM promotion p2 WHERE p2.p_cost > 100)
    GROUP BY s.s_store_id, s.s_store_name, d.d_fy_year
),
sales_fy1905 AS (
    SELECT
        s.s_store_id AS store_id,
        s.s_store_name AS store_name,
        d.d_fy_year AS fy_year,
        SUM(ss.ss_net_paid) AS total_net_paid,
        AVG(ss.ss_ext_discount_amt) AS avg_discount,
        MAX(p.p_cost) AS max_promo_cost
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE d.d_fy_year = 1905
      AND s.s_number_employees > 200
    GROUP BY s.s_store_id, s.s_store_name, d.d_fy_year
)
SELECT
    store_id,
    store_name,
    fy_year,
    total_net_paid,
    avg_discount,
    max_promo_cost
FROM sales_fy1910
UNION ALL
SELECT
    store_id,
    store_name,
    fy_year,
    total_net_paid,
    avg_discount,
    max_promo_cost
FROM sales_fy1905
ORDER BY fy_year DESC, total_net_paid DESC
LIMIT 100
