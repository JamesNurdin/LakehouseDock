WITH filtered_returns AS (
    SELECT
        cr_returned_date_sk,
        cr_returned_time_sk,
        cr_call_center_sk,
        cr_refunded_addr_sk,
        cr_refunded_hdemo_sk,
        cr_returning_addr_sk,
        cr_returning_hdemo_sk,
        cr_return_amount,
        cr_net_loss,
        cr_return_quantity
    FROM catalog_returns
    WHERE cr_return_amount > 0
)
SELECT
    d.d_year,
    cc.cc_state,
    p.p_promo_name,
    COUNT(*)                                   AS num_returns,
    SUM(fr.cr_return_amount)                  AS total_return_amount,
    AVG(fr.cr_return_amount)                  AS avg_return_amount,
    SUM(fr.cr_net_loss)                       AS total_net_loss,
    MIN(fr.cr_return_amount)                  AS min_return_amount,
    MAX(fr.cr_return_amount)                  AS max_return_amount
FROM filtered_returns fr
JOIN date_dim d
    ON fr.cr_returned_date_sk = d.d_date_sk
JOIN time_dim t
    ON fr.cr_returned_time_sk = t.t_time_sk
JOIN call_center cc
    ON fr.cr_call_center_sk = cc.cc_call_center_sk
JOIN customer_address ca_ref
    ON fr.cr_refunded_addr_sk = ca_ref.ca_address_sk
JOIN household_demographics hd_ref
    ON fr.cr_refunded_hdemo_sk = hd_ref.hd_demo_sk
JOIN customer_address ca_ret
    ON fr.cr_returning_addr_sk = ca_ret.ca_address_sk
JOIN household_demographics hd_ret
    ON fr.cr_returning_hdemo_sk = hd_ret.hd_demo_sk
JOIN inventory i
    ON d.d_date_sk = i.inv_date_sk
JOIN promotion p
    ON d.d_date_sk = p.p_start_date_sk
WHERE
    d.d_year = 2001
    AND cc.cc_state = 'CA'
    AND p.p_channel_demo = 'N'
    AND i.inv_quantity_on_hand > 500
    AND d.d_date_sk <= p.p_end_date_sk
GROUP BY
    d.d_year,
    cc.cc_state,
    p.p_promo_name
HAVING
    SUM(fr.cr_return_amount) > 10000
ORDER BY
    total_return_amount DESC
LIMIT 100
