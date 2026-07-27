WITH per_warehouse AS (
    SELECT
        w.w_warehouse_sk,
        i.i_size,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_return_quantity) AS total_quantity,
        AVG(cr.cr_return_tax) AS avg_tax,
        SUM(cr.cr_reversed_charge) AS total_rev_charge,
        CASE WHEN SUM(cr.cr_net_loss) > 1000 THEN 'HIGH' ELSE 'LOW' END AS loss_category
    FROM
        tpcds.catalog_returns cr
        JOIN tpcds.item i ON cr.cr_item_sk = i.i_item_sk
        JOIN tpcds.warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    WHERE
        w.w_country = 'United States'
        AND w.w_state = 'CA'
        AND i.i_size IN ('small', 'medium', 'extra large')
        AND cr.cr_return_amount > 20
        AND cr.cr_return_quantity >= 1
    GROUP BY
        w.w_warehouse_sk,
        i.i_size
),
max_us_warehouse AS (
    SELECT MAX(w2.w_warehouse_sq_ft) AS max_sq_ft
    FROM tpcds.warehouse w2
    WHERE w2.w_country = 'United States'
)
SELECT
    pc.loss_category,
    AVG(pc.total_return_amount) AS avg_return_amount,
    COUNT(DISTINCT pc.w_warehouse_sk) AS warehouse_cnt,
    mu.max_sq_ft AS max_us_warehouse_sqft
FROM
    per_warehouse pc,
    max_us_warehouse mu
GROUP BY
    pc.loss_category,
    mu.max_sq_ft
HAVING
    AVG(pc.total_return_amount) > 100
ORDER BY
    avg_return_amount DESC
LIMIT 100
