WITH store_returns_agg AS (
    SELECT
        sr_store_sk,
        SUM(sr_return_quantity) AS total_return_qty,
        SUM(sr_return_amt_inc_tax) AS total_return_amt_inc_tax,
        SUM(sr_net_loss) AS total_net_loss,
        COUNT(*) AS return_transactions
    FROM store_returns
    GROUP BY sr_store_sk
)
SELECT
    s.s_store_id,
    s.s_store_name,
    s.s_city,
    s.s_state,
    sr_agg.total_return_qty,
    sr_agg.total_return_amt_inc_tax,
    sr_agg.total_net_loss,
    sr_agg.return_transactions,
    (sr_agg.total_return_amt_inc_tax / NULLIF(sr_agg.return_transactions, 0)) AS avg_return_amt_inc_tax,
    (sr_agg.total_net_loss / NULLIF(sr_agg.total_return_qty, 0)) AS avg_net_loss_per_qty,
    RANK() OVER (ORDER BY sr_agg.total_net_loss DESC) AS net_loss_rank
FROM store s
JOIN store_returns_agg sr_agg
    ON sr_agg.sr_store_sk = s.s_store_sk
WHERE s.s_closed_date_sk IS NULL
ORDER BY sr_agg.total_net_loss DESC
LIMIT 20
