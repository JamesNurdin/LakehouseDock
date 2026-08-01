WITH
    base_agg AS (
        SELECT
            hd.hd_demo_sk,
            hd.hd_buy_potential,
            hd.hd_vehicle_count,
            SUM(sr.sr_return_amt) AS total_return_amt,
            AVG(sr.sr_return_ship_cost) AS avg_ship_cost,
            COUNT(*) AS cnt_returns
        FROM store_returns sr
        JOIN household_demographics hd
            ON sr.sr_hdemo_sk = hd.hd_demo_sk
        WHERE
            sr.sr_return_amt > 100
            AND sr.sr_return_ship_cost BETWEEN 10 AND 800
            AND sr.sr_reversed_charge < 20
            AND hd.hd_dep_count >= 2
            AND hd.hd_vehicle_count <= 5
            AND hd.hd_buy_potential IN ('0-500', '501-1000', '1001-5000')
        GROUP BY hd.hd_demo_sk, hd.hd_buy_potential, hd.hd_vehicle_count
    ),
    union_set AS (
        SELECT hd_demo_sk, total_return_amt FROM base_agg WHERE total_return_amt > 500
        UNION
        SELECT hd_demo_sk, total_return_amt FROM base_agg WHERE cnt_returns > 10
    ),
    intersect_set AS (
        SELECT hd_demo_sk FROM base_agg WHERE hd_vehicle_count = 0
        INTERSECT
        SELECT sr.sr_hdemo_sk FROM store_returns sr WHERE sr.sr_return_quantity > 5
    ),
    except_set AS (
        SELECT hd_demo_sk FROM household_demographics
        EXCEPT
        SELECT sr_hdemo_sk FROM store_returns
    ),
    final AS (
        SELECT
            b.hd_demo_sk,
            b.hd_buy_potential,
            b.hd_vehicle_count,
            b.total_return_amt,
            b.avg_ship_cost,
            (
                SELECT SUM(sr2.sr_return_amt)
                FROM store_returns sr2
                WHERE sr2.sr_hdemo_sk = b.hd_demo_sk
            ) AS total_return_amt_all_time,
            LAG(b.total_return_amt) OVER (PARTITION BY b.hd_buy_potential ORDER BY b.total_return_amt DESC) AS lag_return_amt
        FROM base_agg b
        WHERE EXISTS (
            SELECT 1 FROM store_returns sr3
            WHERE sr3.sr_hdemo_sk = b.hd_demo_sk
              AND sr3.sr_return_quantity > 2
        )
    )
SELECT
    f.hd_buy_potential,
    COUNT(DISTINCT f.hd_vehicle_count) AS vehicle_count_variants,
    SUM(f.total_return_amt) AS sum_total_return,
    AVG(f.lag_return_amt) AS avg_lag_return,
    (SELECT COUNT(*) FROM intersect_set) AS intersect_cnt,
    (SELECT COUNT(*) FROM except_set) AS except_cnt
FROM final f
WHERE f.total_return_amt > 200
GROUP BY f.hd_buy_potential
HAVING SUM(f.total_return_amt) > 1000
ORDER BY sum_total_return DESC
LIMIT 10
