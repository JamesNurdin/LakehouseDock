WITH joined_data AS (
    SELECT
        cr.cr_return_amount,
        cr.cr_fee,
        cr.cr_net_loss AS cr_net_loss,
        sr.sr_return_amt,
        sr.sr_net_loss AS sr_net_loss,
        ws.ws_net_profit,
        ws.ws_quantity,
        d.d_year,
        d.d_date,
        t.t_hour,
        s.s_store_id,
        s.s_country,
        s.s_number_employees,
        w.w_warehouse_id,
        w.w_state,
        c.c_customer_id,
        cd.cd_gender
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN time_dim t ON cr.cr_returned_time_sk = t.t_time_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    JOIN store_returns sr ON sr.sr_returned_date_sk = d.d_date_sk
        AND sr.sr_return_time_sk = t.t_time_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk
        AND ws.ws_sold_time_sk = t.t_time_sk
    JOIN inventory i ON i.inv_date_sk = d.d_date_sk
        AND i.inv_warehouse_sk = w.w_warehouse_sk
    WHERE d.d_year = 2001
      AND s.s_country = 'United States'
      AND s.s_number_employees > 250
      AND w.w_state = 'CA'
      AND t.t_hour BETWEEN 9 AND 17
      AND cd.cd_gender = 'F'
      AND EXISTS (
          SELECT 1 FROM web_sales ws2
          WHERE ws2.ws_bill_customer_sk = c.c_customer_sk
            AND ws2.ws_net_paid > 2000
      )
),
agg AS (
    SELECT
        d_year,
        s_store_id,
        w_warehouse_id,
        SUM(cr_return_amount)               AS total_cr_return_amount,
        SUM(sr_return_amt)                  AS total_sr_return_amount,
        SUM(ws_net_profit)                  AS total_ws_profit,
        COUNT(DISTINCT c_customer_id)       AS unique_customers,
        AVG(ws_quantity)                    AS avg_ws_quantity,
        MAX(cr_fee)                         AS max_cr_fee,
        GROUPING(d_year)                    AS g_year,
        GROUPING(s_store_id)                AS g_store,
        GROUPING(w_warehouse_id)            AS g_warehouse
    FROM joined_data
    GROUP BY GROUPING SETS (
        (d_year, s_store_id, w_warehouse_id),
        (d_year, s_store_id),
        (d_year, w_warehouse_id),
        (d_year),
        ()
    )
)
SELECT
    d_year,
    s_store_id,
    w_warehouse_id,
    total_cr_return_amount,
    total_sr_return_amount,
    total_ws_profit,
    unique_customers,
    avg_ws_quantity,
    max_cr_fee,
    SUM(total_cr_return_amount) OVER (
        ORDER BY d_year ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS running_total_cr_return_amount,
    g_year,
    g_store,
    g_warehouse
FROM agg
ORDER BY d_year, s_store_id, w_warehouse_id
