WITH sales_agg AS (
   SELECT
       cs.cs_net_profit,
       i.i_category,
       t.t_hour,
       i.i_item_desc,
       i.i_product_name
   FROM catalog_sales cs
   JOIN item i ON cs.cs_item_sk = i.i_item_sk
   JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
   JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
   JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
   WHERE
       regexp_like(i.i_item_desc, '(?i)steel')
       AND c.c_last_name LIKE 'S%'
       AND cd.cd_gender = 'M'
)
SELECT
    i_category,
    t_hour,
    sum(cs_net_profit) AS total_net_profit,
    concat('Category ', i_category) AS category_label,
    regexp_extract(i_item_desc, '(\\w+)', 1) AS first_word_desc,
    substring(i_product_name, 1, 5) AS prod_prefix
FROM sales_agg
GROUP BY
    i_category,
    t_hour,
    i_item_desc,
    i_product_name
HAVING sum(cs_net_profit) > 1000
ORDER BY total_net_profit DESC
LIMIT 20
