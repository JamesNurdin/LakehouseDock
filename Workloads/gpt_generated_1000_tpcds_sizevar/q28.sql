WITH store_only_items AS (
    SELECT ss_item_sk
    FROM store_sales
    EXCEPT
    SELECT cs_item_sk
    FROM catalog_sales
)
SELECT
    s.s_store_sk,
    concat(s.s_store_name, ' - ', s.s_city) AS store_full_name,
    s.s_state,
    i.i_item_id,
    regexp_extract(i.i_item_desc, '(\\d{3})') AS extracted_digits,
    case when regexp_like(i.i_item_desc, '[A-Z]{2,}') then 'UPPER' else 'OTHER' end AS desc_type,
    SUM(ss.ss_net_paid) AS total_net_paid,
    COUNT(DISTINCT ss.ss_customer_sk) AS distinct_customers,
    (SELECT sum(sr.sr_return_amt) FROM store_returns sr WHERE sr.sr_store_sk = s.s_store_sk) AS total_store_returns
FROM store_sales ss
JOIN store_only_items soi ON ss.ss_item_sk = soi.ss_item_sk
JOIN item i ON ss.ss_item_sk = i.i_item_sk
JOIN store s ON ss.ss_store_sk = s.s_store_sk
WHERE i.i_item_desc LIKE '%test%' OR i.i_item_id LIKE 'ITEM%'
GROUP BY
    s.s_store_sk,
    s.s_store_name,
    s.s_city,
    s.s_state,
    i.i_item_id,
    i.i_item_desc,
    concat(s.s_store_name, ' - ', s.s_city),
    regexp_extract(i.i_item_desc, '(\\d{3})'),
    case when regexp_like(i.i_item_desc, '[A-Z]{2,}') then 'UPPER' else 'OTHER' end
ORDER BY total_net_paid DESC
LIMIT 100
