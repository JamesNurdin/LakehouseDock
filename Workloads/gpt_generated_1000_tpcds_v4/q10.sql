WITH returns_with_color AS (
    SELECT
        cr.cr_returned_date_sk AS returned_date_sk,
        w.w_city AS warehouse_city,
        r.r_reason_desc AS reason_desc,
        cr.cr_net_loss AS net_loss,
        CASE WHEN cr.cr_return_amount > 100 THEN 'High' ELSE 'Low' END AS amount_category
    FROM catalog_returns AS cr
    JOIN reason AS r
        ON cr.cr_reason_sk = r.r_reason_sk
    JOIN warehouse AS w
        ON cr.cr_warehouse_sk = w.w_warehouse_sk
    WHERE r.r_reason_desc LIKE '%color%'
),
returns_in_liberty AS (
    SELECT
        cr.cr_returned_date_sk AS returned_date_sk,
        w.w_city AS warehouse_city,
        r.r_reason_desc AS reason_desc,
        cr.cr_net_loss AS net_loss,
        CASE WHEN cr.cr_return_amount > 100 THEN 'High' ELSE 'Low' END AS amount_category
    FROM catalog_returns AS cr
    JOIN reason AS r
        ON cr.cr_reason_sk = r.r_reason_sk
    JOIN warehouse AS w
        ON cr.cr_warehouse_sk = w.w_warehouse_sk
    WHERE w.w_city = 'Liberty'
)
SELECT * FROM returns_with_color
UNION ALL
SELECT * FROM returns_in_liberty
ORDER BY net_loss DESC, warehouse_city ASC
LIMIT 100
