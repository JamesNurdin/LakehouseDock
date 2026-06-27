WITH enriched_returns AS (
    SELECT
        cp.cp_department AS department,
        cp.cp_type AS page_type,
        ca_ret.ca_state AS returning_state,
        ca_ref.ca_state AS refunded_state,
        td.t_hour AS hour_of_day,
        cr.cr_return_quantity AS return_quantity,
        cr.cr_return_amount AS return_amount,
        cr.cr_net_loss AS net_loss
    FROM catalog_returns cr
    JOIN catalog_page cp
        ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN time_dim td
        ON cr.cr_returned_time_sk = td.t_time_sk
    JOIN customer_address ca_ret
        ON cr.cr_returning_addr_sk = ca_ret.ca_address_sk
    JOIN customer_address ca_ref
        ON cr.cr_refunded_addr_sk = ca_ref.ca_address_sk
    WHERE td.t_am_pm = 'PM'
)
SELECT
    department,
    page_type,
    returning_state,
    refunded_state,
    hour_of_day,
    COUNT(*) AS total_returns,
    SUM(return_quantity) AS total_quantity,
    SUM(return_amount) AS total_return_amount,
    SUM(net_loss) AS total_net_loss,
    AVG(return_amount) AS avg_return_amount,
    MIN(return_amount) AS min_return_amount,
    MAX(return_amount) AS max_return_amount
FROM enriched_returns
GROUP BY department, page_type, returning_state, refunded_state, hour_of_day
ORDER BY total_net_loss DESC
LIMIT 50
