WITH distinct_store_locations AS (
    SELECT DISTINCT
        s.s_store_sk,
        CONCAT(s.s_city, ', ', s.s_state) AS store_location
    FROM store s
    WHERE s.s_city LIKE 'W%'
      AND REGEXP_LIKE(s.s_store_name, '^Store [A-Z]+$')
)
SELECT
    dsl.store_location,
    i.i_category,
    REGEXP_EXTRACT(i.i_item_desc, '(\\d+)', 1) AS item_number,
    SUM(ss.ss_quantity) AS total_quantity,
    SUM(ss.ss_net_profit) AS total_net_profit,
    COUNT(DISTINCT t.t_time_sk) AS time_slots
FROM distinct_store_locations dsl
JOIN store_sales ss ON ss.ss_store_sk = dsl.s_store_sk
JOIN item i ON ss.ss_item_sk = i.i_item_sk
JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
WHERE t.t_shift = 'PM'
  AND REGEXP_LIKE(i.i_item_desc, '\\d')
GROUP BY dsl.store_location, i.i_category, REGEXP_EXTRACT(i.i_item_desc, '(\\d+)', 1)
ORDER BY total_net_profit DESC
LIMIT 100
