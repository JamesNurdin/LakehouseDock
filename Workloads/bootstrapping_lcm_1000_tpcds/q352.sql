SELECT
    s.s_store_id,
    s.s_store_name,
    dd.d_year,
    cd_ref.cd_gender AS refunded_gender,
    cd_ret.cd_gender AS returning_gender,
    ca_ref.ca_state AS refunded_state,
    ca_ret.ca_state AS returning_state,
    SUM(cr.cr_net_loss) AS total_net_loss,
    SUM(cr.cr_return_quantity) AS total_return_qty,
    AVG(cr.cr_return_amount) AS avg_return_amount,
    COUNT(*) AS return_count,
    RANK() OVER (PARTITION BY dd.d_year ORDER BY SUM(cr.cr_net_loss) DESC) AS loss_rank
FROM catalog_returns cr
JOIN date_dim dd
    ON cr.cr_returned_date_sk = dd.d_date_sk
JOIN customer_demographics cd_ref
    ON cr.cr_refunded_cdemo_sk = cd_ref.cd_demo_sk
JOIN customer_address ca_ref
    ON cr.cr_refunded_addr_sk = ca_ref.ca_address_sk
JOIN customer_demographics cd_ret
    ON cr.cr_returning_cdemo_sk = cd_ret.cd_demo_sk
JOIN customer_address ca_ret
    ON cr.cr_returning_addr_sk = ca_ret.ca_address_sk
JOIN store s
    ON s.s_closed_date_sk = dd.d_date_sk
WHERE dd.d_year BETWEEN 1999 AND 2002
GROUP BY
    s.s_store_id,
    s.s_store_name,
    dd.d_year,
    cd_ref.cd_gender,
    cd_ret.cd_gender,
    ca_ref.ca_state,
    ca_ret.ca_state
ORDER BY total_net_loss DESC
LIMIT 100
