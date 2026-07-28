WITH catalog_agg AS (
    SELECT
        i.i_item_id AS item_id,
        d.d_year AS year,
        SUM(cr.cr_return_amount) AS total_return_amount,
        COUNT(*) AS return_cnt
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    WHERE d.d_date BETWEEN DATE '2000-01-01' AND DATE '2000-12-31'
      AND i.i_current_price > (SELECT AVG(i2.i_current_price) FROM item i2)
      AND EXISTS (
          SELECT 1
          FROM warehouse w
          WHERE w.w_warehouse_sk = cr.cr_warehouse_sk
            AND w.w_gmt_offset = -5.00
      )
    GROUP BY i.i_item_id, d.d_year
),
store_agg AS (
    SELECT
        i.i_item_id AS item_id,
        d.d_year AS year,
        SUM(sr.sr_return_amt) AS total_return_amount,
        COUNT(*) AS return_cnt
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    WHERE d.d_year = 2000
      AND r.r_reason_desc = 'Customer Not Satisfied'
    GROUP BY i.i_item_id, d.d_year
),
combined AS (
    SELECT * FROM catalog_agg
    UNION ALL
    SELECT * FROM store_agg
)
SELECT
    item_id,
    year,
    total_return_amount,
    return_cnt,
    ROW_NUMBER() OVER (PARTITION BY item_id ORDER BY total_return_amount DESC) AS rn
FROM combined
ORDER BY rn
LIMIT 100
