/*
 * Goal: Compare total net profit by fiscal month for web sales using the sale date versus the ship date,
 * separating weekend and weekday activity and distinguishing between warehouse (NY) and store closures (CA).
 * The query uses a UNION ALL to combine two aggregated result sets.
 */
WITH sold_monthly AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        'sold' AS period_type,
        SUM(ws.ws_net_profit) AS total_profit
    FROM
        tpcds.web_sales ws
        JOIN tpcds.date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
        JOIN tpcds.warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    WHERE
        d.d_weekend = 'N'                         -- weekdays only
        AND w.w_city = 'New York'                 -- focus on NY warehouse
    GROUP BY
        d.d_year,
        d.d_month_seq
),
shipped_monthly AS (
    SELECT
        d2.d_year,
        d2.d_month_seq,
        'shipped' AS period_type,
        SUM(ws2.ws_net_profit) AS total_profit
    FROM
        tpcds.web_sales ws2
        JOIN tpcds.date_dim d2 ON ws2.ws_ship_date_sk = d2.d_date_sk
        JOIN tpcds.store s ON s.s_closed_date_sk = d2.d_date_sk
    WHERE
        d2.d_weekend = 'Y'                        -- weekends only
        AND s.s_state = 'CA'                      -- CA stores closed on that date
    GROUP BY
        d2.d_year,
        d2.d_month_seq
)
SELECT * FROM sold_monthly
UNION ALL
SELECT * FROM shipped_monthly
ORDER BY d_year, d_month_seq, period_type
