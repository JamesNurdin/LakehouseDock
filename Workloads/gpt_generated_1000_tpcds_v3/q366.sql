SELECT
    concat(cc.cc_city, ', ', cc.cc_state) AS call_center_location,
    d.d_year,
    d.d_moy AS month,
    sum(cs.cs_net_profit) AS total_profit,
    count(DISTINCT cs.cs_order_number) AS distinct_orders,
    array_agg(DISTINCT regexp_extract(i.i_item_desc, '^([A-Za-z]+)', 1)) AS desc_first_words
FROM
    catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
WHERE
    regexp_like(i.i_item_desc, '(?i)plastic')
    AND cc.cc_name LIKE 'Call Center%'
    AND d.d_year BETWEEN 2000 AND 2002
GROUP BY
    concat(cc.cc_city, ', ', cc.cc_state),
    d.d_year,
    d.d_moy
ORDER BY
    total_profit DESC
LIMIT 100
