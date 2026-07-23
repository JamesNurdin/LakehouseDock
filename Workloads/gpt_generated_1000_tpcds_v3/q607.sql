WITH recent_dates AS (
    SELECT d_date_sk
    FROM date_dim
    WHERE d_year = 2001
)
SELECT
    item_id,
    item_desc,
    source,
    total_return_qty,
    total_return_amt,
    avg_net_loss,
    CASE WHEN avg_net_loss > overall_avg_net_loss THEN 'High Loss' ELSE 'Low Loss' END AS loss_category
FROM (
    SELECT
        i.i_item_id AS item_id,
        i.i_item_desc AS item_desc,
        'Store' AS source,
        SUM(sr.sr_return_quantity) AS total_return_qty,
        SUM(sr.sr_return_amt) AS total_return_amt,
        AVG(sr.sr_net_loss) AS avg_net_loss,
        (SELECT AVG(sr2.sr_net_loss) FROM store_returns sr2 WHERE sr2.sr_returned_date_sk IN (SELECT d_date_sk FROM recent_dates)) AS overall_avg_net_loss
    FROM store_returns sr
    JOIN recent_dates rd ON sr.sr_returned_date_sk = rd.d_date_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
    WHERE EXISTS (
        SELECT 1
        FROM promotion p
        JOIN date_dim d ON p.p_start_date_sk = d.d_date_sk
        WHERE p.p_item_sk = i.i_item_sk
          AND d.d_date_sk = sr.sr_returned_date_sk
          AND p.p_discount_active = 'Y'
    )
    GROUP BY i.i_item_id, i.i_item_desc
    UNION ALL
    SELECT
        i.i_item_id AS item_id,
        i.i_item_desc AS item_desc,
        'Web' AS source,
        SUM(wr.wr_return_quantity) AS total_return_qty,
        SUM(wr.wr_return_amt) AS total_return_amt,
        AVG(wr.wr_net_loss) AS avg_net_loss,
        (SELECT AVG(wr2.wr_net_loss) FROM web_returns wr2 WHERE wr2.wr_returned_date_sk IN (SELECT d_date_sk FROM recent_dates)) AS overall_avg_net_loss
    FROM web_returns wr
    JOIN recent_dates rd ON wr.wr_returned_date_sk = rd.d_date_sk
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    JOIN customer_demographics cd ON wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
    WHERE EXISTS (
        SELECT 1
        FROM promotion p
        JOIN date_dim d ON p.p_start_date_sk = d.d_date_sk
        WHERE p.p_item_sk = i.i_item_sk
          AND d.d_date_sk = wr.wr_returned_date_sk
          AND p.p_discount_active = 'Y'
    )
    GROUP BY i.i_item_id, i.i_item_desc
) AS combined
ORDER BY total_return_amt DESC
LIMIT 100
