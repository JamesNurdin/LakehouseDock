WITH wr_agg AS (
    SELECT
        wr_reason_sk,
        COUNT(*) AS return_cnt,
        SUM(wr_return_amt_inc_tax) AS total_return_inc_tax,
        AVG(wr_net_loss) AS avg_net_loss,
        MIN(wr_return_ship_cost) AS min_ship_cost,
        MAX(wr_return_ship_cost) AS max_ship_cost
    FROM web_returns
    WHERE
        wr_return_quantity > 0
        AND wr_return_amt >= 50.00
        AND wr_return_ship_cost < 1500.00
        AND wr_reversed_charge BETWEEN 10.00 AND 200.00
        AND wr_returning_customer_sk IN (10283268, 2924635, 7912544)
        AND wr_returning_addr_sk > 0
    GROUP BY wr_reason_sk
)
SELECT
    r.r_reason_id,
    r.r_reason_desc,
    a.return_cnt,
    a.total_return_inc_tax,
    a.avg_net_loss,
    a.min_ship_cost,
    a.max_ship_cost,
    CASE
        WHEN a.avg_net_loss > 100 THEN 'High'
        WHEN a.avg_net_loss > 50 THEN 'Medium'
        ELSE 'Low'
    END AS loss_category,
    (
        SELECT AVG(wr_return_amt)
        FROM web_returns
        WHERE wr_reason_sk = r.r_reason_sk
    ) AS overall_avg_return_amt
FROM wr_agg a
JOIN reason r
    ON a.wr_reason_sk = r.r_reason_sk
WHERE
    r.r_reason_desc LIKE '%damaged%'
    AND r.r_reason_id = 'AAAAAAAAABAAAAAA'
    AND EXISTS (
        SELECT 1
        FROM reason r2
        WHERE r2.r_reason_sk = a.wr_reason_sk
          AND r2.r_reason_desc LIKE '%Package%'
    )
ORDER BY a.total_return_inc_tax DESC
LIMIT 100
