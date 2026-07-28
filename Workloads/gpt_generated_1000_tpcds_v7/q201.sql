/*
Goal: Compute average sales and profit per store for California stores located in selected counties, 
filtering to only high‑cost items, then summarize by state and county and keep only counties where the 
average profit per store exceeds a threshold.
*/
WITH store_agg AS (
    SELECT
        s.s_store_id,
        s.s_state        AS state,
        s.s_county       AS county,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_net_profit)       AS total_profit,
        COUNT(DISTINCT ss.ss_ticket_number) AS ticket_cnt
    FROM
        store AS s
        JOIN store_sales AS ss
            ON ss.ss_store_sk = s.s_store_sk
    WHERE
        s.s_state = 'CA'
        AND s.s_county IN ('Fairfield County', 'Levy County')
        AND ss.ss_wholesale_cost > 30
    GROUP BY
        s.s_store_id,
        s.s_state,
        s.s_county
)
SELECT
    state,
    county,
    AVG(total_sales)  AS avg_sales_per_store,
    AVG(total_profit) AS avg_profit_per_store,
    SUM(ticket_cnt)   AS total_tickets
FROM
    store_agg
WHERE
    total_sales > 10000
GROUP BY
    state,
    county
HAVING
    AVG(total_profit) > 500
