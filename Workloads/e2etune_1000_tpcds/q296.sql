WITH return_agg AS (
    SELECT
        w.w_city,
        sm.sm_carrier,
        COUNT(*) AS total_returns,
        SUM(wr.wr_return_amt) AS total_return_amount,
        AVG(wr.wr_return_quantity) AS avg_return_qty,
        approx_percentile(wr.wr_return_amt, 0.5) AS median_return_amt
    FROM
        web_returns wr
        JOIN ship_mode sm ON sm.sm_ship_mode_sk = ((wr.wr_item_sk % 5) + 1)
        JOIN warehouse w ON w.w_warehouse_sk = ((wr.wr_returning_addr_sk % 10) + 1)
    WHERE
        w.w_state = 'CA'
        AND sm.sm_type IN ('EXPRESS', 'OVERNIGHT')
        AND wr.wr_returned_date_sk BETWEEN 20230101 AND 20231231
    GROUP BY
        w.w_city,
        sm.sm_carrier
    HAVING
        SUM(wr.wr_return_amt) > 10000
)
SELECT
    r.w_city,
    r.sm_carrier,
    r.total_returns,
    r.total_return_amount,
    r.avg_return_qty,
    r.median_return_amt,
    RANK() OVER (ORDER BY r.total_return_amount DESC) AS revenue_rank
FROM
    return_agg r
ORDER BY
    r.total_return_amount DESC
LIMIT 50
