WITH sr_agg AS (
    SELECT
        sr_returned_date_sk AS date_sk,
        COUNT(*) AS total_returns,
        SUM(sr_return_amt) AS total_return_amount,
        SUM(sr_net_loss) AS total_net_loss,
        AVG(sr_return_quantity) AS avg_return_qty
    FROM store_returns
    WHERE sr_returned_date_sk IS NOT NULL
    GROUP BY sr_returned_date_sk
),
cc_agg AS (
    SELECT
        cc_open_date_sk AS date_sk,
        COUNT(*) AS total_call_centers,
        AVG(cc_tax_percentage) AS avg_tax_pct,
        SUM(cc_employees) AS total_employees,
        MAX(cc_gmt_offset) AS max_gmt_offset
    FROM call_center
    WHERE cc_open_date_sk IS NOT NULL
    GROUP BY cc_open_date_sk
)
SELECT
    sr.date_sk,
    sr.total_returns,
    sr.total_return_amount,
    sr.total_net_loss,
    sr.avg_return_qty,
    cc.total_call_centers,
    cc.avg_tax_pct,
    cc.total_employees,
    cc.max_gmt_offset,
    RANK() OVER (ORDER BY sr.total_return_amount DESC) AS return_amount_rank
FROM sr_agg sr
JOIN cc_agg cc ON sr.date_sk = cc.date_sk
WHERE sr.total_return_amount > 10000
ORDER BY sr.total_return_amount DESC
LIMIT 100
