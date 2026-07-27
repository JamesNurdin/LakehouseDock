WITH promo_sales AS (
    SELECT
        p.p_promo_sk,
        p.p_promo_name,
        p.p_channel_details,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        COUNT(*) AS txn_cnt,
        MIN(ss.ss_sold_date_sk) AS first_sale_date_sk,
        MAX(ss.ss_sold_date_sk) AS last_sale_date_sk
    FROM store_sales ss
    JOIN promotion p
        ON ss.ss_promo_sk = p.p_promo_sk
    GROUP BY p.p_promo_sk, p.p_promo_name, p.p_channel_details
)
SELECT DISTINCT
    ps.p_promo_name,
    ps.p_channel_details,
    ps.total_sales,
    ps.txn_cnt,
    CONCAT('Promo_', CAST(ps.p_promo_sk AS VARCHAR)) AS promo_key,
    SUBSTRING(ps.p_channel_details, 1, 30) AS channel_snippet
FROM promo_sales ps
JOIN store_sales ss
    ON ss.ss_promo_sk = ps.p_promo_sk
JOIN time_dim t
    ON ss.ss_sold_time_sk = t.t_time_sk
WHERE regexp_like(ps.p_channel_details, '(family|prizes)')
  AND ps.p_promo_name LIKE '%2023%'
  AND t.t_am_pm = 'AM'
  AND EXISTS (
        SELECT 1
        FROM store_sales ss2
        JOIN time_dim t2 ON ss2.ss_sold_time_sk = t2.t_time_sk
        WHERE ss2.ss_promo_sk = ps.p_promo_sk
          AND t2.t_am_pm = 'PM'
        LIMIT 1
    )
ORDER BY ps.total_sales DESC
LIMIT 10
