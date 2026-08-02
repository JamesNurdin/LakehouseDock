WITH store_returns_agg AS (
    SELECT
        i.i_item_sk,
        i.i_item_id,
        i.i_product_name,
        s.s_store_name,
        regexp_extract(r.r_reason_desc, '(\\w+)') AS first_word_reason,
        SUM(sr.sr_return_quantity) AS total_qty,
        SUM(sr.sr_return_amt) AS total_amt,
        (SELECT SUM(cr.cr_return_amount)
         FROM catalog_returns cr
         WHERE cr.cr_item_sk = i.i_item_sk) AS catalog_total_amt,
        substr(i.i_product_name, 1, 10) AS short_name
    FROM store_returns sr
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN time_dim td ON sr.sr_return_time_sk = td.t_time_sk
    WHERE regexp_like(r.r_reason_desc, 'purchase')
      AND s.s_store_name LIKE 'A%'
      AND td.t_hour BETWEEN 9 AND 17
    GROUP BY i.i_item_sk, i.i_item_id, i.i_product_name, s.s_store_name, r.r_reason_desc, i.i_product_name
),
web_return_items AS (
    SELECT DISTINCT i.i_item_id
    FROM web_returns wr
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    WHERE regexp_like(r.r_reason_desc, 'purchase')
)
SELECT
    sra.i_item_id,
    sra.i_product_name,
    sra.s_store_name,
    concat(sra.s_store_name, ' - ', sra.i_product_name) AS store_item,
    sra.first_word_reason,
    sra.total_qty,
    sra.total_amt,
    sra.catalog_total_amt,
    sra.short_name
FROM store_returns_agg sra
WHERE sra.i_item_id IN (
    SELECT i_item_id FROM store_returns_agg
    EXCEPT
    SELECT i_item_id FROM web_return_items
)
ORDER BY sra.total_amt DESC
LIMIT 10
