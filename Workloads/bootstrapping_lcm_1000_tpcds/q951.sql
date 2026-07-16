WITH returns_agg AS (
    SELECT
        cr.cr_warehouse_sk,
        cr.cr_returned_date_sk,
        SUM(cr.cr_net_loss) AS total_net_loss,
        COUNT(*) AS total_return_qty
    FROM catalog_returns cr
    GROUP BY cr.cr_warehouse_sk, cr.cr_returned_date_sk
),
store_agg AS (
    SELECT
        s.s_closed_date_sk,
        COUNT(*) AS closed_stores,
        COUNT(DISTINCT s.s_store_sk) AS distinct_closed_stores
    FROM store s
    GROUP BY s.s_closed_date_sk
),
web_page_agg AS (
    SELECT
        wp.wp_creation_date_sk,
        COUNT(DISTINCT wp.wp_web_page_sk) AS created_web_pages,
        AVG(date_diff('day', d_creation.d_date, d_access.d_date)) AS avg_days_between_creation_and_access
    FROM web_page wp
    JOIN date_dim d_creation ON wp.wp_creation_date_sk = d_creation.d_date_sk
    JOIN date_dim d_access   ON wp.wp_access_date_sk   = d_access.d_date_sk
    GROUP BY wp.wp_creation_date_sk
)
SELECT
    w.w_warehouse_id,
    w.w_warehouse_name,
    d_ret.d_year,
    d_ret.d_quarter_name,
    ra.total_net_loss,
    ra.total_return_qty,
    COALESCE(sa.closed_stores, 0)          AS closed_stores,
    COALESCE(wpa.created_web_pages, 0)    AS created_web_pages,
    wpa.avg_days_between_creation_and_access,
    DENSE_RANK() OVER (ORDER BY ra.total_net_loss DESC) AS loss_rank
FROM returns_agg ra
JOIN date_dim d_ret ON ra.cr_returned_date_sk = d_ret.d_date_sk
JOIN warehouse w    ON ra.cr_warehouse_sk    = w.w_warehouse_sk
LEFT JOIN store_agg sa   ON sa.s_closed_date_sk   = d_ret.d_date_sk
LEFT JOIN web_page_agg wpa ON wpa.wp_creation_date_sk = d_ret.d_date_sk
ORDER BY ra.total_net_loss DESC
LIMIT 100
