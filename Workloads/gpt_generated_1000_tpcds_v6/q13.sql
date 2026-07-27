WITH filtered_returns AS (
    SELECT
        cr.cr_return_amount,
        cr.cr_return_quantity,
        cr.cr_item_sk,
        cr.cr_warehouse_sk,
        i.i_brand,
        i.i_category,
        cc.cc_name,
        cc.cc_city
    FROM catalog_returns cr
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    WHERE
        regexp_like(i.i_brand, 'import')                -- brand contains the word "import"
        AND i.i_rec_end_date >= DATE '2000-01-01'       -- items still active after 2000‑01‑01
        AND cc.cc_city LIKE '%ville%'                  -- call‑center city contains "ville"
)
SELECT
    filtered_returns.cc_name,
    filtered_returns.cc_city,
    COUNT(*) AS num_returns,
    SUM(filtered_returns.cr_return_amount) AS total_return_amount,
    AVG(filtered_returns.cr_return_amount) AS avg_return_amount,
    CONCAT('Brand: ', filtered_returns.i_brand) AS brand_label
FROM filtered_returns
WHERE EXISTS (
    SELECT 1
    FROM warehouse w
    WHERE w.w_warehouse_sk = filtered_returns.cr_warehouse_sk
      AND regexp_like(w.w_city, '^A')                -- warehouse city starts with "A"
)
GROUP BY
    filtered_returns.cc_name,
    filtered_returns.cc_city,
    filtered_returns.i_brand
HAVING SUM(filtered_returns.cr_return_amount) > (
    SELECT AVG(cr_return_amount) * 1.5
    FROM catalog_returns
)
ORDER BY total_return_amount DESC
LIMIT 20
