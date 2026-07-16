WITH aggregated_returns AS (
    SELECT
        d_ret.d_year AS return_year,
        d_ret.d_month_seq AS return_month_seq,
        s.s_market_id,
        ws.web_market_manager,
        ca_refunded.ca_state AS refunded_state,
        ca_returning.ca_state AS returning_state,
        d_close.d_year AS web_close_year,
        d_close.d_month_seq AS web_close_month_seq,
        COUNT(*) AS num_returns,
        SUM(cr.cr_net_loss) AS total_net_loss,
        AVG(cr.cr_fee) AS avg_fee,
        SUM(cr.cr_return_quantity) AS total_quantity,
        SUM(cr.cr_return_amount) AS total_return_amount
    FROM catalog_returns cr
    JOIN date_dim d_ret ON cr.cr_returned_date_sk = d_ret.d_date_sk
    JOIN customer_address ca_refunded ON cr.cr_refunded_addr_sk = ca_refunded.ca_address_sk
    JOIN customer_address ca_returning ON cr.cr_returning_addr_sk = ca_returning.ca_address_sk
    JOIN store s ON s.s_closed_date_sk = d_ret.d_date_sk
    JOIN web_site ws ON ws.web_open_date_sk = d_ret.d_date_sk
    JOIN date_dim d_close ON ws.web_close_date_sk = d_close.d_date_sk
    GROUP BY
        d_ret.d_year,
        d_ret.d_month_seq,
        s.s_market_id,
        ws.web_market_manager,
        ca_refunded.ca_state,
        ca_returning.ca_state,
        d_close.d_year,
        d_close.d_month_seq
)
SELECT
    ar.return_year,
    ar.return_month_seq,
    ar.s_market_id,
    ar.web_market_manager,
    ar.refunded_state,
    ar.returning_state,
    ar.web_close_year,
    ar.web_close_month_seq,
    ar.num_returns,
    ar.total_net_loss,
    ar.avg_fee,
    ar.total_quantity,
    ar.total_return_amount,
    ROW_NUMBER() OVER (PARTITION BY ar.return_year ORDER BY ar.total_net_loss DESC) AS loss_rank
FROM aggregated_returns ar
WHERE ar.total_net_loss > 0
ORDER BY ar.total_net_loss DESC
LIMIT 100
