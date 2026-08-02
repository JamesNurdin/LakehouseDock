WITH aggregated AS (
    SELECT
        COALESCE(wr.wr_returned_time_sk, td.t_time_sk) AS time_sk,
        SUM(wr.wr_return_amt) AS total_return_amt,
        SUM(wr.wr_return_tax) AS total_return_tax,
        COUNT(*) AS cnt_returns,
        CASE 
            WHEN wr.wr_return_ship_cost > 500 THEN 'HighShipCost'
            ELSE 'NormalShipCost'
        END AS ship_cost_category
    FROM web_returns wr
    FULL OUTER JOIN time_dim td
        ON wr.wr_returned_time_sk = td.t_time_sk
        AND td.t_minute IN (7, 8, 10, 11, 16)
        AND td.t_hour BETWEEN 8 AND 20
        AND td.t_am_pm = 'AM'
    WHERE
        (wr.wr_return_quantity > 0 OR wr.wr_return_quantity IS NULL)
        AND (wr.wr_return_ship_cost > 0 OR wr.wr_return_ship_cost IS NULL)
        AND (wr.wr_return_amt > 100 OR wr.wr_return_amt IS NULL)
        AND EXISTS (
            SELECT 1
            FROM time_dim t2
            WHERE t2.t_time_sk = wr.wr_returned_time_sk
              AND t2.t_second BETWEEN 0 AND 30
        )
    GROUP BY
        COALESCE(wr.wr_returned_time_sk, td.t_time_sk),
        CASE 
            WHEN wr.wr_return_ship_cost > 500 THEN 'HighShipCost'
            ELSE 'NormalShipCost'
        END
),
unioned AS (
    SELECT time_sk, total_return_amt, total_return_tax, cnt_returns, ship_cost_category
    FROM aggregated
    WHERE ship_cost_category = 'HighShipCost'
    UNION
    SELECT time_sk, total_return_amt, total_return_tax, cnt_returns, ship_cost_category
    FROM aggregated
    WHERE ship_cost_category = 'NormalShipCost' AND cnt_returns > 10
),
final AS (
    SELECT
        ship_cost_category,
        AVG(total_return_amt) AS avg_return_amt,
        SUM(cnt_returns) AS total_returns,
        MAX(total_return_tax) AS max_return_tax,
        COUNT(DISTINCT time_sk) AS distinct_time_keys
    FROM unioned
    GROUP BY ship_cost_category
    HAVING SUM(cnt_returns) > 20
)
SELECT
    f.ship_cost_category,
    f.avg_return_amt,
    f.total_returns,
    f.max_return_tax,
    f.distinct_time_keys,
    (
        SELECT COUNT(*)
        FROM web_returns wr2
        WHERE wr2.wr_returning_hdemo_sk = (
            SELECT MAX(wr3.wr_returning_hdemo_sk)
            FROM web_returns wr3
            WHERE wr3.wr_return_ship_cost > 500
        )
        AND wr2.wr_return_amt > f.avg_return_amt
    ) AS high_cost_high_amt_cnt
FROM final f
ORDER BY f.avg_return_amt DESC
LIMIT 100
