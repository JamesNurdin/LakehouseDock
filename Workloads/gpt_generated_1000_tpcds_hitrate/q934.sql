WITH sales_agg AS (
    SELECT
        s.s_store_id,
        d.d_year,
        SUM(ss.ss_net_profit) AS total_profit,
        COUNT(*) AS sales_cnt,
        CASE
            WHEN regexp_like(s.s_city, '^A.*') THEN 'CityStartsA'
            ELSE 'OtherCity'
        END AS city_group,
        regexp_extract(s.s_store_name, '(\\w+) Store', 1) AS store_name_token
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE s.s_city LIKE '%York%'
      AND regexp_like(s.s_state, '[A-Z]{2}')
    GROUP BY s.s_store_id,
        d.d_year,
        CASE
            WHEN regexp_like(s.s_city, '^A.*') THEN 'CityStartsA'
            ELSE 'OtherCity'
        END,
        regexp_extract(s.s_store_name, '(\\w+) Store', 1)
    HAVING SUM(ss.ss_net_profit) > 1000
),
store_ids_high_profit AS (
    SELECT s_store_id
    FROM sales_agg
    WHERE total_profit >= 5000
),
store_ids_all AS (
    SELECT s_store_id
    FROM sales_agg
)
SELECT
    sa.s_store_id,
    sa.d_year,
    sa.total_profit,
    sa.sales_cnt,
    sa.city_group,
    sa.store_name_token
FROM sales_agg sa
WHERE sa.s_store_id IN (
    SELECT s_store_id FROM store_ids_all
    EXCEPT
    SELECT s_store_id FROM store_ids_high_profit
)
ORDER BY sa.total_profit DESC
OFFSET 0
LIMIT 100
