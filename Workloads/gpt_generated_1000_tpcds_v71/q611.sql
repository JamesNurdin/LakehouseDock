/*
  Goal: Compute total catalog return amount and accompanying store return amount for each ship mode, household buy‑potential segment, and return date, filtered on specific demographic and shipping attributes, and retain only groups with significant store returns.
*/
WITH cr_agg AS (
    SELECT
        cr_ship_mode_sk,
        cr_refunded_hdemo_sk,
        cr_returned_date_sk,
        SUM(cr_return_amount) AS total_return_amount,
        COUNT(*) AS cnt_returns
    FROM catalog_returns
    WHERE cr_returned_date_sk BETWEEN 2450000 AND 2450500               -- filter on returned date surrogate key
      AND cr_return_quantity > 0                                      -- only positive quantities
      AND cr_refunded_customer_sk IN (7633027, 10295061)               -- focus on two customers
      AND cr_call_center_sk = 2                                       -- specific call center
    GROUP BY cr_ship_mode_sk, cr_refunded_hdemo_sk, cr_returned_date_sk
)
SELECT
    hd.hd_buy_potential,
    sm.sm_ship_mode_id,
    cr_agg.cr_returned_date_sk,
    cr_agg.total_return_amount,
    cr_agg.cnt_returns,
    SUM(sr.sr_return_amt) AS store_return_amount,
    COUNT(DISTINCT sr.sr_ticket_number) AS store_return_tickets
FROM cr_agg
JOIN household_demographics hd
     ON cr_agg.cr_refunded_hdemo_sk = hd.hd_demo_sk
JOIN ship_mode sm
     ON cr_agg.cr_ship_mode_sk = sm.sm_ship_mode_sk
JOIN store_returns sr
     ON sr.sr_hdemo_sk = hd.hd_demo_sk
WHERE sm.sm_code = 'AIR'                                           -- only air shipments
  AND hd.hd_vehicle_count >= 1                                     -- households with at least one vehicle
  AND sr.sr_returned_date_sk BETWEEN 2450000 AND 2450500           -- same date window for store returns
  AND sr.sr_return_quantity > 0                                    -- positive store return quantity
GROUP BY
    hd.hd_buy_potential,
    sm.sm_ship_mode_id,
    cr_agg.cr_returned_date_sk,
    cr_agg.total_return_amount,
    cr_agg.cnt_returns
HAVING SUM(sr.sr_return_amt) > 1000                               -- retain only high store‑return value groups
ORDER BY cr_agg.total_return_amount DESC
LIMIT 100
