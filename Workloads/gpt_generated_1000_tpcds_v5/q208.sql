WITH filtered_items AS (
    SELECT
        i_item_sk,
        i_brand,
        i_category,
        i_units,
        i_item_desc,
        i_product_name,
        concat(i_brand, '-', i_category) AS brand_category,
        regexp_extract(i_item_desc, '(\\d{3})') AS three_digit_code
    FROM tpcds.item
    WHERE i_units LIKE 'B%'
      AND regexp_like(i_item_desc, '\\d{3}')
)
SELECT
    fi.brand_category,
    COUNT(DISTINCT sr.sr_ticket_number) AS return_transactions,
    SUM(sr.sr_net_loss) AS total_net_loss,
    AVG(sr.sr_return_amt_inc_tax) AS avg_return_amount,
    MAX(fi.three_digit_code) AS sample_code
FROM filtered_items fi
JOIN tpcds.store_returns sr
    ON sr.sr_item_sk = fi.i_item_sk
WHERE sr.sr_return_tax > 5.00
GROUP BY fi.brand_category
ORDER BY total_net_loss DESC
LIMIT 100
