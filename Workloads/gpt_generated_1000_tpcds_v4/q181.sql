WITH sales_join AS (
    SELECT
        cs.cs_net_profit,
        cs.cs_quantity,
        cs.cs_ship_customer_sk,
        cs.cs_call_center_sk,
        cs.cs_item_sk,
        cs.cs_net_paid_inc_ship_tax,
        cc.cc_state,
        cc.cc_mkt_desc,
        i.i_brand,
        i.i_item_desc,
        i.i_manager_id,
        i.i_manufact,
        i.i_item_id
    FROM tpcds.catalog_sales cs
    JOIN tpcds.call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN tpcds.item i ON cs.cs_item_sk = i.i_item_sk
    WHERE cc.cc_state IN ('WA', 'NY')
      AND regexp_like(i.i_item_desc, '(?i)steel|plastic')
      AND cc.cc_mkt_desc LIKE '%new%'
)
SELECT
    cc_state,
    i_brand,
    CONCAT(cc_state, '-', i_brand) AS state_brand,
    COUNT(*) AS sales_cnt,
    SUM(cs_net_profit) AS total_profit,
    AVG(cs_net_profit) AS avg_profit,
    CASE
        WHEN SUM(cs_net_profit) > 100000 THEN 'High'
        WHEN SUM(cs_net_profit) > 50000 THEN 'Medium'
        ELSE 'Low'
    END AS profit_category,
    REGEXP_EXTRACT(i_manufact, '(\\w+)', 1) AS manufact_word,
    SUBSTR(i_item_id, 1, 3) AS item_prefix
FROM sales_join
GROUP BY
    cc_state,
    i_brand,
    CONCAT(cc_state, '-', i_brand),
    REGEXP_EXTRACT(i_manufact, '(\\w+)', 1),
    SUBSTR(i_item_id, 1, 3)
ORDER BY total_profit DESC
LIMIT 20
