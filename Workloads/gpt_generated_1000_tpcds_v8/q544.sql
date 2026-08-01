WITH sampled_store AS (
   SELECT *
   FROM store TABLESAMPLE BERNOULLI (10)
   WHERE s_market_id IN (
       SELECT DISTINCT s_market_id
       FROM store
       WHERE s_state = 'CA'
   )
),
eligible_keys AS (
   SELECT s_store_sk FROM sampled_store WHERE s_number_employees > 30
   INTERSECT
   SELECT d_date_sk FROM date_dim WHERE d_weekend = 'Y'
)
SELECT
   s.s_state,
   s.s_city,
   d.d_year,
   d.d_month_seq,
   COUNT(DISTINCT s.s_store_id) AS distinct_store_count,
   SUM(
       CASE
           WHEN s.s_tax_percentage > 5.00 THEN s.s_floor_space * s.s_tax_percentage
           ELSE s.s_floor_space
       END
   ) AS tax_adjusted_floor_space,
   ROW_NUMBER() OVER (PARTITION BY s.s_state ORDER BY d.d_year DESC) AS rn_state_year,
   GROUPING(s.s_state) AS grp_state,
   GROUPING(s.s_city) AS grp_city
FROM
   sampled_store AS s
   FULL OUTER JOIN date_dim AS d
     ON s.s_closed_date_sk = d.d_date_sk
WHERE
   s.s_zip IN ('15709','39231','56871')
   AND s.s_market_id IN (1,2,4,7,8)
   AND s.s_city = 'New York'
   AND d.d_year = 2001
   AND d.d_month_seq BETWEEN 1 AND 12
   AND d.d_current_day = 'N'
   AND EXISTS (
       SELECT 1
       FROM store s2
       WHERE s2.s_store_sk = s.s_store_sk
         AND s2.s_manager IS NOT NULL
   )
   AND NOT EXISTS (
       SELECT 1
       FROM date_dim dd2
       WHERE dd2.d_date_sk = s.s_closed_date_sk
         AND dd2.d_holiday = 'Y'
   )
   AND s.s_store_sk IN (SELECT s_store_sk FROM eligible_keys)
GROUP BY
   ROLLUP (s.s_state, s.s_city, d.d_year, d.d_month_seq)
ORDER BY
   s.s_state NULLS LAST,
   s.s_city NULLS LAST,
   d.d_year DESC,
   d.d_month_seq
OFFSET 0
LIMIT 100
