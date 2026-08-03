WITH sales_agg AS (
    SELECT
        i.i_item_id AS item_id,
        d.d_year AS year,
        word,
        ss.ss_quantity AS quantity,
        ss.ss_sales_price AS sales_price,
        (SELECT avg(ss2.ss_sales_price)
         FROM store_sales ss2
         WHERE ss2.ss_item_sk = ss.ss_item_sk) AS avg_item_price
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    CROSS JOIN UNNEST(split(i.i_item_desc, ' ')) AS t(word)
    WHERE d.d_year = 2001
      AND i.i_brand = 'Brand#45'
),
returns_agg AS (
    SELECT
        i.i_item_id AS item_id,
        d.d_year AS year,
        word,
        wr.wr_return_quantity AS return_quantity,
        wr.wr_return_amt AS return_amt,
        EXISTS (
            SELECT 1
            FROM reason r
            WHERE r.r_reason_sk = wr.wr_reason_sk
              AND r.r_reason_desc LIKE '%defect%'
        ) AS is_defect
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    CROSS JOIN UNNEST(split(i.i_item_desc, ' ')) AS t(word)
    WHERE d.d_year = 2001
      AND wr.wr_return_amt > 100
)
SELECT
    item_id,
    year,
    word,
    quantity,
    sales_price,
    avg_item_price,
    NULL AS return_quantity,
    NULL AS return_amt,
    NULL AS is_defect
FROM sales_agg
UNION
SELECT
    item_id,
    year,
    word,
    NULL AS quantity,
    NULL AS sales_price,
    NULL AS avg_item_price,
    return_quantity,
    return_amt,
    is_defect
FROM returns_agg
ORDER BY year DESC, sales_price DESC NULLS LAST
LIMIT 100
