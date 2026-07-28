WITH filtered_cc AS (
    SELECT cc_call_center_sk,
           cc_name,
           cc_manager
    FROM call_center
    WHERE cc_manager LIKE 'Kim%'
)
SELECT
    fc.cc_name,
    SUBSTRING(i.i_item_desc FROM 1 FOR 15) AS item_desc_prefix,
    REGEXP_EXTRACT(i.i_item_desc, '(\\d{3})', 1) AS extracted_digits,
    SUM(cs.cs_ext_sales_price) AS total_sales,
    SUM(cs.cs_net_profit) AS total_profit,
    COUNT(*) AS orders
FROM filtered_cc fc
JOIN catalog_sales cs
    ON cs.cs_call_center_sk = fc.cc_call_center_sk
JOIN item i
    ON cs.cs_item_sk = i.i_item_sk
JOIN time_dim td
    ON cs.cs_sold_time_sk = td.t_time_sk
WHERE
    REGEXP_LIKE(i.i_item_desc, '[A-Z]{3}[0-9]{2}')
    AND td.t_am_pm LIKE 'PM'
GROUP BY
    fc.cc_name,
    SUBSTRING(i.i_item_desc FROM 1 FOR 15),
    REGEXP_EXTRACT(i.i_item_desc, '(\\d{3})', 1)
ORDER BY total_profit DESC
LIMIT 100
