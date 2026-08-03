WITH catalog_items AS (
        SELECT DISTINCT cr.cr_item_sk AS item_sk
        FROM catalog_returns cr
        JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
        WHERE d.d_year = 2001
    ),
    web_items AS (
        SELECT DISTINCT wr.wr_item_sk AS item_sk
        FROM web_returns wr
        JOIN date_dim d2 ON wr.wr_returned_date_sk = d2.d_date_sk
        WHERE d2.d_year = 2001
    ),
    common_items AS (
        SELECT item_sk FROM catalog_items INTERSECT SELECT item_sk FROM web_items
    ),
    exclusive_catalog_items AS (
        SELECT item_sk FROM catalog_items EXCEPT SELECT item_sk FROM web_items
    )
SELECT
    cd.cd_gender,
    CASE WHEN cd.cd_purchase_estimate > 5000 THEN 'High' ELSE 'Low' END AS purchase_segment,
    COUNT(DISTINCT cr.cr_order_number) AS distinct_orders,
    SUM(cr.cr_return_amount) AS total_return_amount,
    RANK() OVER (PARTITION BY d.d_year ORDER BY SUM(cr.cr_return_amount) DESC) AS revenue_rank,
    ci.item_sk AS common_item_sk,
    eci.item_sk AS exclusive_catalog_item_sk
FROM catalog_returns cr
JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
JOIN item i ON cr.cr_item_sk = i.i_item_sk
JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
JOIN customer_demographics cd ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
JOIN store s ON d.d_date_sk = s.s_closed_date_sk
JOIN promotion p ON i.i_item_sk = p.p_item_sk
    AND d.d_date_sk BETWEEN p.p_start_date_sk AND p.p_end_date_sk
JOIN inventory inv ON inv.inv_date_sk = d.d_date_sk AND inv.inv_item_sk = i.i_item_sk
JOIN web_returns wr ON cr.cr_item_sk = wr.wr_item_sk AND cr.cr_returned_date_sk = wr.wr_returned_date_sk
JOIN web_site ws ON ws.web_open_date_sk = d.d_date_sk
JOIN common_items ci ON cr.cr_item_sk = ci.item_sk
LEFT JOIN exclusive_catalog_items eci ON cr.cr_item_sk = eci.item_sk
WHERE d.d_year = 2001
GROUP BY
    cd.cd_gender,
    CASE WHEN cd.cd_purchase_estimate > 5000 THEN 'High' ELSE 'Low' END,
    d.d_year,
    ci.item_sk,
    eci.item_sk
HAVING COUNT(*) > 10
ORDER BY total_return_amount DESC
LIMIT 100
