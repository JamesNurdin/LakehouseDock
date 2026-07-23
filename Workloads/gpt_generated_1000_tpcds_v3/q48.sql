WITH filtered_returns AS (
    SELECT
        wr.wr_returned_date_sk,
        wr.wr_return_quantity,
        wr.wr_return_amt,
        wr.wr_return_tax,
        wr.wr_return_ship_cost,
        wr.wr_account_credit,
        wr.wr_net_loss,
        wr.wr_item_sk
    FROM web_returns wr
    WHERE wr.wr_return_ship_cost > 100
      AND wr.wr_return_tax <= 50
      AND wr.wr_account_credit BETWEEN 30 AND 100
      AND wr.wr_return_quantity > 0
      AND wr.wr_return_amt > 0
),
agg_returns AS (
    SELECT
        fr.wr_returned_date_sk,
        COUNT(DISTINCT fr.wr_item_sk) AS distinct_items_returned,
        SUM(fr.wr_return_quantity) AS total_return_quantity,
        SUM(fr.wr_return_amt) AS total_return_amount,
        AVG(fr.wr_return_amt) AS avg_return_amount,
        SUM(fr.wr_net_loss) AS total_net_loss,
        SUM(CASE WHEN fr.wr_return_tax > 30 THEN fr.wr_return_amt ELSE 0 END) AS sum_return_amt_high_tax
    FROM filtered_returns fr
    GROUP BY fr.wr_returned_date_sk
)
SELECT
    d.d_date,
    d.d_year,
    d.d_month_seq,
    d.d_dow,
    CASE WHEN d.d_dow IN (6, 0) THEN 'Weekend' ELSE 'Weekday' END AS day_type,
    ar.distinct_items_returned,
    ar.total_return_quantity,
    ar.total_return_amount,
    ar.avg_return_amount,
    ar.total_net_loss,
    ar.sum_return_amt_high_tax,
    (SELECT AVG(wr2.wr_return_amt) FROM web_returns wr2 WHERE wr2.wr_return_ship_cost > 200) AS overall_avg_return_amt_high_ship
FROM agg_returns ar
JOIN date_dim d
    ON ar.wr_returned_date_sk = d.d_date_sk
WHERE d.d_year = 2000
  AND d.d_month_seq BETWEEN 1200 AND 1220
  AND d.d_dow IN (1, 3, 5)
  AND d.d_date_id = 'AAAAAAAAELJNECAA'
ORDER BY d.d_date DESC
LIMIT 100
