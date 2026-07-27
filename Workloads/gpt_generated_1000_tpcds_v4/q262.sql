WITH bill_sales AS (
    SELECT
        ca.ca_state,
        d.d_date,
        SUM(ws.ws_net_paid_inc_tax) AS total_sales,
        RANK() OVER (PARTITION BY ca.ca_state ORDER BY SUM(ws.ws_net_paid_inc_tax) DESC) AS state_day_rank,
        CASE WHEN SUM(ws.ws_net_paid_inc_tax) > 5000 THEN 'High' ELSE 'Low' END AS sales_category
    FROM
        web_sales ws
        JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
        JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
        JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
    WHERE
        d.d_year = 2022
        AND t.t_hour BETWEEN 9 AND 17
        AND ca.ca_state IN ('CA', 'TX', 'NY')
        AND ws.ws_warehouse_sk IN (5, 15, 16)
        AND ws.ws_quantity > 1
        AND ws.ws_net_paid_inc_tax > 100
    GROUP BY
        ca.ca_state,
        d.d_date
),
ship_sales AS (
    SELECT
        ca.ca_state,
        d.d_date,
        SUM(ws.ws_net_paid_inc_tax) AS total_sales,
        RANK() OVER (PARTITION BY ca.ca_state ORDER BY SUM(ws.ws_net_paid_inc_tax) DESC) AS state_day_rank,
        CASE WHEN SUM(ws.ws_net_paid_inc_tax) > 5000 THEN 'High' ELSE 'Low' END AS sales_category
    FROM
        web_sales ws
        JOIN date_dim d ON ws.ws_ship_date_sk = d.d_date_sk
        JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
        JOIN customer_address ca ON ws.ws_ship_addr_sk = ca.ca_address_sk
    WHERE
        d.d_year = 2022
        AND t.t_hour BETWEEN 0 AND 23
        AND ca.ca_state IN ('FL', 'IL')
        AND ws.ws_warehouse_sk IN (2, 18)
        AND ws.ws_quantity > 2
        AND ws.ws_net_paid_inc_tax > 200
    GROUP BY
        ca.ca_state,
        d.d_date
)
SELECT
    ca_state,
    d_date,
    total_sales,
    state_day_rank,
    sales_category
FROM (
    SELECT ca_state, d_date, total_sales, state_day_rank, sales_category FROM bill_sales
    UNION ALL
    SELECT ca_state, d_date, total_sales, state_day_rank, sales_category FROM ship_sales
) AS combined
ORDER BY total_sales DESC, ca_state
