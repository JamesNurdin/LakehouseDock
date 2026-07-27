WITH joined_data AS (
    SELECT
        ss.ss_ticket_number,
        ss.ss_ext_sales_price                         AS store_sales_ext,
        sr.sr_return_amt_inc_tax                     AS store_return_amt,
        ws.ws_ext_sales_price                        AS web_sales_ext,
        ws.ws_ext_ship_cost                          AS web_ship_cost,
        c.c_customer_id                              AS customer_id,
        d.d_year                                     AS year,
        d.d_month_seq                                AS month_seq,
        s.s_store_name                               AS store_name,
        s.s_state                                    AS store_state,
        sm.sm_carrier                                AS carrier,
        t.t_shift                                    AS shift
    FROM store_sales ss
    JOIN date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN time_dim t
        ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN customer c
        ON ss.ss_customer_sk = c.c_customer_sk
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    LEFT JOIN store_returns sr
        ON sr.sr_ticket_number = ss.ss_ticket_number
        AND sr.sr_item_sk = ss.ss_item_sk
        AND sr.sr_customer_sk = c.c_customer_sk
        AND sr.sr_store_sk = s.s_store_sk
    LEFT JOIN web_sales ws
        ON ws.ws_bill_customer_sk = c.c_customer_sk
        AND ws.ws_sold_date_sk = d.d_date_sk
        AND ws.ws_sold_time_sk = t.t_time_sk
    LEFT JOIN ship_mode sm
        ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE d.d_year = 2001
      AND d.d_month_seq BETWEEN 1200 AND 1210
      AND c.c_birth_year = 1975
      AND s.s_state = 'CA'
      AND sm.sm_carrier = 'UPS'
      AND t.t_shift = 'first'
      AND ws.ws_ext_ship_cost > 1000
      AND sr.sr_return_ship_cost < 100
),
agg_data AS (
    SELECT
        store_name,
        store_state,
        year,
        carrier,
        shift,
        COUNT(DISTINCT customer_id)                         AS unique_customers,
        SUM(store_sales_ext)                                 AS total_store_sales,
        SUM(web_sales_ext)                                   AS total_web_sales,
        SUM(web_ship_cost)                                   AS total_web_ship_cost,
        AVG(store_return_amt)                                AS avg_store_return,
        MIN(store_sales_ext)                                 AS min_store_sale,
        MAX(store_sales_ext)                                 AS max_store_sale
    FROM joined_data
    GROUP BY store_name, store_state, year, carrier, shift
)
SELECT
    store_name,
    store_state,
    year,
    carrier,
    shift,
    unique_customers,
    total_store_sales,
    total_web_sales,
    total_web_ship_cost,
    avg_store_return,
    min_store_sale,
    max_store_sale,
    SUM(total_store_sales) OVER (
        PARTITION BY store_state
        ORDER BY total_store_sales DESC
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cumulative_state_sales
FROM agg_data
ORDER BY total_store_sales DESC
LIMIT 100
