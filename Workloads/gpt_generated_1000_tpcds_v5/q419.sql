WITH joined AS (
    SELECT
        cr.cr_returned_date_sk,
        cr.cr_returned_time_sk,
        cr.cr_item_sk,
        cr.cr_fee,
        cr.cr_return_amount,
        cr.cr_return_quantity,
        cr.cr_net_loss,
        d.d_quarter_name,
        d.d_year,
        t.t_hour,
        i.i_category,
        i.i_category_id,
        i.i_current_price,
        inv.inv_quantity_on_hand,
        CASE WHEN cr.cr_return_amount > 100 THEN 'HIGH' ELSE 'LOW' END AS return_level,
        (
            SELECT SUM(inv2.inv_quantity_on_hand)
            FROM inventory inv2
            WHERE inv2.inv_item_sk = cr.cr_item_sk
        ) AS total_item_qty
    FROM catalog_returns cr
    JOIN date_dim d
        ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN time_dim t
        ON cr.cr_returned_time_sk = t.t_time_sk
    JOIN item i
        ON cr.cr_item_sk = i.i_item_sk
    JOIN inventory inv
        ON inv.inv_date_sk = d.d_date_sk
       AND inv.inv_item_sk = i.i_item_sk
    WHERE d.d_quarter_name = '1904Q4'
      AND i.i_category_id = 5
      AND cr.cr_fee > 30
      AND t.t_hour BETWEEN 9 AND 17
),
aggregated AS (
    SELECT
        i_category,
        d_quarter_name,
        return_level,
        SUM(cr_return_amount) AS total_return_amount,
        AVG(cr_fee) AS avg_fee,
        COUNT(*) AS return_cnt,
        MIN(inv_quantity_on_hand) AS min_qty,
        MAX(inv_quantity_on_hand) AS max_qty,
        MAX(total_item_qty) AS total_item_qty -- same for each group, pick any
    FROM joined
    GROUP BY i_category, d_quarter_name, return_level
)
SELECT
    i_category,
    d_quarter_name,
    return_level,
    total_return_amount,
    avg_fee,
    return_cnt,
    min_qty,
    max_qty,
    total_item_qty,
    SUM(total_return_amount) OVER (
        PARTITION BY i_category
        ORDER BY d_quarter_name
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS running_total_return_amount,
    RANK() OVER (
        PARTITION BY i_category
        ORDER BY total_return_amount DESC
    ) AS return_amount_rank
FROM aggregated
ORDER BY i_category, d_quarter_name
