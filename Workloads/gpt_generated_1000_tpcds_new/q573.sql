WITH base_store_sales AS (
    SELECT *
    FROM store_sales
    TABLESAMPLE BERNOULLI (10)
),
joined AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_sold_time_sk,
        ss.ss_item_sk,
        ss.ss_customer_sk,
        ss.ss_cdemo_sk,
        ss.ss_addr_sk,
        ss.ss_quantity,
        ss.ss_ext_sales_price,
        d.d_year,
        t.t_hour,
        i.i_item_id,
        i.i_brand,
        c.c_customer_id,
        ca.ca_state,
        cd.cd_gender,
        sr.sr_return_quantity,
        r.r_reason_desc,
        cs.cs_ext_sales_price AS cs_ext_sales_price,
        cs.cs_quantity AS cs_quantity,
        cs.cs_sales_price AS cs_sales_price,
        ws.ws_ext_sales_price AS ws_ext_sales_price,
        sm.sm_carrier,
        wp.wp_url,
        -- running total per item (analytic window)
        SUM(cs.cs_ext_sales_price) OVER (PARTITION BY cs.cs_item_sk ORDER BY cs.cs_sold_date_sk
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cs_running_sales,
        -- array for UNNEST later
        ARRAY[cs.cs_quantity, cs.cs_sales_price] AS cs_metrics
    FROM base_store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
        AND sr.sr_item_sk = ss.ss_item_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN catalog_sales cs ON cs.cs_item_sk = i.i_item_sk
        AND cs.cs_sold_date_sk = d.d_date_sk
        AND cs.cs_sold_time_sk = t.t_time_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
        AND cr.cr_item_sk = cs.cs_item_sk
    JOIN web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk
        AND ws.ws_item_sk = i.i_item_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN date_dim d2 ON wp.wp_creation_date_sk = d2.d_date_sk
    WHERE cs.cs_ext_sales_price > (
        SELECT MAX(ws2.ws_net_paid)
        FROM web_sales ws2
        WHERE ws2.ws_sold_date_sk = d.d_date_sk
    )
),
unnested AS (
    SELECT
        j.c_customer_id,
        j.i_item_id,
        j.d_year,
        m AS metric_value,
        seq
    FROM joined j
    CROSS JOIN UNNEST(j.cs_metrics) WITH ORDINALITY AS t(m, seq)
),
agg_store AS (
    SELECT
        j.c_customer_id,
        j.i_item_id,
        j.d_year,
        SUM(j.ss_ext_sales_price) AS total_store_sales,
        SUM(j.cs_running_sales) AS total_running_sales,
        SUM(u.metric_value) AS sum_metric_values
    FROM joined j
    LEFT JOIN unnested u
        ON j.c_customer_id = u.c_customer_id
        AND j.i_item_id = u.i_item_id
        AND j.d_year = u.d_year
    GROUP BY j.c_customer_id, j.i_item_id, j.d_year
),
agg_web AS (
    SELECT
        j.c_customer_id,
        j.i_item_id,
        j.d_year,
        SUM(j.ws_ext_sales_price) AS total_web_sales,
        SUM(j.cs_running_sales) AS total_running_sales,
        SUM(u.metric_value) AS sum_metric_values
    FROM joined j
    LEFT JOIN unnested u
        ON j.c_customer_id = u.c_customer_id
        AND j.i_item_id = u.i_item_id
        AND j.d_year = u.d_year
    GROUP BY j.c_customer_id, j.i_item_id, j.d_year
),
empty_set AS (
    SELECT
        j.c_customer_id,
        j.i_item_id,
        j.d_year,
        0 AS total_store_sales,
        0 AS total_running_sales,
        0 AS sum_metric_values
    FROM joined j
    GROUP BY j.c_customer_id, j.i_item_id, j.d_year
    HAVING COUNT(*) = 0
)
SELECT *
FROM (
    SELECT *
    FROM agg_store
    INTERSECT
    SELECT *
    FROM agg_web
) AS intersected
EXCEPT
SELECT *
FROM empty_set
ORDER BY total_store_sales DESC
LIMIT 100
