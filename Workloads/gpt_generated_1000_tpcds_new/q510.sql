WITH
    return_agg AS (
        SELECT
            cr.cr_item_sk AS item_sk,
            SUM(cr.cr_return_amount) AS total_return_amount,
            COUNT(*) AS return_cnt,
            REGEXP_EXTRACT_ALL(it.i_item_desc, '\\w+') AS desc_words,
            it.i_item_desc
        FROM catalog_returns cr
        JOIN item it ON cr.cr_item_sk = it.i_item_sk
        JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
        WHERE d.d_year = 2020
          AND it.i_item_desc LIKE '%metal%'
          AND REGEXP_LIKE(it.i_item_desc, '.*[A-Z]{2}.*')
        GROUP BY cr.cr_item_sk, it.i_item_desc
    ),
    return_words AS (
        SELECT
            r.item_sk,
            word,
            COUNT(*) OVER (PARTITION BY r.item_sk) AS word_occurrences
        FROM return_agg r
        CROSS JOIN UNNEST(r.desc_words) AS t(word)
    ),
    sales_agg AS (
        SELECT
            ws.ws_item_sk AS item_sk,
            SUM(ws.ws_net_paid) AS total_sales_amount,
            COUNT(*) AS sales_cnt,
            REGEXP_EXTRACT_ALL(it.i_item_desc, '\\w+') AS desc_words,
            it.i_item_desc
        FROM web_sales ws
        JOIN item it ON ws.ws_item_sk = it.i_item_sk
        JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
        WHERE d.d_year = 2020
          AND it.i_item_desc LIKE '%metal%'
          AND REGEXP_LIKE(it.i_item_desc, '.*[A-Z]{2}.*')
        GROUP BY ws.ws_item_sk, it.i_item_desc
    ),
    sales_words AS (
        SELECT
            s.item_sk,
            word,
            COUNT(*) OVER (PARTITION BY s.item_sk) AS word_occurrences
        FROM sales_agg s
        CROSS JOIN UNNEST(s.desc_words) AS t(word)
    ),
    common_items AS (
        SELECT item_sk FROM return_agg
        INTERSECT
        SELECT item_sk FROM sales_agg
    ),
    union_agg AS (
        SELECT item_sk, total_return_amount AS total_amount, return_cnt AS cnt, 'return' AS src
        FROM return_agg
        UNION
        SELECT item_sk, total_sales_amount AS total_amount, sales_cnt AS cnt, 'sale' AS src
        FROM sales_agg
    )
SELECT
    u.item_sk,
    i.i_item_desc,
    u.total_amount,
    u.cnt,
    u.src,
    ROW_NUMBER() OVER (PARTITION BY u.src ORDER BY u.total_amount DESC) AS rank_within_src,
    SUBSTR(i.i_item_desc, 1, 10) || '_' || u.src AS desc_key
FROM union_agg u
JOIN item i ON u.item_sk = i.i_item_sk
WHERE u.item_sk IN (SELECT item_sk FROM common_items)
  AND REGEXP_LIKE(i.i_item_desc, '^.*metal.*$')
ORDER BY u.total_amount DESC
OFFSET 0
LIMIT 100
