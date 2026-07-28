WITH avg_price_cte AS (
    SELECT avg(i_current_price) AS avg_price
    FROM item
)
SELECT
    s.s_store_id,
    s.s_store_name,
    s.s_city,
    concat(s.s_store_name, ' - ', s.s_city) AS store_full_name,
    regexp_extract(s.s_city, '^([A-Za-z]+)', 1) AS city_prefix,
    sum(ss.ss_net_profit) AS total_net_profit,
    sum(ss.ss_quantity) AS total_quantity,
    count(DISTINCT ss.ss_ticket_number) AS distinct_tickets
FROM
    store_sales ss
JOIN item i
    ON ss.ss_item_sk = i.i_item_sk
JOIN time_dim t
    ON ss.ss_sold_time_sk = t.t_time_sk
JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
JOIN customer_address ca
    ON ss.ss_addr_sk = ca.ca_address_sk
WHERE
    regexp_like(i.i_color, '^s')
    AND i.i_current_price > (SELECT avg_price FROM avg_price_cte)
    AND t.t_shift = 'first'
    AND s.s_city LIKE '%York%'
    AND ca.ca_city LIKE '%Spring%'
    AND EXISTS (
        SELECT 1
        FROM web_sales ws
        WHERE ws.ws_item_sk = ss.ss_item_sk
          AND ws.ws_sold_date_sk = ss.ss_sold_date_sk
    )
GROUP BY
    s.s_store_id,
    s.s_store_name,
    s.s_city,
    concat(s.s_store_name, ' - ', s.s_city),
    regexp_extract(s.s_city, '^([A-Za-z]+)', 1)
ORDER BY
    total_net_profit DESC
LIMIT 100
