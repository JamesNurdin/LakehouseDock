WITH
catalog_agg AS (
    SELECT
        i.i_item_id,
        i.i_product_name,
        'catalog' AS channel,
        SUM(cr.cr_return_quantity) AS total_return_qty,
        SUM(cr.cr_return_amount) AS total_return_amount,
        ROW_NUMBER() OVER (ORDER BY SUM(cr.cr_return_amount) DESC) AS per_channel_rn
    FROM catalog_returns cr
    JOIN date_dim d
        ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN item i
        ON cr.cr_item_sk = i.i_item_sk
    JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    WHERE d.d_year = 2001
      AND r.r_reason_desc = 'Damaged'
      AND NOT EXISTS (
          SELECT 1
          FROM web_returns wr
          JOIN date_dim dw
              ON wr.wr_returned_date_sk = dw.d_date_sk
          WHERE wr.wr_item_sk = i.i_item_sk
            AND dw.d_year = 2001
      )
    GROUP BY i.i_item_id, i.i_product_name
),
web_agg AS (
    SELECT
        i.i_item_id,
        i.i_product_name,
        'web' AS channel,
        SUM(wr.wr_return_quantity) AS total_return_qty,
        SUM(wr.wr_return_amt) AS total_return_amount,
        ROW_NUMBER() OVER (ORDER BY SUM(wr.wr_return_amt) DESC) AS per_channel_rn
    FROM web_returns wr
    JOIN date_dim d
        ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN item i
        ON wr.wr_item_sk = i.i_item_sk
    JOIN reason r
        ON wr.wr_reason_sk = r.r_reason_sk
    WHERE d.d_year = 2001
      AND r.r_reason_desc = 'Damaged'
      AND NOT EXISTS (
          SELECT 1
          FROM catalog_returns cr2
          JOIN date_dim dc2
              ON cr2.cr_returned_date_sk = dc2.d_date_sk
          WHERE cr2.cr_item_sk = i.i_item_sk
            AND dc2.d_year = 2001
      )
    GROUP BY i.i_item_id, i.i_product_name
),
combined AS (
    SELECT
        i_item_id,
        i_product_name,
        channel,
        total_return_qty,
        total_return_amount,
        per_channel_rn
    FROM catalog_agg
    UNION ALL
    SELECT
        i_item_id,
        i_product_name,
        channel,
        total_return_qty,
        total_return_amount,
        per_channel_rn
    FROM web_agg
)
SELECT
    c.i_item_id,
    c.i_product_name,
    c.channel,
    c.total_return_qty,
    c.total_return_amount,
    ROW_NUMBER() OVER (ORDER BY c.total_return_amount DESC) AS global_rn
FROM combined c
ORDER BY global_rn
LIMIT 100
