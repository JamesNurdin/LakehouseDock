WITH sales_data AS (
    -- In‑store sales
    SELECT
        s.s_store_name,
        ca.ca_city,
        ca.ca_state,
        d.d_year,
        d.d_qoy,
        t.t_hour,
        t.t_sub_shift,
        ss.ss_quantity                AS quantity,
        ss.ss_sales_price             AS sales_price,
        ss.ss_net_profit              AS net_profit,
        'store'                       AS channel
    FROM store_sales ss
    JOIN store s               ON ss.ss_store_sk = s.s_store_sk
    JOIN date_dim d            ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN time_dim t            ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN customer_address ca   ON ss.ss_addr_sk = ca.ca_address_sk
    
    UNION ALL
    
    -- Web sales (online)
    SELECT
        CAST(NULL AS varchar)         AS s_store_name,
        ca.ca_city,
        ca.ca_state,
        d.d_year,
        d.d_qoy,
        t.t_hour,
        t.t_sub_shift,
        ws.ws_quantity                AS quantity,
        ws.ws_sales_price             AS sales_price,
        ws.ws_net_profit              AS net_profit,
        'web'                         AS channel
    FROM web_sales ws
    JOIN date_dim d            ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN time_dim t            ON ws.ws_sold_time_sk = t.t_time_sk
    JOIN customer_address ca   ON ws.ws_bill_addr_sk = ca.ca_address_sk
),
agg_sales AS (
    SELECT
        s_store_name,
        ca_city,
        channel,
        t_hour,
        SUM(quantity)       AS total_quantity,
        SUM(sales_price)    AS total_sales_price,
        SUM(net_profit)     AS total_net_profit
    FROM sales_data
    WHERE d_year = 2001               -- filter 1: specific year
      AND d_qoy = 2                   -- filter 2: quarter of year
      AND t_sub_shift = 'morning'     -- filter 3: time shift
      AND ca_state = 'CA'             -- filter 4: state
    GROUP BY s_store_name, ca_city, channel, t_hour
)
SELECT
    a.s_store_name,
    a.ca_city,
    a.channel,
    a.t_hour,
    a.total_quantity,
    a.total_sales_price,
    a.total_net_profit,
    CASE u.idx WHEN 1 THEN 'sales_price' ELSE 'net_profit' END AS metric_name,
    u.metric_value,
    (
        SELECT SUM(ws.ws_net_profit)
        FROM web_sales ws
        JOIN date_dim d2 ON ws.ws_sold_date_sk = d2.d_date_sk
        WHERE d2.d_year = 2001 AND d2.d_qoy = 2
    ) AS overall_web_profit
FROM agg_sales a
CROSS JOIN UNNEST(ARRAY[a.total_sales_price, a.total_net_profit]) WITH ORDINALITY AS u(metric_value, idx)
ORDER BY a.total_sales_price DESC
LIMIT 100
