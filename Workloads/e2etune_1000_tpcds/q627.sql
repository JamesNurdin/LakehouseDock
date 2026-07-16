WITH cc_stats AS (
    SELECT
        cc_manager,
        cc_company,
        SUM(cc_employees) AS total_employees,
        AVG(cc_tax_percentage) AS avg_tax_pct,
        COUNT(*) AS cc_cnt
    FROM call_center
    WHERE cc_country = 'United States'
      AND cc_employees > 1000000
    GROUP BY cc_manager, cc_company
),
wr_stats AS (
    SELECT
        wr_reason_sk,
        SUM(wr_return_amt) AS total_return_amt,
        SUM(wr_net_loss) AS total_net_loss,
        COUNT(*) AS return_cnt,
        AVG(wr_return_quantity) AS avg_return_qty
    FROM web_returns
    WHERE wr_return_amt > 0
    GROUP BY wr_reason_sk
),
joined AS (
    SELECT
        cc.cc_manager,
        cc.cc_company,
        cc.total_employees,
        cc.avg_tax_pct,
        wr.wr_reason_sk,
        wr.total_return_amt,
        wr.total_net_loss,
        wr.return_cnt,
        CASE
            WHEN wr.total_return_amt >= 1000000 THEN 'HIGH'
            WHEN wr.total_return_amt >= 500000 THEN 'MEDIUM'
            ELSE 'LOW'
        END AS return_bucket
    FROM cc_stats cc
    JOIN wr_stats wr
      ON cc.cc_company = wr.wr_reason_sk
    WHERE cc.total_employees > 2000000
)
SELECT
    cc_manager AS manager,
    total_employees,
    avg_tax_pct,
    return_bucket,
    total_return_amt,
    total_net_loss,
    return_cnt,
    ROW_NUMBER() OVER (PARTITION BY cc_manager ORDER BY total_return_amt DESC) AS rn,
    SUM(total_return_amt) OVER (PARTITION BY cc_manager ORDER BY total_return_amt DESC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cum_return_amt
FROM joined
WHERE return_bucket <> 'LOW'
ORDER BY manager, total_return_amt DESC
LIMIT 50
