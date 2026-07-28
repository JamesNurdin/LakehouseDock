WITH filtered AS (
    SELECT
        sr.sr_customer_sk,
        sr.sr_return_amt,
        sr.sr_return_ship_cost,
        sr.sr_return_quantity,
        hd.hd_vehicle_count,
        hd.hd_dep_count,
        hd.hd_buy_potential,
        ca.ca_state,
        ca.ca_city,
        ca.ca_suite_number,
        ca.ca_zip
    FROM store_returns sr
    JOIN household_demographics hd
        ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca
        ON sr.sr_addr_sk = ca.ca_address_sk
    WHERE sr.sr_return_ship_cost > 0
      AND hd.hd_vehicle_count >= 1
      AND ca.ca_suite_number LIKE 'Suite %'
      AND hd.hd_buy_potential = '0-500'
),
state_metrics AS (
    SELECT
        ca_state AS region,
        'state' AS region_type,
        COUNT(*) AS returns_cnt,
        SUM(sr_return_amt) AS total_return_amt,
        AVG(sr_return_amt) AS avg_return_amt,
        ROW_NUMBER() OVER (ORDER BY AVG(sr_return_amt) DESC) AS rank_num
    FROM filtered
    GROUP BY ca_state
),
city_metrics AS (
    SELECT
        ca_city AS region,
        'city' AS region_type,
        COUNT(*) AS returns_cnt,
        SUM(sr_return_amt) AS total_return_amt,
        AVG(sr_return_amt) AS avg_return_amt,
        ROW_NUMBER() OVER (ORDER BY AVG(sr_return_amt) DESC) AS rank_num
    FROM filtered
    GROUP BY ca_city
)
SELECT DISTINCT
    region,
    region_type,
    returns_cnt,
    total_return_amt,
    avg_return_amt,
    rank_num
FROM (
    SELECT region, region_type, returns_cnt, total_return_amt, avg_return_amt, rank_num
    FROM state_metrics
    UNION ALL
    SELECT region, region_type, returns_cnt, total_return_amt, avg_return_amt, rank_num
    FROM city_metrics
) combined
WHERE returns_cnt > 5
ORDER BY rank_num, region_type, region
