WITH filtered_calls AS (
    SELECT
        cc.cc_call_center_sk,
        cc.cc_call_center_id,
        cc.cc_name,
        cc.cc_city,
        cc.cc_state,
        REGEXP_EXTRACT(cc.cc_name, '(\\w+) Center', 1) AS center_word,
        CONCAT(cc.cc_city, ', ', cc.cc_state) AS location,
        SUBSTRING(cc.cc_state FROM 1 FOR 2) AS state_prefix
    FROM tpcds.call_center cc
    WHERE REGEXP_LIKE(cc.cc_name, '.*Center.*')
)
SELECT
    fc.cc_call_center_id,
    fc.cc_name,
    fc.cc_city,
    fc.cc_state,
    fc.center_word,
    fc.location,
    fc.state_prefix,
    SUM(cs.cs_net_profit) AS total_profit,
    COUNT(DISTINCT cs.cs_order_number) AS orders
FROM filtered_calls fc
JOIN tpcds.catalog_sales cs
    ON cs.cs_call_center_sk = fc.cc_call_center_sk
JOIN tpcds.item i
    ON i.i_item_sk = cs.cs_item_sk
WHERE i.i_item_desc LIKE '%steel%'
  AND EXISTS (
        SELECT 1
        FROM tpcds.store_sales ss
        WHERE ss.ss_item_sk = i.i_item_sk
          AND ss.ss_sold_date_sk = cs.cs_sold_date_sk
          AND ss.ss_net_paid > 0
    )
GROUP BY
    fc.cc_call_center_id,
    fc.cc_name,
    fc.cc_city,
    fc.cc_state,
    fc.center_word,
    fc.location,
    fc.state_prefix
ORDER BY total_profit DESC
LIMIT 100
