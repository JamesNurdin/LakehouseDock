WITH returns_by_center AS (
    SELECT
        cr.cr_call_center_sk,
        COUNT(*) AS return_count,
        SUM(cr.cr_return_quantity) AS total_quantity,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_return_tax) AS total_tax,
        SUM(cr.cr_return_amt_inc_tax) AS total_return_inc_tax,
        SUM(cr.cr_fee) AS total_fee,
        SUM(cr.cr_return_ship_cost) AS total_ship_cost,
        SUM(cr.cr_refunded_cash) AS total_refunded_cash,
        SUM(cr.cr_reversed_charge) AS total_reversed_charge,
        SUM(cr.cr_store_credit) AS total_store_credit,
        SUM(cr.cr_net_loss) AS total_net_loss
    FROM catalog_returns cr
    GROUP BY cr.cr_call_center_sk
)
SELECT
    cc.cc_call_center_id,
    cc.cc_name,
    cc.cc_state,
    cc.cc_country,
    cc.cc_market_manager,
    rb.return_count,
    rb.total_quantity,
    rb.total_return_amount,
    rb.total_net_loss,
    (rb.total_net_loss / NULLIF(rb.total_return_amount, 0)) AS net_loss_ratio,
    (rb.total_return_amount / NULLIF(rb.return_count, 0)) AS avg_return_amount
FROM returns_by_center rb
JOIN call_center cc
    ON rb.cr_call_center_sk = cc.cc_call_center_sk
ORDER BY rb.total_net_loss DESC
LIMIT 10
