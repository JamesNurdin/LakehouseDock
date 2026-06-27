WITH returns_by_demo AS (
    SELECT
        hd.hd_demo_sk,
        hd.hd_buy_potential,
        hd.hd_dep_count,
        hd.hd_vehicle_count,
        cr.cr_return_quantity,
        cr.cr_return_amount,
        cr.cr_return_tax,
        cr.cr_return_amt_inc_tax,
        cr.cr_fee,
        cr.cr_return_ship_cost,
        cr.cr_refunded_cash,
        cr.cr_reversed_charge,
        cr.cr_store_credit,
        cr.cr_net_loss
    FROM catalog_returns cr
    JOIN household_demographics hd
        ON cr.cr_returning_hdemo_sk = hd.hd_demo_sk
    WHERE cr.cr_return_quantity > 0
)
SELECT
    hd_buy_potential,
    hd_dep_count,
    hd_vehicle_count,
    COUNT(*) AS total_returns,
    SUM(cr_return_quantity) AS total_return_quantity,
    AVG(cr_return_quantity) AS avg_return_quantity,
    SUM(cr_return_amount) AS total_return_amount,
    SUM(cr_return_tax) AS total_return_tax,
    SUM(cr_return_amt_inc_tax) AS total_return_amount_inc_tax,
    SUM(cr_fee) AS total_fee,
    SUM(cr_return_ship_cost) AS total_return_ship_cost,
    SUM(cr_refunded_cash) AS total_refunded_cash,
    SUM(cr_reversed_charge) AS total_reversed_charge,
    SUM(cr_store_credit) AS total_store_credit,
    SUM(cr_net_loss) AS total_net_loss
FROM returns_by_demo
GROUP BY hd_buy_potential, hd_dep_count, hd_vehicle_count
ORDER BY total_net_loss DESC
LIMIT 10
