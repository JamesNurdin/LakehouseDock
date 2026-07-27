WITH distinct_sales AS (
    SELECT DISTINCT
        ss.ss_ticket_number,
        ss.ss_store_sk,
        ss.ss_sold_date_sk,
        ss.ss_net_profit
    FROM store_sales ss
),
sales_agg AS (
    SELECT
        s.s_store_name AS store_name,
        d.d_date AS activity_date,
        SUM(ds.ss_net_profit) AS amount,
        CASE WHEN SUM(ds.ss_net_profit) > 0 THEN 'Profit' ELSE 'Loss' END AS flag
    FROM distinct_sales ds
    JOIN store s ON ds.ss_store_sk = s.s_store_sk
    JOIN date_dim d ON ds.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2002
    GROUP BY s.s_store_name, d.d_date
),
returns_agg AS (
    SELECT
        s.s_store_name AS store_name,
        d.d_date AS activity_date,
        -SUM(sr.sr_net_loss) AS amount,
        CASE WHEN SUM(sr.sr_net_loss) > 0 THEN 'Return_Loss' ELSE 'Return_Gain' END AS flag
    FROM store_returns sr
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2002
    GROUP BY s.s_store_name, d.d_date
)
SELECT *
FROM (
    SELECT store_name, activity_date, amount, flag FROM sales_agg
    UNION
    SELECT store_name, activity_date, amount, flag FROM returns_agg
) combined
ORDER BY store_name, activity_date
