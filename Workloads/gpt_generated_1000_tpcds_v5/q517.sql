WITH filtered_returns AS (
    SELECT
        cr_item_sk,
        cr_refunded_cdemo_sk,
        cr_return_amount,
        cr_fee,
        cr_return_quantity,
        cr_returned_date_sk
    FROM catalog_returns
    WHERE cr_fee > 30
      AND cr_return_amount > 10
      AND cr_returned_date_sk BETWEEN 2450000 AND 2453650
)
SELECT
    i.i_brand,
    i.i_category,
    COALESCE(cd.cd_gender, 'Unknown') AS gender,
    COUNT(*) AS total_returns,
    SUM(fr.cr_return_amount) AS sum_return_amount,
    AVG(fr.cr_fee) AS avg_fee,
    MIN(fr.cr_return_quantity) AS min_quantity,
    MAX(fr.cr_return_quantity) AS max_quantity
FROM filtered_returns fr
JOIN item i
    ON fr.cr_item_sk = i.i_item_sk
LEFT JOIN customer_demographics cd
    ON fr.cr_refunded_cdemo_sk = cd.cd_demo_sk
WHERE i.i_manufact_id IN (625, 995)
  AND i.i_color = 'Red'
  AND fr.cr_returned_date_sk BETWEEN 2450000 AND 2453650
GROUP BY i.i_brand, i.i_category, cd.cd_gender
ORDER BY sum_return_amount DESC
LIMIT 100
