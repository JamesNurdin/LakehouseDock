WITH sales_agg AS (
    SELECT
        cc.cc_call_center_id,
        cc.cc_name,
        LENGTH(cc.cc_name) AS name_len,
        SUBSTR(cc.cc_name, 1, 3) AS name_prefix,
        REVERSE(cc.cc_name) AS name_reversed,
        REGEXP_REPLACE(cc.cc_zip, '\\D', '') AS zip_digits,
        TRIM(CONCAT_WS(' ', cc.cc_street_number, cc.cc_street_name, cc.cc_street_type, cc.cc_suite_number) || ', ' || cc.cc_city || ', ' || cc.cc_state || ' ' || cc.cc_zip) AS full_address,
        CARDINALITY(REGEXP_SPLIT(LOWER(cc.cc_name), '\\s+')) AS name_word_count,
        COUNT(DISTINCT i.i_item_id) AS distinct_items_sold,
        SUM(cs.cs_quantity) AS total_quantity,
        SUM(cs.cs_net_paid) AS total_net_paid,
        AVG(LENGTH(i.i_product_name)) AS avg_product_name_len,
        ARRAY_JOIN(ARRAY_AGG(DISTINCT SUBSTR(i.i_product_name, 1, 5)), ', ') AS product_name_prefixes
    FROM call_center cc
    JOIN catalog_sales cs ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN item i ON i.i_item_sk = cs.cs_item_sk
    JOIN date_dim d ON d.d_date_sk = cs.cs_sold_date_sk
    WHERE d.d_year = 2000
      AND cc.cc_state IN ('CA', 'TX', 'NY')
      AND REGEXP_LIKE(LOWER(cc.cc_name), 'center')
    GROUP BY
        cc.cc_call_center_id,
        cc.cc_name,
        cc.cc_zip,
        cc.cc_street_number,
        cc.cc_street_name,
        cc.cc_street_type,
        cc.cc_suite_number,
        cc.cc_city,
        cc.cc_state
    HAVING SUM(cs.cs_net_paid) > 100000
)
SELECT
    *,
    ROW_NUMBER() OVER (PARTITION BY cc_call_center_id ORDER BY total_net_paid DESC) AS rn_by_sales
FROM sales_agg
ORDER BY total_net_paid DESC
LIMIT 100
