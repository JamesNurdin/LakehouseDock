WITH sales_item AS (
    SELECT cs.cs_call_center_sk,
           cs.cs_item_sk,
           cs.cs_net_profit,
           cs.cs_quantity,
           cs.cs_ext_sales_price
    FROM catalog_sales cs
    WHERE cs.cs_net_profit > 0
)
SELECT
    cc.cc_call_center_id,
    concat(cc.cc_city, ', ', cc.cc_state) AS location,
    count(DISTINCT si.cs_item_sk) AS distinct_items_sold,
    sum(si.cs_net_profit) AS total_net_profit,
    avg(si.cs_net_profit) AS avg_net_profit_per_sale,
    regexp_extract(i.i_product_name, '(\\w+)$') AS product_suffix,
    sum(CASE WHEN regexp_like(i.i_product_name, '^.*[0-9]{2}.*$') THEN si.cs_net_profit ELSE 0 END) AS profit_with_digits
FROM sales_item si
JOIN call_center cc
  ON si.cs_call_center_sk = cc.cc_call_center_sk
JOIN item i
  ON si.cs_item_sk = i.i_item_sk
JOIN inventory inv
  ON i.i_item_sk = inv.inv_item_sk
WHERE
    cc.cc_country = 'United States'
    AND cc.cc_name LIKE '%Center%'
    AND regexp_like(cc.cc_name, '^.*[aeiou]{2}.*$')
    AND inv.inv_quantity_on_hand > 0
    AND i.i_class_id IN (
        SELECT i2.i_class_id
        FROM item i2
        WHERE regexp_like(i2.i_item_desc, '.*[Ss]mall.*')
    )
GROUP BY
    cc.cc_call_center_id,
    cc.cc_city,
    cc.cc_state,
    i.i_product_name
HAVING sum(si.cs_net_profit) > 1000
ORDER BY total_net_profit DESC
LIMIT 100
