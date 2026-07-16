WITH store_return_agg AS (
    SELECT
        sr_store_sk,
        SUM(sr_return_amt_inc_tax) AS total_return_amt_inc_tax,
        SUM(sr_net_loss) AS total_net_loss,
        SUM(sr_return_quantity) AS total_return_qty,
        AVG(sr_net_loss) AS avg_net_loss,
        SUM(sr_store_credit) AS total_store_credit
    FROM store_returns
    WHERE sr_returned_date_sk BETWEEN 2450000 AND 2452000
      AND sr_return_quantity > 1
    GROUP BY sr_store_sk
    HAVING SUM(sr_return_amt_inc_tax) > 10000
)
SELECT
    s.s_store_id,
    s.s_store_name,
    s.s_city,
    s.s_state,
    s.s_geography_class,
    s.s_market_id,
    a.total_return_amt_inc_tax,
    a.total_net_loss,
    a.total_return_qty,
    a.avg_net_loss,
    a.total_store_credit,
    (a.total_net_loss / NULLIF(a.total_return_amt_inc_tax, 0)) * 100 AS net_loss_pct,
    RANK() OVER (ORDER BY a.total_return_amt_inc_tax DESC) AS store_rank
FROM store_return_agg a
JOIN store s ON a.sr_store_sk = s.s_store_sk
WHERE s.s_state = 'CA'
ORDER BY a.total_return_amt_inc_tax DESC
LIMIT 10
