WITH sales AS (
   SELECT
       s.s_store_id,
       d.d_year,
       SUM(ss.ss_ext_sales_price) AS total_sales,
       COUNT(*) AS sales_cnt,
       ROW_NUMBER() OVER (PARTITION BY d.d_year ORDER BY SUM(ss.ss_ext_sales_price) DESC) AS sales_rank
   FROM store_sales ss
   JOIN store s ON ss.ss_store_sk = s.s_store_sk
   JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
   WHERE regexp_like(s.s_store_name, '^A.*')
     AND s.s_state LIKE 'CA'
   GROUP BY s.s_store_id, d.d_year
), returns AS (
   SELECT
       s.s_store_id,
       d.d_year,
       SUM(cr.cr_return_amount) AS total_returns,
       COUNT(*) AS return_cnt,
       ROW_NUMBER() OVER (PARTITION BY d.d_year ORDER BY SUM(cr.cr_return_amount) DESC) AS return_rank
   FROM catalog_returns cr
   JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
   JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
   JOIN store s ON s.s_closed_date_sk = d.d_date_sk
   WHERE sm.sm_type = 'AIR'
     AND cr.cr_return_amount > 0
   GROUP BY s.s_store_id, d.d_year
), promo_distinct AS (
   SELECT DISTINCT p.p_promo_name
   FROM promotion p
   WHERE regexp_like(p.p_promo_name, 'Discount')
     AND p.p_promo_name LIKE '%2022%'
)
SELECT
    combined.store_id,
    combined.year,
    combined.metric,
    combined.amount,
    combined.rank,
    combined.avg_amount
FROM (
    SELECT
        s.s_store_id AS store_id,
        s.d_year AS year,
        'sales' AS metric,
        s.total_sales AS amount,
        s.sales_rank AS rank,
        (SELECT AVG(total_sales) FROM sales) AS avg_amount
    FROM sales s

    UNION ALL

    SELECT
        r.s_store_id AS store_id,
        r.d_year AS year,
        'returns' AS metric,
        r.total_returns AS amount,
        r.return_rank AS rank,
        (SELECT AVG(total_returns) FROM returns) AS avg_amount
    FROM returns r
) combined
WHERE EXISTS (
    SELECT 1
    FROM promo_distinct pd
    WHERE pd.p_promo_name = (
        SELECT p.p_promo_name
        FROM promotion p
        WHERE p.p_promo_id = 'PROMO123'
        LIMIT 1
    )
)
ORDER BY combined.year DESC, combined.amount DESC
LIMIT 100
