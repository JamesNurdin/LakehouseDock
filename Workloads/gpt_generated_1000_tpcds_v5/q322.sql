WITH sales_by_center AS (
    SELECT
        cc.cc_call_center_id      AS call_center_id,
        cc.cc_city                AS city,
        cc.cc_state               AS state,
        i.i_manufact              AS manufact,
        regexp_extract(cc.cc_suite_number, '(\\d+)', 1) AS suite_digits,
        sum(cs.cs_net_profit)    AS total_profit,
        count(*)                 AS order_cnt
    FROM catalog_sales cs
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    WHERE
        regexp_like(cc.cc_suite_number, '^Suite [0-9]+')
        AND cc.cc_city LIKE '%York%'
        AND i.i_current_price BETWEEN 5 AND 50
        AND regexp_like(i.i_manufact, '^a')
    GROUP BY
        cc.cc_call_center_id,
        cc.cc_city,
        cc.cc_state,
        i.i_manufact,
        regexp_extract(cc.cc_suite_number, '(\\d+)', 1)
)
SELECT
    call_center_id,
    city,
    state,
    manufact,
    suite_digits,
    total_profit,
    order_cnt,
    concat('Center ', call_center_id, ' - ', city, ', ', state) AS center_desc
FROM sales_by_center
WHERE total_profit > 10000
ORDER BY total_profit DESC
LIMIT 10
