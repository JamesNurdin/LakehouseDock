WITH filtered_returns AS (
    SELECT
        cr.cr_item_sk,
        cr.cr_return_amount,
        cr.cr_net_loss,
        cr.cr_refunded_cash,
        cr.cr_return_quantity,
        cr.cr_returned_date_sk
    FROM catalog_returns cr
    WHERE cr.cr_return_amount > 0
),
item_info AS (
    SELECT
        i.i_item_sk,
        i.i_manufact,
        i.i_formulation,
        i.i_product_name,
        i.i_brand,
        i.i_category
    FROM item i
    WHERE regexp_like(i.i_formulation, '^\\d{3,}.*[a-z]$')
      AND i.i_brand LIKE '%a%'
)
SELECT
    ii.i_manufact,
    ii.i_brand,
    COUNT(*) AS total_returns,
    SUM(fr.cr_return_amount) AS total_return_amount,
    AVG(fr.cr_return_amount) AS avg_return_amount,
    SUM(fr.cr_net_loss) AS total_net_loss,
    CASE
        WHEN SUM(fr.cr_net_loss) > 0 THEN 'LOSS'
        ELSE 'NO LOSS'
    END AS loss_flag,
    CONCAT(SUBSTRING(ii.i_product_name, 1, 10), '_', CAST(COUNT(*) AS VARCHAR)) AS product_key
FROM filtered_returns fr
JOIN item_info ii
    ON fr.cr_item_sk = ii.i_item_sk
WHERE EXISTS (
    SELECT 1
    FROM catalog_returns cr2
    WHERE cr2.cr_item_sk = fr.cr_item_sk
      AND cr2.cr_refunded_cash > 100
      AND regexp_extract(CAST(cr2.cr_refunded_cash AS VARCHAR), '(\\d+)', 1) IS NOT NULL
)
GROUP BY ii.i_manufact, ii.i_brand, ii.i_product_name
ORDER BY total_return_amount DESC
LIMIT 100
