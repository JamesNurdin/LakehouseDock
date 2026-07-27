WITH filtered_returns AS (
    SELECT
        cr_returned_date_sk,
        cr_item_sk,
        cr_refunded_cdemo_sk,
        cr_returning_cdemo_sk,
        cr_catalog_page_sk,
        cr_return_quantity,
        cr_return_amount,
        cr_refunded_cash
    FROM catalog_returns
    WHERE cr_return_amount > 100
      AND cr_return_quantity <= 3
      AND cr_refunded_cash >= 50
      AND cr_returned_date_sk BETWEEN 2450000 AND 2452000
      AND cr_returned_time_sk BETWEEN 0 AND 1440
),
distinct_items AS (
    SELECT DISTINCT i.i_item_sk, i.i_product_name, i.i_current_price, i.i_color
    FROM item i
    WHERE i.i_current_price BETWEEN 20 AND 200
      AND i.i_color = 'red'
)
SELECT
    cp.cp_catalog_page_id,
    di.i_product_name,
    cd.cd_gender,
    crf.cr_return_amount,
    crf.cr_return_quantity,
    ROW_NUMBER() OVER (PARTITION BY cp.cp_catalog_page_id ORDER BY crf.cr_return_amount DESC) AS rn,
    SUM(crf.cr_return_amount) OVER (
        PARTITION BY di.i_item_sk
        ORDER BY crf.cr_returned_date_sk
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ) AS moving_sum_3
FROM filtered_returns crf
JOIN distinct_items di
  ON crf.cr_item_sk = di.i_item_sk
JOIN customer_demographics cd
  ON crf.cr_returning_cdemo_sk = cd.cd_demo_sk
JOIN catalog_page cp
  ON crf.cr_catalog_page_sk = cp.cp_catalog_page_sk
WHERE cd.cd_marital_status = 'M'
  AND cp.cp_type = 'A'
  AND cp.cp_department LIKE '%Home%'
  AND cp.cp_description LIKE '%Urban%'
LIMIT 100
