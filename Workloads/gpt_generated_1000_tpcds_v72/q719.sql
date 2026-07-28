WITH warehouse_returns AS (
    SELECT
        w.w_warehouse_sk,
        w.w_warehouse_id,
        w.w_city,
        w.w_state,
        SUM(cr.cr_return_amount) AS total_return_amount,
        COUNT(*) AS return_cnt
    FROM catalog_returns cr
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    GROUP BY w.w_warehouse_sk, w.w_warehouse_id, w.w_city, w.w_state
),
item_returns AS (
    SELECT
        i.i_item_sk,
        i.i_item_desc,
        i.i_units,
        SUM(cr.cr_return_amount) AS item_return_amount,
        COUNT(*) AS item_return_cnt
    FROM catalog_returns cr
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    WHERE regexp_like(i.i_item_desc, '(?i)damaged|defective')
    GROUP BY i.i_item_sk, i.i_item_desc, i.i_units
)
SELECT
    wr.w_warehouse_id,
    concat(wr.w_city, ', ', wr.w_state) AS location,
    wr.total_return_amount,
    wr.return_cnt,
    ir.i_item_desc,
    regexp_extract(ir.i_item_desc, '^([^ ]+)', 1) AS first_word,
    ir.item_return_amount,
    rank() OVER (PARTITION BY wr.w_state ORDER BY wr.total_return_amount DESC) AS state_rank
FROM warehouse_returns wr
JOIN item_returns ir ON ir.i_item_sk = (
        SELECT cr2.cr_item_sk
        FROM catalog_returns cr2
        WHERE cr2.cr_warehouse_sk = wr.w_warehouse_sk
        ORDER BY cr2.cr_return_amount DESC
        LIMIT 1
    )
WHERE wr.w_city LIKE 'A%'
  AND wr.total_return_amount > (SELECT avg(total_return_amount) FROM warehouse_returns)
  AND EXISTS (
        SELECT 1
        FROM catalog_returns cr3
        WHERE cr3.cr_warehouse_sk = wr.w_warehouse_sk
          AND cr3.cr_return_amount > 500
      )
  AND regexp_like(wr.w_city, '^A[[:alpha:]]+')
UNION ALL
SELECT
    wr.w_warehouse_id,
    concat(wr.w_city, ', ', wr.w_state) AS location,
    wr.total_return_amount,
    wr.return_cnt,
    ir.i_item_desc,
    regexp_extract(ir.i_item_desc, '^([^ ]+)', 1) AS first_word,
    ir.item_return_amount,
    rank() OVER (PARTITION BY wr.w_state ORDER BY wr.total_return_amount DESC) AS state_rank
FROM warehouse_returns wr
JOIN item_returns ir ON ir.i_item_sk = (
        SELECT cr2.cr_item_sk
        FROM catalog_returns cr2
        WHERE cr2.cr_warehouse_sk = wr.w_warehouse_sk
        ORDER BY cr2.cr_return_amount DESC
        LIMIT 1
    )
WHERE wr.w_city LIKE 'B%'
  AND wr.total_return_amount > (SELECT avg(total_return_amount) FROM warehouse_returns)
  AND EXISTS (
        SELECT 1
        FROM catalog_returns cr3
        WHERE cr3.cr_warehouse_sk = wr.w_warehouse_sk
          AND cr3.cr_return_amount > 500
      )
  AND regexp_like(wr.w_city, '^B[[:alpha:]]+')
ORDER BY total_return_amount DESC
LIMIT 100
