WITH store_returns AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        s.s_city AS store_city,
        s.s_state AS store_state,
        d_ret.d_date AS return_date,
        d_ret.d_year,
        d_ret.d_month_seq,
        t.t_hour,
        t.t_minute,
        cr.cr_return_amount,
        cr.cr_net_loss,
        cr.cr_return_quantity,
        cr.cr_refunded_cash,
        cr.cr_fee,
        cr.cr_order_number,
        ca_ret.ca_city AS returning_city,
        ca_ret.ca_state AS returning_state,
        ca_ref.ca_city AS refunded_city,
        ca_ref.ca_state AS refunded_state,
        CASE
            WHEN cr.cr_return_amount < 20 THEN 'Low'
            WHEN cr.cr_return_amount BETWEEN 20 AND 100 THEN 'Medium'
            ELSE 'High'
        END AS return_amount_bucket
    FROM catalog_returns cr
    JOIN date_dim d_ret
        ON cr.cr_returned_date_sk = d_ret.d_date_sk
    JOIN time_dim t
        ON cr.cr_returned_time_sk = t.t_time_sk
    JOIN customer_address ca_ret
        ON cr.cr_returning_addr_sk = ca_ret.ca_address_sk
    JOIN customer_address ca_ref
        ON cr.cr_refunded_addr_sk = ca_ref.ca_address_sk
    JOIN store s
        ON s.s_closed_date_sk = d_ret.d_date_sk
    WHERE d_ret.d_year = 2020
),
aggregated AS (
    SELECT
        sr.s_store_id,
        sr.s_store_name,
        sr.store_city,
        sr.store_state,
        sr.return_date,
        sr.t_hour,
        MAX(sr.t_minute) AS max_minute,
        COUNT(*) AS num_returns,
        SUM(sr.cr_return_amount) AS total_return_amount,
        SUM(sr.cr_net_loss) AS total_net_loss,
        AVG(sr.cr_return_quantity) AS avg_return_quantity,
        SUM(sr.cr_refunded_cash) AS total_refunded_cash,
        SUM(sr.cr_fee) AS total_fee,
        ROUND(SUM(sr.cr_refunded_cash) / NULLIF(SUM(sr.cr_return_amount), 0), 2) AS refunded_to_return_ratio,
        MIN(sr.return_amount_bucket) AS min_return_amount_bucket,
        MAX(sr.return_amount_bucket) AS max_return_amount_bucket,
        array_join(array_agg(DISTINCT sr.returning_city || ', ' || sr.returning_state), '; ') AS returning_cities,
        array_join(array_agg(DISTINCT sr.refunded_city || ', ' || sr.refunded_state), '; ') AS refunded_cities
    FROM store_returns sr
    GROUP BY
        sr.s_store_id,
        sr.s_store_name,
        sr.store_city,
        sr.store_state,
        sr.return_date,
        sr.t_hour
    HAVING COUNT(*) > 2
)
SELECT
    a.s_store_id,
    a.s_store_name,
    a.store_city,
    a.store_state,
    a.return_date,
    a.t_hour,
    a.max_minute,
    a.num_returns,
    a.total_return_amount,
    a.total_net_loss,
    a.avg_return_quantity,
    a.total_refunded_cash,
    a.total_fee,
    a.refunded_to_return_ratio,
    a.min_return_amount_bucket,
    a.max_return_amount_bucket,
    a.returning_cities,
    a.refunded_cities,
    SUM(a.total_net_loss) OVER (
        PARTITION BY a.s_store_id
        ORDER BY a.return_date
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cumulative_net_loss
FROM aggregated a
ORDER BY a.total_net_loss DESC
LIMIT 100
