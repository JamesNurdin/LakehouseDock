WITH joined AS (
    SELECT
        wr.wr_order_number,
        wr.wr_return_amt,
        wr.wr_fee,
        wr.wr_reversed_charge,
        wr.wr_net_loss,
        wr.wr_return_quantity,
        hd_ref.hd_buy_potential,
        hd_ref.hd_dep_count,
        hd_ret.hd_vehicle_count,
        (wr.wr_fee + wr.wr_reversed_charge + wr.wr_net_loss) AS total_loss,
        RANK() OVER (PARTITION BY hd_ref.hd_buy_potential ORDER BY (wr.wr_fee + wr.wr_reversed_charge + wr.wr_net_loss) DESC) AS loss_rank
    FROM web_returns wr
    LEFT JOIN household_demographics hd_ref
        ON wr.wr_refunded_hdemo_sk = hd_ref.hd_demo_sk
    LEFT JOIN household_demographics hd_ret
        ON wr.wr_returning_hdemo_sk = hd_ret.hd_demo_sk
    WHERE wr.wr_return_amt > 100.00
      AND wr.wr_fee BETWEEN 10 AND 80
      AND hd_ref.hd_buy_potential IN ('0-500', '501-1000', '1001-5000')
)
SELECT
    j.wr_order_number,
    j.wr_return_amt,
    j.total_loss,
    j.hd_buy_potential,
    j.hd_dep_count,
    j.hd_vehicle_count,
    j.loss_rank
FROM joined j
WHERE j.wr_order_number NOT IN (
    SELECT DISTINCT wr2.wr_order_number
    FROM web_returns wr2
    WHERE wr2.wr_return_quantity = 0
)
ORDER BY j.total_loss DESC
LIMIT 100
