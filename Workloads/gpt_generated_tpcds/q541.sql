WITH reason_agg AS (
    SELECT
        r.r_reason_id,
        r.r_reason_desc,
        COUNT(*) AS return_count,
        SUM(wr.wr_return_quantity) AS total_quantity,
        SUM(wr.wr_return_amt) AS total_return_amount,
        SUM(wr.wr_return_tax) AS total_tax,
        SUM(wr.wr_return_amt_inc_tax) AS total_return_amount_inc_tax,
        SUM(wr.wr_fee) AS total_fee,
        SUM(wr.wr_return_ship_cost) AS total_ship_cost,
        SUM(wr.wr_refunded_cash) AS total_refunded_cash,
        SUM(wr.wr_reversed_charge) AS total_reversed_charge,
        SUM(wr.wr_account_credit) AS total_account_credit,
        SUM(wr.wr_net_loss) AS total_net_loss,
        AVG(wr.wr_return_amt) AS avg_return_amount
    FROM web_returns wr
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    WHERE wr.wr_return_amt > 0
    GROUP BY r.r_reason_id, r.r_reason_desc
)
SELECT
    r_reason_id,
    r_reason_desc,
    return_count,
    total_quantity,
    total_return_amount,
    total_tax,
    total_return_amount_inc_tax,
    total_fee,
    total_ship_cost,
    total_refunded_cash,
    total_reversed_charge,
    total_account_credit,
    total_net_loss,
    avg_return_amount,
    ROW_NUMBER() OVER (ORDER BY total_net_loss DESC) AS net_loss_rank
FROM reason_agg
ORDER BY net_loss_rank
LIMIT 10
