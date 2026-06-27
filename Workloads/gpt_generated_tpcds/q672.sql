-- Analytical view of sales vs. returns by store, hour of day and household vehicle count
WITH sales_agg AS (
    SELECT
        s.s_store_sk,
        s.s_store_name,
        t.t_hour,
        hd.hd_demo_sk,
        hd.hd_vehicle_count,
        SUM(ss.ss_ext_sales_price)            AS total_sales_amount,
        SUM(ss.ss_ext_discount_amt)           AS total_discount_amount,
        SUM(ss.ss_net_profit)                 AS total_net_profit,
        SUM(ss.ss_quantity)                   AS total_quantity_sold
    FROM store_sales ss
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    JOIN time_dim t
        ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    GROUP BY
        s.s_store_sk,
        s.s_store_name,
        t.t_hour,
        hd.hd_demo_sk,
        hd.hd_vehicle_count
),
returns_agg AS (
    SELECT
        s.s_store_sk,
        s.s_store_name,
        t.t_hour,
        hd.hd_demo_sk,
        hd.hd_vehicle_count,
        SUM(sr.sr_return_amt)           AS total_return_amount,
        SUM(sr.sr_net_loss)             AS total_return_loss,
        SUM(sr.sr_return_quantity)      AS total_quantity_returned
    FROM store_returns sr
    JOIN store s
        ON sr.sr_store_sk = s.s_store_sk
    JOIN time_dim t
        ON sr.sr_return_time_sk = t.t_time_sk
    JOIN household_demographics hd
        ON sr.sr_hdemo_sk = hd.hd_demo_sk
    GROUP BY
        s.s_store_sk,
        s.s_store_name,
        t.t_hour,
        hd.hd_demo_sk,
        hd.hd_vehicle_count
)
SELECT
    s.s_store_name,
    s.t_hour,
    s.hd_vehicle_count,
    s.total_sales_amount,
    COALESCE(r.total_return_amount, 0)                         AS total_return_amount,
    s.total_sales_amount - COALESCE(r.total_return_amount, 0) AS net_sales_after_returns,
    s.total_net_profit - COALESCE(r.total_return_loss, 0)    AS net_profit_after_returns,
    CASE
        WHEN s.total_quantity_sold = 0 THEN 0
        ELSE (COALESCE(r.total_quantity_returned, 0) * 100.0 / s.total_quantity_sold)
    END                                                       AS return_rate_percent,
    CASE
        WHEN s.total_sales_amount = 0 THEN 0
        ELSE (s.total_discount_amount * 100.0 / s.total_sales_amount)
    END                                                       AS discount_percent
FROM sales_agg s
LEFT JOIN returns_agg r
    ON s.s_store_sk = r.s_store_sk
   AND s.t_hour = r.t_hour
   AND s.hd_demo_sk = r.hd_demo_sk
   AND s.hd_vehicle_count = r.hd_vehicle_count
ORDER BY s.s_store_name, s.t_hour
