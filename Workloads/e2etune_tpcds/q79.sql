WITH combined_returns AS (
    SELECT
        cr.cr_item_sk AS item_sk,
        cr.cr_returning_cdemo_sk AS demo_sk,
        cr.cr_reason_sk AS reason_sk,
        cr.cr_return_amount AS return_amount,
        cr.cr_return_quantity AS return_quantity,
        cr.cr_return_tax AS return_tax,
        cr.cr_net_loss AS net_loss,
        cr.cr_fee AS fee,
        cr.cr_returned_date_sk AS returned_date_sk,
        'catalog' AS channel
    FROM catalog_returns cr
    WHERE cr.cr_returned_date_sk BETWEEN 2450000 AND 2459999
      AND cr.cr_return_quantity > 10
    UNION ALL
    SELECT
        wr.wr_item_sk AS item_sk,
        wr.wr_returning_cdemo_sk AS demo_sk,
        wr.wr_reason_sk AS reason_sk,
        wr.wr_return_amt AS return_amount,
        wr.wr_return_quantity AS return_quantity,
        wr.wr_return_tax AS return_tax,
        wr.wr_net_loss AS net_loss,
        wr.wr_fee AS fee,
        wr.wr_returned_date_sk AS returned_date_sk,
        'web' AS channel
    FROM web_returns wr
    WHERE wr.wr_returned_date_sk BETWEEN 2450000 AND 2459999
      AND wr.wr_return_quantity > 10
),
aggregated AS (
    SELECT
        i.i_category AS category,
        cd.cd_gender AS gender,
        r.r_reason_desc AS return_reason,
        cr.channel,
        COUNT(*) AS return_events,
        SUM(cr.return_amount) AS total_return_amount,
        SUM(cr.return_quantity) AS total_return_quantity,
        AVG(cr.return_tax) AS avg_return_tax,
        SUM(cr.net_loss) AS total_net_loss,
        SUM(cr.fee) AS total_fee,
        COALESCE(SUM(inv.inv_quantity_on_hand), 0) AS total_inventory_on_hand
    FROM combined_returns cr
    JOIN item i ON cr.item_sk = i.i_item_sk
    JOIN customer_demographics cd ON cr.demo_sk = cd.cd_demo_sk
    JOIN reason r ON cr.reason_sk = r.r_reason_sk
    LEFT JOIN inventory inv ON i.i_item_sk = inv.inv_item_sk
    WHERE i.i_category IS NOT NULL
    GROUP BY
        i.i_category,
        cd.cd_gender,
        r.r_reason_desc,
        cr.channel
    HAVING SUM(cr.return_amount) > 100
)
SELECT
    a.*,
    RANK() OVER (PARTITION BY a.channel ORDER BY a.total_return_amount DESC) AS amount_rank_by_channel
FROM aggregated a
ORDER BY a.total_return_amount DESC
LIMIT 100
