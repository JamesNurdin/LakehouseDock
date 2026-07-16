WITH store_returns_summary AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        s.s_tax_percentage,
        COUNT(*) AS total_returns,
        SUM(sr.sr_return_amt) AS total_return_amount,
        SUM(sr.sr_net_loss) AS total_net_loss,
        AVG(sr.sr_return_amt) AS avg_return_amount,
        SUM(sr.sr_return_quantity) AS total_return_quantity,
        AVG(sr.sr_return_quantity) AS avg_return_quantity,
        SUM(CASE WHEN sr.sr_return_quantity >= 5 THEN 1 ELSE 0 END) AS high_qty_return_cnt
    FROM store s
    JOIN store_returns sr
        ON s.s_store_sk = sr.sr_store_sk
    WHERE s.s_tax_percentage > 0.06
      AND s.s_closed_date_sk > 2451000
      AND s.s_suite_number LIKE 'Suite %'
      AND sr.sr_return_amt > 20
    GROUP BY s.s_store_id, s.s_store_name, s.s_tax_percentage
    HAVING COUNT(*) >= 10
)
SELECT
    srs.s_store_id,
    srs.s_store_name,
    srs.s_tax_percentage,
    srs.total_returns,
    srs.total_return_amount,
    srs.total_net_loss,
    srs.avg_return_amount,
    srs.total_return_quantity,
    srs.avg_return_quantity,
    srs.high_qty_return_cnt,
    ROW_NUMBER() OVER (ORDER BY srs.total_net_loss DESC) AS loss_rank,
    ROUND(srs.high_qty_return_cnt * 100.0 / srs.total_returns, 2) AS high_qty_return_pct
FROM store_returns_summary srs
ORDER BY loss_rank
LIMIT 10
