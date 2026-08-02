WITH returns_detail AS (
    SELECT
        cr.cr_call_center_sk,
        cr.cr_warehouse_sk,
        cr.cr_returned_date_sk,
        cr.cr_return_quantity,
        cr.cr_return_amount,
        cr.cr_net_loss,
        cc.cc_call_center_id,
        cc.cc_division_name,
        cc.cc_mkt_desc,
        cc.cc_name,
        w.w_warehouse_name,
        w.w_city,
        w.w_suite_number,
        cp.cp_description,
        cp.cp_type,
        d.d_year,
        c.c_email_address,
        regexp_extract(cp.cp_description, '(\\d+)', 1) AS cp_desc_number,
        (cc.cc_name || ' - ' || w.w_city) AS center_warehouse_desc,
        substr(cc.cc_mkt_desc, 1, 30) AS mkt_desc_snippet
    FROM catalog_returns cr
    JOIN call_center cc
        ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN warehouse w
        ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN catalog_page cp
        ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN date_dim d
        ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN customer c
        ON cr.cr_returning_customer_sk = c.c_customer_sk
    WHERE d.d_year = 2001
      AND regexp_like(cc.cc_mkt_desc, '(?i)rich')
      AND w.w_suite_number LIKE 'Suite %'
)
SELECT
    rd.cc_call_center_id,
    rd.cc_division_name,
    rd.w_warehouse_name,
    rd.w_city,
    MAX(rd.center_warehouse_desc) AS center_warehouse_desc,
    MAX(rd.mkt_desc_snippet) AS mkt_desc_snippet,
    SUM(rd.cr_net_loss) AS total_net_loss,
    COUNT(*) AS total_returns,
    COUNT(DISTINCT rd.cr_returned_date_sk) AS distinct_return_days,
    MAX(rd.cp_desc_number) AS max_extracted_page_number
FROM returns_detail rd
WHERE EXISTS (
    SELECT 1
    FROM catalog_returns cr2
    JOIN customer c2
        ON cr2.cr_returning_customer_sk = c2.c_customer_sk
    WHERE cr2.cr_call_center_sk = rd.cr_call_center_sk
      AND cr2.cr_warehouse_sk = rd.cr_warehouse_sk
      AND c2.c_email_address LIKE '%.com'
)
GROUP BY
    rd.cc_call_center_id,
    rd.cc_division_name,
    rd.w_warehouse_name,
    rd.w_city
ORDER BY total_net_loss DESC
LIMIT 100
