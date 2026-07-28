WITH catalog_ret AS (
    SELECT
        cr.cr_returned_date_sk AS return_date_key,
        cr.cr_refunded_customer_sk AS customer_sk,
        cr.cr_return_amount,
        i.i_brand,
        cp.cp_department,
        'catalog' AS source
    FROM catalog_returns cr
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    WHERE i.i_brand = 'BrandX'
      AND cp.cp_department = 'Sports'
),
store_ret AS (
    SELECT
        sr.sr_returned_date_sk AS return_date_key,
        sr.sr_customer_sk AS customer_sk,
        sr.sr_return_amt AS return_amount,
        i.i_brand,
        s.s_county,
        'store' AS source
    FROM store_returns sr
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    WHERE i.i_brand = 'BrandX'
      AND s.s_county = 'Gage County'
)
SELECT DISTINCT
    customer_sk,
    return_date_key,
    return_amount,
    source,
    i_brand,
    COALESCE(cp_department, s_county) AS category_detail
FROM (
    SELECT
        customer_sk,
        return_date_key,
        cr_return_amount AS return_amount,
        source,
        i_brand,
        cp_department,
        NULL AS s_county
    FROM catalog_ret
    UNION ALL
    SELECT
        customer_sk,
        return_date_key,
        return_amount,
        source,
        i_brand,
        NULL,
        s_county
    FROM store_ret
) AS combined
ORDER BY return_amount DESC, customer_sk
LIMIT 100
