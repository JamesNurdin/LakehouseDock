WITH sales_data AS (
    SELECT
        ss.ss_net_profit,
        i.i_category,
        ca.ca_state,
        i.i_brand,
        i.i_item_desc,
        regexp_extract(i.i_item_desc, '(sport|furn)', 1) AS key_term
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    WHERE regexp_like(i.i_item_desc, '(sport|furn)')
      AND ca.ca_city LIKE 'San%'
)
SELECT
    i_category,
    ca_state,
    sum(ss_net_profit) AS total_profit,
    any_value(concat(i_brand, ' - ', key_term)) AS sample_brand_term
FROM sales_data
GROUP BY GROUPING SETS (
    (i_category, ca_state),
    (i_category),
    (ca_state),
    ()
)
ORDER BY total_profit DESC
LIMIT 100
