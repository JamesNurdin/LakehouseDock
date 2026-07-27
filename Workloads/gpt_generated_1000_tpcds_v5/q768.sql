WITH filtered_returns AS (
    SELECT
        s.s_market_manager,
        d.d_quarter_name,
        i.i_category,
        i.i_item_desc,
        i.i_item_id,
        sr.sr_return_amt,
        sr.sr_net_loss,
        regexp_extract(i.i_item_desc, '([0-9]{2,})', 1) AS extracted_number,
        CONCAT(s.s_store_name, ' - ', i.i_item_desc) AS store_item_label
    FROM store_returns sr
    JOIN date_dim d
        ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN item i
        ON sr.sr_item_sk = i.i_item_sk
    JOIN store s
        ON sr.sr_store_sk = s.s_store_sk
    WHERE s.s_store_name LIKE '%Market%'
      AND regexp_like(i.i_item_desc, '[A-Z]{2}[0-9]{2}')
      AND d.d_year = 2002
)
SELECT
    s_market_manager,
    d_quarter_name,
    i_category,
    COUNT(*) AS return_cnt,
    SUM(sr_return_amt) AS total_return_amt,
    SUM(sr_net_loss) AS total_net_loss,
    AVG(CAST(extracted_number AS DOUBLE)) AS avg_extracted_number
FROM filtered_returns
GROUP BY
    s_market_manager,
    d_quarter_name,
    i_category
ORDER BY
    total_return_amt DESC,
    total_net_loss DESC
LIMIT 100
