SELECT
    d_return.d_year,
    d_return.d_moy AS month,
    s.s_store_name,
    wp.wp_type,
    d_wp_creation.d_year AS creation_year,
    d_wp_creation.d_moy AS creation_month,
    d_wp_access.d_year AS access_year,
    d_wp_access.d_moy AS access_month,
    SUM(cr.cr_net_loss) AS total_catalog_net_loss,
    SUM(wr.wr_net_loss) AS total_web_net_loss,
    COUNT(*) AS total_returns,
    COUNT(DISTINCT cr.cr_order_number) AS distinct_catalog_orders,
    COUNT(DISTINCT wr.wr_order_number) AS distinct_web_orders,
    AVG(cr.cr_return_quantity) AS avg_catalog_return_qty,
    AVG(wr.wr_return_quantity) AS avg_web_return_qty,
    SUM(cr.cr_return_amount) AS total_catalog_return_amount,
    SUM(wr.wr_return_amt_inc_tax) AS total_web_return_amount,
    CASE
        WHEN SUM(wr.wr_net_loss) = 0 THEN NULL
        ELSE SUM(cr.cr_net_loss) / SUM(wr.wr_net_loss)
    END AS catalog_to_web_loss_ratio,
    SUM(CASE WHEN cr.cr_return_amount < 20 THEN cr.cr_return_amount ELSE 0 END) AS small_catalog_return_total,
    SUM(CASE WHEN cr.cr_return_amount >= 20 THEN cr.cr_return_amount ELSE 0 END) AS large_catalog_return_total
FROM catalog_returns cr
JOIN date_dim d_return
    ON cr.cr_returned_date_sk = d_return.d_date_sk
JOIN web_returns wr
    ON wr.wr_returned_date_sk = d_return.d_date_sk
JOIN web_page wp
    ON wr.wr_web_page_sk = wp.wp_web_page_sk
JOIN date_dim d_wp_creation
    ON wp.wp_creation_date_sk = d_wp_creation.d_date_sk
JOIN date_dim d_wp_access
    ON wp.wp_access_date_sk = d_wp_access.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_return.d_date_sk
WHERE d_return.d_year = 2020
GROUP BY
    d_return.d_year,
    d_return.d_moy,
    s.s_store_name,
    wp.wp_type,
    d_wp_creation.d_year,
    d_wp_creation.d_moy,
    d_wp_access.d_year,
    d_wp_access.d_moy
HAVING SUM(cr.cr_net_loss) > 0
ORDER BY total_catalog_net_loss DESC
LIMIT 100
