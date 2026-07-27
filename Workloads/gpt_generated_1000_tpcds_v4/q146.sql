WITH high_ship_cost_stores AS (
    SELECT DISTINCT sr_store_sk
    FROM store_returns
    WHERE sr_return_ship_cost > 300.00
),
filtered_returns AS (
    SELECT sr.*
    FROM store_returns sr
    WHERE sr.sr_return_ship_cost > 20.00
      AND sr.sr_return_amt > 0
      AND sr.sr_store_sk IN (SELECT sr_store_sk FROM high_ship_cost_stores)
),
joined AS (
    SELECT
        s.s_store_sk,
        s.s_store_id,
        s.s_store_name,
        s.s_geography_class,
        s.s_gmt_offset,
        fr.sr_return_amt,
        fr.sr_return_quantity,
        td.t_hour,
        td.t_shift
    FROM filtered_returns fr
    JOIN store s
        ON fr.sr_store_sk = s.s_store_sk
    JOIN time_dim td
        ON fr.sr_return_time_sk = td.t_time_sk
    WHERE s.s_gmt_offset = -5.00
      AND td.t_hour BETWEEN 9 AND 17
      AND td.t_shift = 'first'
)
SELECT
    j.s_store_id,
    j.s_store_name,
    j.s_geography_class,
    SUM(j.sr_return_amt) AS total_return_amt,
    AVG(j.sr_return_amt) AS avg_return_amt,
    COUNT(*) AS return_cnt,
    MIN(j.sr_return_amt) AS min_return_amt,
    MAX(j.sr_return_amt) AS max_return_amt,
    (SELECT MAX(sr_return_amt) FROM store_returns) AS max_return_amt_overall,
    ROW_NUMBER() OVER (PARTITION BY j.s_geography_class ORDER BY SUM(j.sr_return_amt) DESC) AS geo_rank
FROM joined j
GROUP BY
    j.s_store_id,
    j.s_store_name,
    j.s_geography_class
HAVING COUNT(*) >= 5
ORDER BY total_return_amt DESC, j.s_store_id
LIMIT 100
