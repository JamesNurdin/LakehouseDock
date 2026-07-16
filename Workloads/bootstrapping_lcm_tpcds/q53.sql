SELECT
    d.d_date,
    d.d_year,
    d.d_month_seq,
    COALESCE(ca.catalog_net_loss, 0) AS catalog_net_loss,
    COALESCE(wa.web_net_loss, 0) AS web_net_loss,
    COALESCE(ca.catalog_return_quantity, 0) AS catalog_return_quantity,
    COALESCE(wa.web_return_quantity, 0) AS web_return_quantity,
    COALESCE(ca.catalog_refunded_cash, 0) AS catalog_refunded_cash,
    COALESCE(wa.web_refunded_cash, 0) AS web_refunded_cash,
    COALESCE(sa.stores_closed, 0) AS stores_closed_on_date,
    COALESCE(sa.total_floor_space, 0) AS total_floor_space_closed,
    COALESCE(sa.avg_tax_percentage, 0) AS avg_store_tax_percentage,
    COALESCE(pcr.pages_created, 0) AS pages_created,
    COALESCE(pcr.total_link_count, 0) AS total_link_count_created,
    COALESCE(pcr.total_image_count, 0) AS total_image_count_created,
    COALESCE(par.pages_accessed, 0) AS pages_accessed,
    COALESCE(par.total_link_count_access, 0) AS total_link_count_accessed,
    COALESCE(par.total_image_count_access, 0) AS total_image_count_accessed
FROM date_dim d
LEFT JOIN (
    SELECT
        cr_returned_date_sk,
        SUM(cr_net_loss) AS catalog_net_loss,
        SUM(cr_return_quantity) AS catalog_return_quantity,
        SUM(cr_refunded_cash) AS catalog_refunded_cash,
        COUNT(DISTINCT cr_order_number) AS catalog_orders
    FROM catalog_returns
    GROUP BY cr_returned_date_sk
) ca
    ON ca.cr_returned_date_sk = d.d_date_sk
LEFT JOIN (
    SELECT
        wr_returned_date_sk,
        SUM(wr_net_loss) AS web_net_loss,
        SUM(wr_return_quantity) AS web_return_quantity,
        SUM(wr_refunded_cash) AS web_refunded_cash,
        COUNT(DISTINCT wr_order_number) AS web_orders
    FROM web_returns
    GROUP BY wr_returned_date_sk
) wa
    ON wa.wr_returned_date_sk = d.d_date_sk
LEFT JOIN (
    SELECT
        s_closed_date_sk,
        COUNT(*) AS stores_closed,
        SUM(s_floor_space) AS total_floor_space,
        AVG(s_tax_percentage) AS avg_tax_percentage
    FROM store
    GROUP BY s_closed_date_sk
) sa
    ON sa.s_closed_date_sk = d.d_date_sk
LEFT JOIN (
    SELECT
        wp_creation_date_sk,
        COUNT(*) AS pages_created,
        SUM(wp_link_count) AS total_link_count,
        SUM(wp_image_count) AS total_image_count
    FROM web_page
    GROUP BY wp_creation_date_sk
) pcr
    ON pcr.wp_creation_date_sk = d.d_date_sk
LEFT JOIN (
    SELECT
        wp_access_date_sk,
        COUNT(*) AS pages_accessed,
        SUM(wp_link_count) AS total_link_count_access,
        SUM(wp_image_count) AS total_image_count_access
    FROM web_page
    GROUP BY wp_access_date_sk
) par
    ON par.wp_access_date_sk = d.d_date_sk
WHERE d.d_date IS NOT NULL
ORDER BY d.d_date DESC
LIMIT 100
