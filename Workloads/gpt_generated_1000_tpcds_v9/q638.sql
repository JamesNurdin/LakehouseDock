WITH sales_data AS (
    SELECT
        cs.cs_order_number,
        cs.cs_sold_date_sk,
        cs.cs_net_paid,
        cs.cs_quantity,
        cs.cs_call_center_sk,
        cs.cs_catalog_page_sk,
        cs.cs_ship_mode_sk,
        d.d_date,
        d.d_year,
        cp.cp_description,
        cc.cc_name,
        cc.cc_city,
        sm.sm_contract,
        (
            SELECT SUM(cr.cr_return_amount)
            FROM catalog_returns cr
            WHERE cr.cr_order_number = cs.cs_order_number
        ) AS total_return_amount
    FROM catalog_sales cs
    JOIN date_dim d
        ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE d.d_year = 2001
      AND regexp_like(cc.cc_name, '^A')
      AND cp.cp_description LIKE '%Special%'
)
SELECT
    sd.d_year,
    sd.d_date,
    sd.cc_name,
    sd.cc_city,
    concat(sd.cc_name, ' - ', sd.cc_city) AS center_full_name,
    sd.cp_description,
    regexp_extract(sd.cp_description, '(\\w+)') AS first_word_desc,
    sd.sm_contract,
    sd.cs_net_paid,
    sd.total_return_amount,
    (sd.cs_net_paid - COALESCE(sd.total_return_amount, 0)) AS net_sales_after_returns,
    ROW_NUMBER() OVER (PARTITION BY sd.d_year ORDER BY sd.cs_net_paid DESC) AS rn_year_sales,
    EXISTS (
        SELECT 1
        FROM catalog_returns cr
        JOIN reason r
            ON cr.cr_reason_sk = r.r_reason_sk
        WHERE cr.cr_order_number = sd.cs_order_number
          AND r.r_reason_desc LIKE '%service%'
    ) AS has_service_issue_return,
    ltr.description_prefix_upper
FROM sales_data sd
LEFT JOIN LATERAL (
    SELECT upper(substring(sd.cp_description, 1, 10)) AS description_prefix_upper
) AS ltr ON TRUE
WHERE sd.cs_quantity > 1
ORDER BY sd.d_year, rn_year_sales
LIMIT 100
