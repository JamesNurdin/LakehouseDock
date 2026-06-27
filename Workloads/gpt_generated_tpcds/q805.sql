-- Analytical query: total return amount and net loss by call‑center, warehouse city, and item category,
-- with a ranking of the categories for each call‑center based on net loss.
WITH category_returns AS (
    SELECT
        cc.cc_name,
        w.w_city,
        i.i_category,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_net_loss) AS total_net_loss,
        COUNT(*) AS return_cnt,
        AVG(cr.cr_return_quantity) AS avg_return_qty
    FROM catalog_returns cr
    JOIN call_center cc
        ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN warehouse w
        ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN item i
        ON cr.cr_item_sk = i.i_item_sk
    GROUP BY
        cc.cc_name,
        w.w_city,
        i.i_category
    HAVING SUM(cr.cr_return_amount) > 0
)
SELECT
    cc_name,
    w_city,
    i_category,
    total_return_amount,
    total_net_loss,
    return_cnt,
    avg_return_qty,
    ROW_NUMBER() OVER (PARTITION BY cc_name ORDER BY total_net_loss DESC) AS category_rank_by_net_loss
FROM category_returns
ORDER BY cc_name, category_rank_by_net_loss
