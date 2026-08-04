-- Goal: Identify high‑value catalog returns for items whose description matches a pattern, enrich with ship mode and catalog page info, exclude low‑value returns, rank the results, and limit to 100 rows.
WITH order_numbers_to_exclude AS (
    SELECT cr_order_number
    FROM catalog_returns
    WHERE cr_return_amount < 10
),
selected_orders AS (
    SELECT cr_order_number
    FROM catalog_returns
    WHERE cr_return_amount > 50
    EXCEPT
    SELECT cr_order_number FROM order_numbers_to_exclude
),
filtered_returns AS (
    SELECT
        cr.cr_order_number,
        cr.cr_return_amount,
        cr.cr_return_quantity,
        cr.cr_refunded_cash,
        cr.cr_ship_mode_sk,
        cr.cr_item_sk,
        cr.cr_catalog_page_sk,
        cr.cr_returned_date_sk
    FROM catalog_returns cr
    WHERE cr.cr_order_number IN (SELECT cr_order_number FROM selected_orders)
      AND regexp_like(CAST(cr.cr_refunded_cash AS varchar), '^\\d{2,}\\.')
),
item_details AS (
    SELECT
        i.i_item_sk,
        i.i_item_desc,
        i.i_category,
        i.i_brand,
        i.i_product_name
    FROM item i
    WHERE regexp_like(i.i_item_desc, '(?i)and')
),
ship_details AS (
    SELECT
        sm.sm_ship_mode_sk,
        sm.sm_carrier,
        sm.sm_code,
        sm.sm_contract
    FROM ship_mode sm
    WHERE sm.sm_carrier LIKE '%USPS%'
),
page_details AS (
    SELECT
        cp.cp_catalog_page_sk,
        cp.cp_description,
        cp.cp_department
    FROM catalog_page cp
    WHERE cp.cp_description LIKE '%women%'
)
SELECT
    fr.cr_order_number,
    id.i_brand,
    concat(id.i_brand, ' ', coalesce(id.i_product_name, '')) AS brand_product,
    sd.sm_carrier,
    pd.cp_department,
    regexp_extract(id.i_item_desc, '(\\w+)', 1) AS first_word_desc,
    (
        SELECT sum(cr_inner.cr_refunded_cash)
        FROM catalog_returns cr_inner
        WHERE cr_inner.cr_item_sk = id.i_item_sk
    ) AS total_refunded_cash_per_item,
    ROW_NUMBER() OVER (ORDER BY fr.cr_return_amount DESC) AS rn
FROM filtered_returns fr
JOIN item_details id ON fr.cr_item_sk = id.i_item_sk
JOIN ship_details sd ON fr.cr_ship_mode_sk = sd.sm_ship_mode_sk
JOIN page_details pd ON fr.cr_catalog_page_sk = pd.cp_catalog_page_sk
CROSS JOIN LATERAL (
    SELECT substring(id.i_item_desc FROM 1 FOR 10) AS short_desc
) lt
WHERE lt.short_desc LIKE 'A%'
UNION
SELECT
    fr2.cr_order_number,
    id2.i_brand,
    concat(id2.i_brand, ' ', coalesce(id2.i_product_name, '')) AS brand_product,
    sd2.sm_carrier,
    pd2.cp_department,
    regexp_extract(id2.i_item_desc, '(\\w+)', 1) AS first_word_desc,
    (
        SELECT sum(cr_inner2.cr_refunded_cash)
        FROM catalog_returns cr_inner2
        WHERE cr_inner2.cr_item_sk = id2.i_item_sk
    ) AS total_refunded_cash_per_item,
    ROW_NUMBER() OVER (ORDER BY fr2.cr_return_amount DESC) AS rn
FROM filtered_returns fr2
JOIN item_details id2 ON fr2.cr_item_sk = id2.i_item_sk
JOIN ship_details sd2 ON fr2.cr_ship_mode_sk = sd2.sm_ship_mode_sk
JOIN page_details pd2 ON fr2.cr_catalog_page_sk = pd2.cp_catalog_page_sk
WHERE id2.i_category = 'Furniture'
  AND NOT EXISTS (
        SELECT 1
        FROM catalog_returns cr3
        WHERE cr3.cr_order_number = fr2.cr_order_number
          AND cr3.cr_return_amount > 1000
    )
LIMIT 100
