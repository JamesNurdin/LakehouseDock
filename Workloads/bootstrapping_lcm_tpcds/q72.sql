WITH inv_agg AS (
    SELECT inv_date_sk, SUM(inv_quantity_on_hand) AS total_inventory_on_hand
    FROM inventory
    GROUP BY inv_date_sk
),
sales_agg AS (
    SELECT
        s.s_store_id AS store_id,
        s.s_store_name AS store_name,
        s.s_city AS city,
        s.s_state AS state,
        dd_sales.d_date AS sale_date,
        dd_sales.d_day_name AS day_name,
        td.t_hour AS hour,
        td.t_shift AS shift,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_net_profit) AS total_profit,
        SUM(ss.ss_quantity) AS total_quantity_sold,
        AVG(ss.ss_ext_sales_price) AS avg_sales_price,
        CASE
            WHEN dd_sales.d_holiday = 'Y' THEN 'Holiday'
            WHEN dd_sales.d_weekend = 'Y' THEN 'Weekend'
            ELSE 'Weekday'
        END AS day_type,
        COALESCE(dd_closed.d_date, DATE '9999-12-31') AS closed_date,
        i.total_inventory_on_hand
    FROM store_sales ss
    JOIN date_dim dd_sales
        ON ss.ss_sold_date_sk = dd_sales.d_date_sk
    JOIN time_dim td
        ON ss.ss_sold_time_sk = td.t_time_sk
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    JOIN inv_agg i
        ON i.inv_date_sk = dd_sales.d_date_sk
    LEFT JOIN date_dim dd_closed
        ON s.s_closed_date_sk = dd_closed.d_date_sk
    WHERE s.s_state = 'CA'
      AND dd_sales.d_year = 2022
      AND td.t_shift IN ('Morning', 'Afternoon')
    GROUP BY
        s.s_store_id,
        s.s_store_name,
        s.s_city,
        s.s_state,
        dd_sales.d_date,
        dd_sales.d_day_name,
        td.t_hour,
        td.t_shift,
        dd_sales.d_holiday,
        dd_sales.d_weekend,
        dd_closed.d_date,
        i.total_inventory_on_hand
    HAVING SUM(ss.ss_ext_sales_price) > 10000
)
SELECT
    store_id,
    store_name,
    city,
    state,
    sale_date,
    day_name,
    hour,
    shift,
    total_sales,
    total_profit,
    total_quantity_sold,
    avg_sales_price,
    day_type,
    closed_date,
    total_inventory_on_hand,
    RANK() OVER (PARTITION BY sale_date ORDER BY total_profit DESC) AS profit_rank
FROM sales_agg
ORDER BY total_sales DESC
LIMIT 100
