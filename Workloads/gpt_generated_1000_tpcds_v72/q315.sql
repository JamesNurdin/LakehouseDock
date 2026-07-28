WITH sales_joined AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_sold_time_sk,
        cs.cs_ship_date_sk,
        cs.cs_ship_mode_sk,
        cs.cs_quantity,
        cs.cs_net_paid,
        cs.cs_net_profit,
        d_sold.d_year,
        d_sold.d_month_seq,
        d_sold.d_date,
        t.t_meal_time,
        sm.sm_carrier,
        sm.sm_code,
        ws.web_name,
        wp.wp_type
    FROM catalog_sales cs
    JOIN date_dim d_sold
        ON cs.cs_sold_date_sk = d_sold.d_date_sk
    JOIN time_dim t
        ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN web_site ws
        ON ws.web_open_date_sk = d_sold.d_date_sk
    JOIN web_page wp
        ON wp.wp_creation_date_sk = d_sold.d_date_sk
    WHERE
        t.t_meal_time IN ('dinner', 'lunch')
        AND sm.sm_carrier IN ('FEDEX', 'AIRBORNE')
        AND d_sold.d_year BETWEEN 2001 AND 2002
        AND ws.web_name LIKE 'Site%'
        AND wp.wp_type = 'home'
        AND cs.cs_quantity > 1
),
sales_agg AS (
    SELECT
        d_year,
        d_month_seq,
        sm_carrier,
        t_meal_time,
        web_name,
        wp_type,
        SUM(cs_net_paid) AS total_net_paid,
        SUM(cs_quantity) AS total_quantity,
        AVG(cs_net_profit) AS avg_net_profit
    FROM sales_joined
    GROUP BY
        d_year,
        d_month_seq,
        sm_carrier,
        t_meal_time,
        web_name,
        wp_type
)
SELECT
    d_year,
    d_month_seq,
    sm_carrier,
    t_meal_time,
    web_name,
    wp_type,
    total_net_paid,
    total_quantity,
    avg_net_profit,
    RANK() OVER (PARTITION BY d_year ORDER BY total_net_paid DESC) AS net_paid_rank,
    SUM(total_quantity) OVER (PARTITION BY d_year ORDER BY d_month_seq
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_quantity
FROM sales_agg
ORDER BY d_year DESC, net_paid_rank
LIMIT 100
