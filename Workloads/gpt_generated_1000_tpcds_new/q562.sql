WITH base AS (
    SELECT sr.sr_hdemo_sk,
           sr.sr_item_sk,
           sr.sr_return_amt,
           sr.sr_return_quantity,
           i.i_item_id,
           i.i_units,
           i.i_product_name,
           hd.hd_buy_potential,
           hd.hd_vehicle_count
    FROM   store_returns sr
    JOIN   item i ON sr.sr_item_sk = i.i_item_sk
    JOIN   household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    WHERE  regexp_like(i.i_product_name, '^.*[A-Z]{3}.*$')
      AND  LOWER(i.i_units) LIKE '%p%'
),

lateral_enhanced AS (
    SELECT b.*, l.extracted_number,
           (SELECT sum(sr2.sr_return_amt)
            FROM   store_returns sr2
            WHERE  sr2.sr_item_sk = b.sr_item_sk) AS total_item_return_amt
    FROM   base b
    CROSS JOIN LATERAL (
        SELECT regexp_extract(b.i_product_name, '(\\d+)', 1) AS extracted_number
    ) AS l
),

agg_all AS (
    SELECT hd_buy_potential,
           COUNT(DISTINCT i_item_id) AS unique_items,
           SUM(sr_return_amt)       AS total_return_amt,
           SUM(total_item_return_amt) AS total_item_return_sum
    FROM   lateral_enhanced
    GROUP BY hd_buy_potential
),

agg_vehicle AS (
    SELECT hd_buy_potential,
           COUNT(DISTINCT i_item_id) AS unique_items,
           SUM(sr_return_amt)       AS total_return_amt,
           SUM(total_item_return_amt) AS total_item_return_sum
    FROM   lateral_enhanced
    WHERE  hd_vehicle_count > 0
    GROUP BY hd_buy_potential
),

intersected_keys AS (
    SELECT hd_buy_potential FROM agg_all
    INTERSECT
    SELECT hd_buy_potential FROM agg_vehicle
),

unioned_agg AS (
    SELECT hd_buy_potential, unique_items, total_return_amt FROM agg_all
    UNION
    SELECT hd_buy_potential, unique_items, total_return_amt FROM agg_vehicle
),

sum_item_return AS (
    SELECT hd_buy_potential,
           SUM(total_item_return_sum) AS total_item_return_sum
    FROM (
        SELECT hd_buy_potential, total_item_return_sum FROM agg_all
        UNION ALL
        SELECT hd_buy_potential, total_item_return_sum FROM agg_vehicle
    ) t
    GROUP BY hd_buy_potential
)
SELECT DISTINCT ua.hd_buy_potential,
                ua.unique_items,
                ua.total_return_amt,
                sir.total_item_return_sum
FROM   unioned_agg ua
JOIN   sum_item_return sir ON ua.hd_buy_potential = sir.hd_buy_potential
WHERE  ua.hd_buy_potential IN (SELECT hd_buy_potential FROM intersected_keys)
ORDER BY ua.total_return_amt DESC
LIMIT 100
