WITH filtered_data AS (
    SELECT
        sr.sr_returned_date_sk,
        sr.sr_return_time_sk,
        sr.sr_item_sk,
        sr.sr_customer_sk,
        sr.sr_cdemo_sk,
        sr.sr_hdemo_sk,
        sr.sr_addr_sk,
        sr.sr_store_sk,
        sr.sr_reason_sk,
        sr.sr_ticket_number,
        sr.sr_return_quantity,
        sr.sr_return_amt,
        sr.sr_return_tax,
        sr.sr_return_amt_inc_tax,
        sr.sr_fee,
        sr.sr_return_ship_cost,
        sr.sr_refunded_cash,
        sr.sr_reversed_charge,
        sr.sr_store_credit,
        sr.sr_net_loss,
        hd.hd_demo_sk,
        hd.hd_income_band_sk,
        hd.hd_buy_potential,
        hd.hd_dep_count,
        hd.hd_vehicle_count
    FROM store_returns AS sr
    JOIN household_demographics AS hd
        ON sr.sr_hdemo_sk = hd.hd_demo_sk
    WHERE hd.hd_dep_count >= 1                                 -- predicate 1
      AND hd.hd_vehicle_count BETWEEN 1 AND 4                  -- predicate 2
      AND sr.sr_return_amt_inc_tax > 100.00                    -- predicate 3
      AND sr.sr_store_credit < 30.00                           -- predicate 4
      AND sr.sr_reversed_charge >= 50.00                       -- predicate 5
      AND sr.sr_return_quantity <= 5                           -- predicate 6
      AND sr.sr_return_quantity = (
            SELECT MIN(sr2.sr_return_quantity)
            FROM store_returns AS sr2
            WHERE sr2.sr_return_quantity > 0
        )                                                       -- predicate 7 (scalar subquery)
      AND EXISTS (
            SELECT 1
            FROM store_returns AS sr3
            WHERE sr3.sr_customer_sk = sr.sr_customer_sk
              AND sr3.sr_return_amt_inc_tax > sr.sr_return_amt_inc_tax
        )                                                       -- correlated EXISTS filter
),
scalar_cmp AS (
    SELECT MIN(sr_return_quantity) AS min_qty
    FROM store_returns
)
SELECT
    fd.hd_vehicle_count,
    fd.hd_dep_count,
    COUNT(DISTINCT fd.sr_ticket_number) AS num_tickets,
    SUM(fd.sr_return_amt_inc_tax) AS total_return_inc_tax,
    AVG(fd.sr_return_amt_inc_tax) AS avg_return_inc_tax,
    MIN(fd.sr_return_amt_inc_tax) AS min_return_inc_tax,
    MAX(fd.sr_return_amt_inc_tax) AS max_return_inc_tax,
    CASE WHEN SUM(fd.sr_return_amt_inc_tax) > 1000 THEN 'HIGH' ELSE 'LOW' END AS return_level
FROM filtered_data AS fd
GROUP BY ROLLUP (fd.hd_vehicle_count, fd.hd_dep_count)
HAVING SUM(fd.sr_return_amt_inc_tax) IS NOT NULL
ORDER BY total_return_inc_tax DESC
LIMIT 100
