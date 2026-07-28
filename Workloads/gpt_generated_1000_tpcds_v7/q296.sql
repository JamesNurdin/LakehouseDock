WITH filtered_items AS (
    SELECT
        i_item_sk,
        i_class,
        i_item_desc,
        i_product_name,
        i_brand,
        i_color,
        CONCAT(i_brand, ' ', i_product_name) AS brand_product,
        SUBSTRING(i_item_desc FROM 1 FOR 20) AS short_desc
    FROM tpcds.item
    WHERE regexp_like(i_item_desc, '[A-Za-z]{3,}\s\d{2,}')
),
filtered_reasons AS (
    SELECT
        r_reason_sk,
        r_reason_desc
    FROM tpcds.reason
    WHERE r_reason_desc LIKE '%size%'
)
SELECT
    fr.r_reason_desc,
    fi.i_class,
    COUNT(*) AS returns_cnt,
    SUM(wr.wr_return_amt) AS total_return_amt,
    AVG(wr.wr_return_quantity) AS avg_return_qty,
    MIN(wr.wr_return_amt) AS min_return_amt,
    MAX(wr.wr_return_amt) AS max_return_amt,
    MIN(fr.r_reason_desc || ' - ' || fi.i_class) AS concatenated_key
FROM tpcds.web_returns wr
JOIN filtered_items fi
    ON wr.wr_item_sk = fi.i_item_sk
JOIN filtered_reasons fr
    ON wr.wr_reason_sk = fr.r_reason_sk
WHERE wr.wr_return_amt > 0
GROUP BY fr.r_reason_desc, fi.i_class
ORDER BY total_return_amt DESC
LIMIT 100
