WITH combined_returns AS (
    -- Store returns part (includes a semi‑join on store for California locations)
    SELECT
        CAST('store' AS varchar) AS return_source,
        s.s_store_id AS store_id,
        s.s_store_name AS store_name,
        CAST(NULL AS varchar) AS catalog_page_id,
        CAST(NULL AS varchar) AS department,
        i.i_item_id AS item_id,
        i.i_product_name AS product_name,
        c.c_customer_id AS customer_id,
        cd.cd_gender AS gender,
        hd.hd_buy_potential AS buy_potential,
        r.r_reason_desc AS reason_desc,
        sr.sr_return_amt_inc_tax AS return_amount_inc_tax,
        CASE WHEN sr.sr_return_tax > 50 THEN 'High Tax' ELSE 'Normal Tax' END AS tax_category,
        sr.sr_returned_date_sk AS returned_date_sk
    FROM store_returns sr
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    WHERE sr.sr_return_amt_inc_tax > 100
      AND sr.sr_returned_date_sk BETWEEN 2450000 AND 2455000
      AND i.i_current_price > 20
      AND EXISTS (
          SELECT 1
          FROM store s2
          WHERE s2.s_store_sk = sr.sr_store_sk
            AND s2.s_state = 'CA'
      )
    UNION ALL
    -- Catalog returns part
    SELECT
        CAST('catalog' AS varchar) AS return_source,
        CAST(NULL AS varchar) AS store_id,
        CAST(NULL AS varchar) AS store_name,
        cp.cp_catalog_page_id AS catalog_page_id,
        cp.cp_department AS department,
        i.i_item_id AS item_id,
        i.i_product_name AS product_name,
        cust_ref.c_customer_id AS customer_id,
        cd_ref.cd_gender AS gender,
        hd_ref.hd_buy_potential AS buy_potential,
        r.r_reason_desc AS reason_desc,
        cr.cr_return_amt_inc_tax AS return_amount_inc_tax,
        CASE WHEN cr.cr_return_tax > 30 THEN 'High Tax' ELSE 'Standard Tax' END AS tax_category,
        cr.cr_returned_date_sk AS returned_date_sk
    FROM catalog_returns cr
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN customer cust_ref ON cr.cr_refunded_customer_sk = cust_ref.c_customer_sk
    JOIN customer_demographics cd_ref ON cr.cr_refunded_cdemo_sk = cd_ref.cd_demo_sk
    JOIN household_demographics hd_ref ON cr.cr_refunded_hdemo_sk = hd_ref.hd_demo_sk
    WHERE cr.cr_return_amt_inc_tax > 200
      AND cr.cr_returned_date_sk BETWEEN 2450000 AND 2455000
      AND i.i_current_price > 30
      AND sm.sm_contract LIKE 'hGoF18%'
),
ranked AS (
    SELECT
        *,
        ROW_NUMBER() OVER (PARTITION BY return_source ORDER BY return_amount_inc_tax DESC) AS rn,
        RANK()    OVER (PARTITION BY return_source ORDER BY return_amount_inc_tax DESC) AS rnk
    FROM combined_returns
)
SELECT
    return_source,
    store_id,
    store_name,
    catalog_page_id,
    department,
    item_id,
    product_name,
    customer_id,
    gender,
    buy_potential,
    reason_desc,
    return_amount_inc_tax,
    tax_category,
    returned_date_sk,
    rn,
    rnk
FROM ranked
WHERE rn <= 10
ORDER BY return_source, rnk
LIMIT 100
