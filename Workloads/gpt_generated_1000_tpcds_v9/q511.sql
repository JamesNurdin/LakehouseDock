WITH union_data AS (
    SELECT
        cr.cr_item_sk AS item_sk,
        cr.cr_return_amt_inc_tax AS total_return_amount,
        cr.cr_return_quantity AS return_qty,
        cr.cr_fee AS fee,
        cr.cr_return_ship_cost AS ship_cost,
        i.i_category AS category,
        i.i_item_id AS item_id
    FROM catalog_returns cr
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
    WHERE i.i_category_id IN (1, 2)
      AND i.i_size = 'small'
      AND i.i_rec_start_date >= DATE '2001-01-01'
      AND i.i_rec_end_date <= DATE '2005-12-31'
      AND inv.inv_quantity_on_hand >= 10
      AND cr.cr_return_amt_inc_tax < 500
      AND EXISTS (
          SELECT 1
          FROM store_returns sr
          WHERE sr.sr_item_sk = i.i_item_sk
            AND sr.sr_return_ship_cost > 100
            AND sr.sr_return_amt_inc_tax > 200
      )
    UNION
    SELECT
        sr.sr_item_sk AS item_sk,
        sr.sr_return_amt_inc_tax AS total_return_amount,
        sr.sr_return_quantity AS return_qty,
        sr.sr_fee AS fee,
        sr.sr_return_ship_cost AS ship_cost,
        i.i_category AS category,
        i.i_item_id AS item_id
    FROM store_returns sr
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
    WHERE i.i_category_id IN (1, 2)
      AND i.i_size = 'small'
      AND i.i_rec_start_date >= DATE '2001-01-01'
      AND i.i_rec_end_date <= DATE '2005-12-31'
      AND inv.inv_quantity_on_hand >= 10
      AND sr.sr_return_amt_inc_tax < 500
      AND EXISTS (
          SELECT 1
          FROM catalog_returns cr
          WHERE cr.cr_item_sk = i.i_item_sk
            AND cr.cr_return_amt_inc_tax > 100
      )
),
aggregated AS (
    SELECT
        u.category,
        SUM(u.total_return_amount) AS sum_total_return_amount,
        AVG(u.total_return_amount) AS avg_total_return_amount,
        COUNT(DISTINCT u.item_id) AS distinct_item_count,
        MIN(u.total_return_amount) AS min_total_return_amount,
        MAX(u.total_return_amount) AS max_total_return_amount
    FROM union_data u
    GROUP BY u.category
    HAVING SUM(u.total_return_amount) > 1000
)
SELECT
    ROW_NUMBER() OVER (ORDER BY agg.sum_total_return_amount DESC) AS row_num,
    agg.category,
    agg.sum_total_return_amount,
    agg.avg_total_return_amount,
    agg.distinct_item_count,
    agg.min_total_return_amount,
    agg.max_total_return_amount
FROM aggregated agg
ORDER BY agg.sum_total_return_amount DESC
LIMIT 100
