WITH sales_data AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_sold_time_sk,
        ss.ss_store_sk,
        ss.ss_customer_sk,
        ss.ss_item_sk,
        ss.ss_ticket_number,
        ss.ss_net_profit,
        ss.ss_quantity,
        d.d_year,
        d.d_quarter_seq,
        t.t_hour,
        c.c_first_name,
        c.c_last_name,
        c.c_email_address,
        s.s_store_name,
        s.s_city
    FROM store_sales ss
    JOIN date_dim d   ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN time_dim t   ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN customer c   ON ss.ss_customer_sk = c.c_customer_sk
    JOIN store s      ON ss.ss_store_sk = s.s_store_sk
    WHERE d.d_year = 2001
      AND regexp_like(c.c_email_address, '[A-Za-z0-9._%+-]+@example\\.com$')
      AND s.s_store_name LIKE '%Store%'
),
expanded_sales AS (
    SELECT
        sd.*, 
        u.email_part AS domain
    FROM sales_data sd
    CROSS JOIN UNNEST(split(sd.c_email_address, '@')) WITH ORDINALITY AS u (email_part, idx)
    WHERE idx = 2  -- keep only the domain part of the e‑mail address
)
SELECT
    es.s_store_name,
    es.s_city,
    es.d_quarter_seq,
    SUM(es.ss_net_profit)                AS total_net_profit,
    COUNT(DISTINCT es.ss_customer_sk)    AS unique_customers,
    AVG(es.ss_quantity)                 AS avg_quantity,
    MAX(CONCAT(es.c_first_name, ' ', es.c_last_name)) AS example_full_name,
    es.domain
FROM expanded_sales es
WHERE NOT EXISTS (
    SELECT 1
    FROM store_returns sr
    JOIN date_dim dr ON sr.sr_returned_date_sk = dr.d_date_sk
    WHERE sr.sr_store_sk = es.ss_store_sk
      AND dr.d_year = 2001
      AND sr.sr_item_sk = es.ss_item_sk
      AND sr.sr_ticket_number = es.ss_ticket_number
)
GROUP BY
    es.s_store_name,
    es.s_city,
    es.d_quarter_seq,
    es.domain
ORDER BY total_net_profit DESC
LIMIT 100
