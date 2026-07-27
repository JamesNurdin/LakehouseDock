WITH item_features AS (
    SELECT
        i_item_sk,
        i_product_name,
        i_item_desc,
        regexp_extract(i_item_desc, '^([^ ]+)', 1) AS first_word_desc,
        length(i_item_desc) AS desc_len
    FROM item
    WHERE regexp_like(i_item_desc, '[A-Za-z]{3,}')
)
SELECT
    CONCAT(w.w_warehouse_name, ' - ', cc.cc_name) AS location_desc,
    i.first_word_desc,
    SUM(cs.cs_net_paid_inc_tax) AS total_sales_inc_tax,
    AVG(cs.cs_net_profit) AS avg_profit,
    COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
    AVG(i.desc_len) AS avg_desc_len
FROM catalog_sales cs
JOIN call_center cc
  ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN warehouse w
  ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN item_features i
  ON cs.cs_item_sk = i.i_item_sk
WHERE
    regexp_like(w.w_warehouse_name, '^[A-Z][a-z]+')
    AND w.w_gmt_offset = -5.00
    AND i.first_word_desc LIKE 'A%'
GROUP BY
    CONCAT(w.w_warehouse_name, ' - ', cc.cc_name),
    i.first_word_desc
ORDER BY total_sales_inc_tax DESC
LIMIT 20
