WITH daily_store_sales AS (
    SELECT
        d_sold.d_date AS d_date,
        s.s_store_id,
        s.s_store_name,
        s.s_city,
        s.s_state,
        ws.web_name,
        ws.web_city,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_ext_discount_amt) AS total_discount,
        SUM(ss.ss_net_profit) AS total_profit,
        COUNT(DISTINCT ss.ss_ticket_number) AS distinct_tickets,
        AVG(ss.ss_quantity) AS avg_quantity,
        MIN(t.t_hour) AS earliest_hour,
        MAX(t.t_hour) AS latest_hour
    FROM store_sales ss
    JOIN date_dim d_sold ON ss.ss_sold_date_sk = d_sold.d_date_sk
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN date_dim d_closed ON s.s_closed_date_sk = d_closed.d_date_sk
    JOIN web_site ws ON ws.web_open_date_sk = d_sold.d_date_sk
    JOIN date_dim d_web_close ON ws.web_close_date_sk = d_web_close.d_date_sk
    WHERE d_sold.d_year = 2023
      AND s.s_state = 'TX'
      AND ws.web_country = 'US'
    GROUP BY
        d_sold.d_date,
        s.s_store_id,
        s.s_store_name,
        s.s_city,
        s.s_state,
        ws.web_name,
        ws.web_city
)
SELECT
    d_date,
    s_store_id,
    s_store_name,
    s_city,
    s_state,
    web_name,
    web_city,
    total_sales,
    total_discount,
    total_profit,
    distinct_tickets,
    avg_quantity,
    earliest_hour,
    latest_hour,
    ROW_NUMBER() OVER (PARTITION BY d_date ORDER BY total_sales DESC) AS sales_rank
FROM daily_store_sales
ORDER BY d_date DESC, sales_rank
LIMIT 200
