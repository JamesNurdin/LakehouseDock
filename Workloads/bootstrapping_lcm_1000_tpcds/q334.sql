WITH agg AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        s.s_city AS store_city,
        d.d_year,
        d.d_month_seq,
        d.d_date,
        t.t_hour,
        t.t_minute,
        ca_refunded.ca_city AS refunded_city,
        ca_refunded.ca_state AS refunded_state,
        ca_returning.ca_city AS returning_city,
        ca_returning.ca_state AS returning_state,
        COUNT(*) AS return_cnt,
        SUM(cr.cr_net_loss) AS total_net_loss,
        SUM(cr.cr_return_amount) AS total_return_amount,
        AVG(cr.cr_return_quantity) AS avg_return_qty,
        SUM(cr.cr_fee) AS total_fee,
        AVG(cr.cr_return_tax) AS avg_return_tax
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN time_dim t ON cr.cr_returned_time_sk = t.t_time_sk
    JOIN customer_address ca_refunded ON cr.cr_refunded_addr_sk = ca_refunded.ca_address_sk
    JOIN customer_address ca_returning ON cr.cr_returning_addr_sk = ca_returning.ca_address_sk
    JOIN store s ON s.s_closed_date_sk = d.d_date_sk
    GROUP BY
        s.s_store_id,
        s.s_store_name,
        s.s_city,
        d.d_year,
        d.d_month_seq,
        d.d_date,
        t.t_hour,
        t.t_minute,
        ca_refunded.ca_city,
        ca_refunded.ca_state,
        ca_returning.ca_city,
        ca_returning.ca_state
)
SELECT
    s_store_id,
    s_store_name,
    store_city,
    d_year,
    d_month_seq,
    d_date,
    t_hour,
    t_minute,
    refunded_city,
    refunded_state,
    returning_city,
    returning_state,
    return_cnt,
    total_net_loss,
    total_return_amount,
    avg_return_qty,
    total_fee,
    avg_return_tax,
    ROW_NUMBER() OVER (PARTITION BY s_store_id ORDER BY total_net_loss DESC) AS loss_rank
FROM agg
ORDER BY total_net_loss DESC
LIMIT 100
