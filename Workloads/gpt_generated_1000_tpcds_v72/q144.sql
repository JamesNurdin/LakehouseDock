WITH combined AS (
    -- Store sales aggregation
    SELECT
        i.i_item_id            AS i_item_id,
        i.i_item_desc          AS i_item_desc,
        SUM(ss.ss_ext_sales_price) AS total_amount,
        'store'                AS source_type
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE ss.ss_ext_sales_price > 500
    GROUP BY i.i_item_id, i.i_item_desc

    UNION ALL

    -- Web returns aggregation
    SELECT
        i.i_item_id            AS i_item_id,
        i.i_item_desc          AS i_item_desc,
        SUM(wr.wr_return_amt) AS total_amount,
        'web'                  AS source_type
    FROM web_returns wr
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    WHERE wr.wr_return_amt > 100
    GROUP BY i.i_item_id, i.i_item_desc
)
SELECT
    i_item_id,
    i_item_desc,
    total_amount,
    source_type,
    row_number() OVER (PARTITION BY source_type ORDER BY total_amount DESC) AS rank_by_amount
FROM combined
ORDER BY source_type, rank_by_amount
LIMIT 100
