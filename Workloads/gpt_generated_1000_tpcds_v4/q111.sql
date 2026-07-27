WITH filtered_sales AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_store_sk,
        ss.ss_item_sk,
        ss.ss_net_profit,
        ss.ss_ticket_number
    FROM store_sales ss
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    JOIN item i
        ON ss.ss_item_sk = i.i_item_sk
    WHERE regexp_like(i.i_item_desc, '^[A-Z]{2}[0-9]{3}')
      AND s.s_store_name LIKE '%Market%'
),
joined_dates AS (
    SELECT
        fs.*, d.d_year
    FROM filtered_sales fs
    JOIN date_dim d
        ON fs.ss_sold_date_sk = d.d_date_sk
)
SELECT
    s.s_store_id,
    s.s_store_name,
    s.s_city || ', ' || s.s_state AS location,
    substring(s.s_store_name FROM 1 FOR 5) AS store_prefix,
    sum(jd.ss_net_profit) AS total_net_profit,
    count(DISTINCT jd.ss_ticket_number) AS distinct_tickets
FROM joined_dates jd
JOIN store s
    ON jd.ss_store_sk = s.s_store_sk
WHERE jd.d_year = 2001
GROUP BY
    s.s_store_id,
    s.s_store_name,
    s.s_city,
    s.s_state
ORDER BY total_net_profit DESC
LIMIT 10
