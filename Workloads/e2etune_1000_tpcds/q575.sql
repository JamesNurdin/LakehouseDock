WITH agg AS (
    SELECT
        cc.cc_city,
        w.w_state,
        d.d_year,
        SUM(cr.cr_net_loss) AS total_net_loss,
        AVG(cr.cr_return_amount) AS avg_return_amount,
        COUNT(*) AS total_returns,
        COUNT(DISTINCT cr.cr_item_sk) AS distinct_items_returned
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    WHERE
        cc.cc_gmt_offset = -5.00
        AND cp.cp_type = 'Promotion'
        AND d.d_year BETWEEN 2000 AND 2005
        AND cc.cc_city IN ('Greenwood', 'Friendship')
    GROUP BY cc.cc_city, w.w_state, d.d_year
    HAVING SUM(cr.cr_net_loss) > 10000
)
SELECT
    cc_city,
    w_state,
    d_year,
    total_net_loss,
    avg_return_amount,
    total_returns,
    distinct_items_returned,
    RANK() OVER (PARTITION BY d_year ORDER BY total_net_loss DESC) AS net_loss_rank
FROM agg
ORDER BY d_year, net_loss_rank
LIMIT 20
