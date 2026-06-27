WITH page_returns AS (
    SELECT
        cr.cr_catalog_page_sk,
        sum(cr.cr_return_amount) AS sum_return_amount,
        sum(cr.cr_net_loss) AS sum_net_loss,
        avg(cr.cr_return_quantity) AS avg_return_quantity,
        count(*) AS return_cnt
    FROM
        catalog_returns cr
    WHERE
        cr.cr_return_amount > 0
    GROUP BY
        cr.cr_catalog_page_sk
)
SELECT
    cp.cp_department,
    cp.cp_type,
    cp.cp_catalog_page_number,
    pr.sum_return_amount,
    pr.sum_net_loss,
    pr.avg_return_quantity,
    pr.return_cnt,
    rank() OVER (PARTITION BY cp.cp_department ORDER BY pr.sum_net_loss DESC) AS dept_loss_rank
FROM
    catalog_page cp
JOIN
    page_returns pr
        ON pr.cr_catalog_page_sk = cp.cp_catalog_page_sk
WHERE
    cp.cp_department IS NOT NULL
ORDER BY
    pr.sum_net_loss DESC
LIMIT 100
