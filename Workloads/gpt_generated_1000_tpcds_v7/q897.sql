/*
Goal: Rank customers by their combined store and web net paid amount within each hour of the day, after filtering on birth year, first ship‑to date, web net paid (including shipping), minute of the sale time, and ship mode carrier.
The query joins all five tables using only the permitted join keys, applies four filter predicates, aggregates sales per customer per hour, and uses ROW_NUMBER as a window function to produce a ranking.
*/
WITH agg_sales AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        t.t_hour,
        SUM(ss.ss_net_paid) AS store_net_paid,
        SUM(ws.ws_net_paid) AS web_net_paid,
        SUM(ss.ss_net_paid) + SUM(ws.ws_net_paid) AS total_net_paid
    FROM store_sales ss
    JOIN customer c
        ON ss.ss_customer_sk = c.c_customer_sk
    JOIN time_dim t
        ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN web_sales ws
        ON ws.ws_sold_time_sk = t.t_time_sk
        AND ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN ship_mode sm
        ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE c.c_birth_year BETWEEN 1950 AND 2000
      AND c.c_first_shipto_date_sk > 2450000
      AND ws.ws_net_paid_inc_ship > 500
      AND t.t_minute IN (0, 5, 10, 15)
      AND sm.sm_carrier = 'UPS'
    GROUP BY
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        t.t_hour
)
SELECT
    c_customer_sk,
    c_first_name,
    c_last_name,
    t_hour,
    total_net_paid,
    ROW_NUMBER() OVER (PARTITION BY t_hour ORDER BY total_net_paid DESC) AS hourly_rank
FROM agg_sales
ORDER BY t_hour, hourly_rank
