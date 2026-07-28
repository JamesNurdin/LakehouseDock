SELECT
    i_brand,
    COUNT(DISTINCT i_item_id) AS distinct_item_count
FROM
    tpcds.item
WHERE
    i_rec_start_date >= DATE '1999-01-01'
    AND i_rec_start_date <= DATE '2000-12-31'
    AND i_units = 'Gram'
GROUP BY
    i_brand
ORDER BY
    i_brand
LIMIT 100
