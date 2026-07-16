WITH aggregated_returns AS (
    SELECT
        s.s_store_name,
        s.s_city,
        s.s_state,
        d.d_year,
        d.d_date,
        ca_refunded.ca_country AS refunded_country,
        ca_returning.ca_city AS returning_city,
        hd_refunded.hd_buy_potential AS refunded_buy_potential,
        hd_returning.hd_vehicle_count AS returning_vehicle_count,
        COUNT(*) AS num_returns,
        SUM(cr.cr_net_loss) AS total_net_loss,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_return_quantity) AS total_return_qty,
        AVG(cr.cr_return_quantity) AS avg_return_qty,
        SUM(cr.cr_refunded_cash) AS total_refunded_cash,
        AVG(cr.cr_refunded_cash) AS avg_refunded_cash
    FROM catalog_returns cr
    JOIN date_dim d
        ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN household_demographics hd_refunded
        ON cr.cr_refunded_hdemo_sk = hd_refunded.hd_demo_sk
    JOIN household_demographics hd_returning
        ON cr.cr_returning_hdemo_sk = hd_returning.hd_demo_sk
    JOIN customer_address ca_refunded
        ON cr.cr_refunded_addr_sk = ca_refunded.ca_address_sk
    JOIN customer_address ca_returning
        ON cr.cr_returning_addr_sk = ca_returning.ca_address_sk
    JOIN store s
        ON s.s_closed_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 2000 AND 2005
    GROUP BY
        s.s_store_name,
        s.s_city,
        s.s_state,
        d.d_year,
        d.d_date,
        ca_refunded.ca_country,
        ca_returning.ca_city,
        hd_refunded.hd_buy_potential,
        hd_returning.hd_vehicle_count
)
SELECT
    ar.s_store_name,
    ar.s_city,
    ar.s_state,
    ar.d_year,
    ar.d_date,
    ar.refunded_country,
    ar.returning_city,
    ar.refunded_buy_potential,
    ar.returning_vehicle_count,
    ar.num_returns,
    ar.total_net_loss,
    ar.total_return_amount,
    ar.total_return_qty,
    ar.avg_return_qty,
    ar.total_refunded_cash,
    ar.avg_refunded_cash,
    RANK() OVER (PARTITION BY ar.d_year ORDER BY ar.total_net_loss DESC) AS yearly_net_loss_rank
FROM aggregated_returns ar
ORDER BY ar.total_net_loss DESC
LIMIT 100
