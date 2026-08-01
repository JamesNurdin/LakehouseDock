WITH filtered AS (
    SELECT
        cr_returned_date_sk,
        cr_returned_time_sk,
        cr_item_sk,
        cr_return_quantity,
        cr_return_amount,
        cr_return_tax,
        cr_return_amt_inc_tax,
        cr_fee,
        cr_return_ship_cost,
        cr_net_loss,
        cr_ship_mode_sk,
        cr_warehouse_sk,
        cr_reversed_charge
    FROM tpcds.catalog_returns
    WHERE cr_warehouse_sk IN (13, 17, 10, 2)
      AND cr_return_amount > 50
      AND cr_return_quantity >= 1
      AND cr_reversed_charge <= 200
      AND cr_returned_date_sk BETWEEN 2450000 AND 2450100
)
SELECT
    f.cr_returned_date_sk,
    f.cr_item_sk,
    f.cr_return_amount,
    f.cr_net_loss,
    s.sm_ship_mode_id,
    s.sm_carrier,
    s.sm_contract,
    CASE
        WHEN f.cr_net_loss > 100 THEN 'HIGH'
        WHEN f.cr_net_loss > 50 THEN 'MEDIUM'
        ELSE 'LOW'
    END AS loss_category,
    RANK() OVER (PARTITION BY s.sm_carrier ORDER BY f.cr_net_loss DESC) AS carrier_loss_rank,
    ROW_NUMBER() OVER (ORDER BY f.cr_net_loss DESC) AS overall_loss_rownum
FROM filtered f
JOIN tpcds.ship_mode s
    ON f.cr_ship_mode_sk = s.sm_ship_mode_sk
WHERE s.sm_carrier IN ('UPS', 'DHL')
ORDER BY f.cr_net_loss DESC
LIMIT 100
