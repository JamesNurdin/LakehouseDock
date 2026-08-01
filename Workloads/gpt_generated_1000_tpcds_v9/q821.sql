WITH RECURSIVE year_seq (year_num) AS (
    -- Anchor: the earliest year in the date dimension
    SELECT MIN(d_year) AS year_num
    FROM date_dim
    UNION ALL
    -- Recursive step: generate the next year until the max year
    SELECT year_num + 1
    FROM year_seq
    WHERE year_num < (SELECT MAX(d_year) FROM date_dim)
)
-- Combine catalog return rows and web sales rows
(
    SELECT
        'catalog' AS source_type,
        d.d_year            AS year_num,
        cr.cr_item_sk       AS item_sk,
        cr.cr_return_amount AS amount,
        t.reason_word      AS reason_word,
        (
            SELECT COUNT(*)
            FROM catalog_returns cr2
            WHERE cr2.cr_order_number = cr.cr_order_number
        )                  AS return_cnt,
        ROW_NUMBER() OVER (PARTITION BY d.d_year ORDER BY cr.cr_return_amount DESC) AS row_num
    FROM catalog_returns cr
    JOIN date_dim d
        ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    CROSS JOIN UNNEST(split(COALESCE(r.r_reason_desc, ''), ' ')) AS t(reason_word)
    JOIN year_seq y
        ON d.d_year = y.year_num
    WHERE cr.cr_return_amount > (
            SELECT MAX(cr3.cr_return_amount)
            FROM catalog_returns cr3
            WHERE cr3.cr_item_sk = cr.cr_item_sk
          )
      AND d.d_year BETWEEN 2000 AND 2002
)
UNION ALL
(
    SELECT
        'web' AS source_type,
        d.d_year               AS year_num,
        ws.ws_item_sk          AS item_sk,
        ws.ws_net_paid_inc_ship_tax AS amount,
        t.reason_word         AS reason_word,
        (
            SELECT COUNT(*)
            FROM web_returns wr2
            WHERE wr2.wr_order_number = ws.ws_order_number
        )                     AS return_cnt,
        ROW_NUMBER() OVER (PARTITION BY d.d_year ORDER BY ws.ws_net_paid_inc_ship_tax DESC) AS row_num
    FROM web_sales ws
    JOIN date_dim d
        ON ws.ws_sold_date_sk = d.d_date_sk
    LEFT JOIN web_returns wr
        ON wr.wr_order_number = ws.ws_order_number
       AND wr.wr_item_sk = ws.ws_item_sk
    LEFT JOIN reason r2
        ON wr.wr_reason_sk = r2.r_reason_sk
    CROSS JOIN UNNEST(split(COALESCE(r2.r_reason_desc, ''), ' ')) AS t(reason_word)
    JOIN year_seq y
        ON d.d_year = y.year_num
    WHERE ws.ws_net_paid_inc_ship_tax > (
            SELECT MAX(ws2.ws_net_paid_inc_ship_tax)
            FROM web_sales ws2
          )
      AND d.d_year BETWEEN 2000 AND 2002
)
ORDER BY year_num DESC, amount DESC
LIMIT 100
