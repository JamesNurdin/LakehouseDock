WITH agg AS (
    SELECT
        dd.d_year AS return_year,
        s.s_store_name AS store_name,
        i.i_category AS category,
        SUM(cr.cr_net_loss) AS total_net_loss,
        SUM(cr.cr_return_amount) AS total_return_amount,
        COUNT(*) AS return_cnt,
        AVG(cr.cr_return_quantity) AS avg_return_qty
    FROM catalog_returns cr
    JOIN date_dim dd ON cr.cr_returned_date_sk = dd.d_date_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN store s ON s.s_closed_date_sk = dd.d_date_sk
    WHERE dd.d_year BETWEEN 2000 AND 2005
    GROUP BY dd.d_year, s.s_store_name, i.i_category
)
SELECT
    return_year,
    store_name,
    category,
    total_net_loss,
    total_return_amount,
    return_cnt,
    avg_return_qty,
    total_net_loss / NULLIF(return_cnt, 0) AS avg_net_loss_per_return,
    ROW_NUMBER() OVER (PARTITION BY return_year ORDER BY total_net_loss DESC) AS net_loss_rank
FROM agg
ORDER BY return_year, net_loss_rank
LIMIT 100
