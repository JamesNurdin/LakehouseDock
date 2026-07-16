WITH store_daily_metrics AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        s.s_state,
        d_ret.d_date,
        SUM(cr.cr_net_loss) AS total_net_loss,
        SUM(cr.cr_return_quantity) AS total_return_quantity,
        SUM(inv.inv_quantity_on_hand) AS total_inventory_on_hand,
        COUNT(DISTINCT wp_create.wp_web_page_id) AS pages_created,
        COUNT(DISTINCT wp_access.wp_web_page_id) AS pages_accessed,
        AVG(cr.cr_return_amount) AS avg_return_amount,
        CASE
            WHEN SUM(cr.cr_net_loss) > 5000 THEN 'HIGH'
            WHEN SUM(cr.cr_net_loss) > 1000 THEN 'MEDIUM'
            ELSE 'LOW'
        END AS loss_category
    FROM catalog_returns cr
    JOIN date_dim d_ret
        ON cr.cr_returned_date_sk = d_ret.d_date_sk
    JOIN inventory inv
        ON inv.inv_date_sk = d_ret.d_date_sk
    JOIN store s
        ON s.s_closed_date_sk = d_ret.d_date_sk
    JOIN web_page wp_create
        ON wp_create.wp_creation_date_sk = d_ret.d_date_sk
    JOIN web_page wp_access
        ON wp_access.wp_access_date_sk = d_ret.d_date_sk
    WHERE d_ret.d_year = 2020
      AND s.s_state = 'CA'
    GROUP BY
        s.s_store_id,
        s.s_store_name,
        s.s_state,
        d_ret.d_date
    HAVING SUM(cr.cr_net_loss) > 1000
)
SELECT
    sdm.s_store_id,
    sdm.s_store_name,
    sdm.s_state,
    sdm.d_date,
    sdm.total_net_loss,
    sdm.total_return_quantity,
    sdm.total_inventory_on_hand,
    sdm.pages_created,
    sdm.pages_accessed,
    sdm.avg_return_amount,
    sdm.loss_category,
    ROW_NUMBER() OVER (PARTITION BY sdm.s_store_id ORDER BY sdm.total_net_loss DESC) AS loss_rank
FROM store_daily_metrics sdm
ORDER BY sdm.total_net_loss DESC
LIMIT 10
