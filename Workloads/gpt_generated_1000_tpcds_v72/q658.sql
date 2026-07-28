WITH cat_ret AS (
    SELECT
        cr.cr_warehouse_sk,
        w.w_warehouse_name,
        SUM(cr.cr_net_loss) AS total_net_loss,
        COUNT(*) AS return_cnt,
        regexp_extract(ca.ca_suite_number, '\\d+', 0) AS suite_number
    FROM catalog_returns cr
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    WHERE regexp_like(cp.cp_description, '(?i)clearance')
      AND ca.ca_city LIKE 'A%'
      AND ca.ca_suite_number LIKE 'Suite %'
      AND EXISTS (
          SELECT 1
          FROM date_dim d
          WHERE d.d_date_sk = cr.cr_returned_date_sk
            AND d.d_year = 2001
      )
    GROUP BY cr.cr_warehouse_sk, w.w_warehouse_name, ca.ca_suite_number
),
store_ret AS (
    SELECT
        sr.sr_store_sk,
        s.s_store_name,
        SUM(sr.sr_net_loss) AS total_net_loss,
        COUNT(*) AS return_cnt,
        regexp_extract(ca.ca_suite_number, '\\d+', 0) AS suite_number
    FROM store_returns sr
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    WHERE regexp_like(s.s_store_name, '^A.*')
      AND ca.ca_city LIKE 'A%'
      AND ca.ca_suite_number LIKE 'Suite %'
      AND EXISTS (
          SELECT 1
          FROM date_dim d
          WHERE d.d_date_sk = sr.sr_returned_date_sk
            AND d.d_year = 2001
      )
    GROUP BY sr.sr_store_sk, s.s_store_name, ca.ca_suite_number
)
SELECT
    source_type,
    entity_name,
    total_net_loss,
    return_cnt,
    suite_number,
    concat(source_type, ': ', entity_name) AS label
FROM (
    SELECT
        'WAREHOUSE' AS source_type,
        w_warehouse_name AS entity_name,
        total_net_loss,
        return_cnt,
        suite_number
    FROM cat_ret
    UNION ALL
    SELECT
        'STORE' AS source_type,
        s_store_name AS entity_name,
        total_net_loss,
        return_cnt,
        suite_number
    FROM store_ret
) final_result
ORDER BY source_type, total_net_loss DESC
