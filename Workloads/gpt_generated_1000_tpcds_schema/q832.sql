WITH sampled_returns AS (
    SELECT sr_returned_date_sk, sr_return_time_sk, sr_item_sk, sr_customer_sk, sr_cdemo_sk,
           sr_hdemo_sk, sr_addr_sk, sr_store_sk, sr_reason_sk, sr_ticket_number,
           sr_return_quantity, sr_return_amt, sr_return_tax, sr_return_amt_inc_tax,
           sr_fee, sr_return_ship_cost, sr_refunded_cash, sr_reversed_charge,
           sr_store_credit, sr_net_loss
    FROM store_returns TABLESAMPLE BERNOULLI (10)
    WHERE sr_return_amt > 100
),
filtered_returns AS (
    SELECT sr_hdemo_sk, sr_reason_sk, sr_return_quantity, sr_return_amt, sr_return_amt_inc_tax,
           sr_fee, sr_refunded_cash, sr_reversed_charge, sr_net_loss
    FROM sampled_returns
    WHERE sr_fee > (SELECT AVG(sr_fee) FROM store_returns WHERE sr_fee IS NOT NULL)
      AND sr_return_quantity >= 2
      AND sr_return_amt_inc_tax BETWEEN 50 AND 500
      AND sr_refunded_cash < 200
      AND sr_reversed_charge = 0.61
),
joined AS (
    SELECT hd.hd_demo_sk,
           hd.hd_buy_potential,
           hd.hd_dep_count,
           hd.hd_vehicle_count,
           r.r_reason_sk,
           r.r_reason_id,
           r.r_reason_desc,
           fr.sr_return_quantity,
           fr.sr_return_amt,
           fr.sr_fee,
           fr.sr_refunded_cash,
           fr.sr_net_loss
    FROM filtered_returns fr
    JOIN household_demographics hd
      ON fr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN reason r
      ON fr.sr_reason_sk = r.r_reason_sk
    WHERE hd.hd_vehicle_count >= 0
      AND hd.hd_buy_potential = '>10000         '
),
agg1 AS (
    SELECT
        hd_demo_sk,
        hd_buy_potential,
        r_reason_desc,
        COUNT(*) AS return_cnt,
        SUM(sr_return_amt) AS total_return_amt,
        AVG(sr_fee) AS avg_fee,
        MIN(sr_net_loss) AS min_net_loss,
        MAX(sr_refunded_cash) AS max_refunded_cash
    FROM joined
    GROUP BY hd_demo_sk, hd_buy_potential, r_reason_desc
    HAVING COUNT(*) > 5
),
agg2 AS (
    SELECT
        hd_demo_sk,
        hd_buy_potential,
        r_reason_desc,
        COUNT(*) AS return_cnt,
        SUM(sr_return_amt) AS total_return_amt,
        AVG(sr_fee) AS avg_fee,
        MIN(sr_net_loss) AS min_net_loss,
        MAX(sr_refunded_cash) AS max_refunded_cash
    FROM joined
    WHERE r_reason_id = 'AAAAAAAACAAAAAAA'
    GROUP BY hd_demo_sk, hd_buy_potential, r_reason_desc
    HAVING COUNT(*) > 2
)
SELECT *
FROM agg1
EXCEPT
SELECT *
FROM agg2
ORDER BY total_return_amt DESC
LIMIT 100
