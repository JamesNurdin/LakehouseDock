WITH filtered_returns AS (
    SELECT
        cr_returning_hdemo_sk,
        cr_refunded_hdemo_sk,
        cr_reason_sk,
        cr_return_amount,
        cr_return_quantity,
        cr_net_loss,
        cr_fee,
        cr_ship_mode_sk,
        cr_returned_date_sk,
        cr_order_number
    FROM catalog_returns
    WHERE cr_return_amount > 100
      AND cr_return_quantity > 0
      AND cr_returned_date_sk BETWEEN 2450000 AND 2453650
)
SELECT
    r.r_reason_desc AS reason,
    hd_ret.hd_buy_potential AS returning_buy_potential,
    hd_ref.hd_buy_potential AS refunded_buy_potential,
    COUNT(*) AS return_count,
    SUM(fr.cr_return_amount) AS total_return_amount,
    SUM(fr.cr_net_loss) AS total_net_loss,
    SUM(fr.cr_fee) AS total_fee,
    AVG(fr.cr_return_quantity) AS avg_return_quantity,
    SUM(fr.cr_return_amount) / NULLIF(SUM(fr.cr_net_loss), 0) AS return_to_loss_ratio
FROM filtered_returns fr
JOIN household_demographics hd_ret
    ON fr.cr_returning_hdemo_sk = hd_ret.hd_demo_sk
JOIN household_demographics hd_ref
    ON fr.cr_refunded_hdemo_sk = hd_ref.hd_demo_sk
JOIN reason r
    ON fr.cr_reason_sk = r.r_reason_sk
GROUP BY
    r.r_reason_desc,
    hd_ret.hd_buy_potential,
    hd_ref.hd_buy_potential
HAVING SUM(fr.cr_return_amount) > 5000
ORDER BY total_return_amount DESC
LIMIT 50
