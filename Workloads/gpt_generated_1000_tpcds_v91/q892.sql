WITH agg_by_year_ship AS (
    SELECT
        d.d_year,
        COALESCE(sm.sm_ship_mode_id, 'UNKNOWN') AS ship_mode_id,
        ws.web_company_id,
        COUNT(*) AS return_cnt,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_return_quantity) AS total_return_quantity,
        SUM(CASE WHEN cr.cr_return_quantity > 10 THEN cr.cr_return_amount ELSE 0 END) AS sum_large_qty_returns,
        SUM(cr.cr_net_loss) AS total_net_loss,
        SUM(COALESCE(inv.inv_quantity_on_hand, 0)) AS total_quantity_on_hand,
        CASE WHEN SUM(cr.cr_net_loss) > 1000 THEN 'HighLoss' ELSE 'LowLoss' END AS loss_category
    FROM
        tpcds.catalog_returns cr
        INNER JOIN tpcds.date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
        LEFT JOIN tpcds.ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
        LEFT JOIN tpcds.inventory inv ON inv.inv_date_sk = d.d_date_sk
        INNER JOIN tpcds.web_site ws ON ws.web_open_date_sk = d.d_date_sk
    WHERE
        d.d_year = 2001
        AND d.d_fy_week_seq >= 10
        AND cr.cr_return_quantity > 5
        AND ws.web_company_id IN (1, 2, 3)
        AND cr.cr_order_number NOT IN (
            SELECT cr2.cr_order_number
            FROM tpcds.catalog_returns cr2
            WHERE cr2.cr_return_amount > 2000
        )
    GROUP BY
        d.d_year,
        sm.sm_ship_mode_id,
        ws.web_company_id
)
SELECT
    a.d_year,
    AVG(a.total_return_amount) AS avg_return_amount,
    SUM(a.return_cnt) AS total_returns,
    SUM(a.total_net_loss) AS total_net_loss,
    SUM(a.total_quantity_on_hand) AS total_quantity_on_hand_year,
    CASE WHEN SUM(a.total_net_loss) > 5000 THEN 'Critical' ELSE 'Normal' END AS year_loss_severity
FROM
    agg_by_year_ship a
GROUP BY
    a.d_year
HAVING
    AVG(a.total_return_amount) > 500
ORDER BY
    avg_return_amount DESC
LIMIT 100
