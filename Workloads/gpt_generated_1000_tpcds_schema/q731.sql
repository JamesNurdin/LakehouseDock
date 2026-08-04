WITH sampled_sales AS (
    SELECT
        cs_sold_date_sk,
        cs_sold_time_sk,
        cs_warehouse_sk,
        cs_item_sk,
        cs_bill_customer_sk,
        cs_order_number,
        cs_ext_sales_price,
        cs_net_profit
    FROM catalog_sales
    TABLESAMPLE BERNOULLI (10)
),
order_diff AS (
    SELECT cs_order_number FROM sampled_sales
    EXCEPT
    SELECT sr_ticket_number FROM store_returns
),
sales_warehouse AS (
    SELECT
        ss.cs_sold_date_sk,
        ss.cs_sold_time_sk,
        ss.cs_warehouse_sk,
        ss.cs_item_sk,
        ss.cs_bill_customer_sk,
        ss.cs_order_number,
        ss.cs_ext_sales_price,
        ss.cs_net_profit,
        w.w_warehouse_name
    FROM sampled_sales ss
    FULL OUTER JOIN warehouse w
        ON ss.cs_warehouse_sk = w.w_warehouse_sk
)
SELECT
    sw.cs_order_number,
    sw.cs_sold_date_sk,
    sw.w_warehouse_name,
    i.i_item_desc,
    i.i_brand,
    SUBSTRING(i.i_item_desc, 1, 5) AS item_desc_prefix,
    CONCAT(i.i_brand, ' - ', i.i_item_desc) AS brand_item_concat,
    CASE WHEN sw.cs_net_profit > 0 THEN 'Profit' ELSE 'Loss' END AS profit_flag,
    REGEXP_EXTRACT(i.i_item_desc, '(\\d+)', 1) AS first_number_in_desc,
    CASE WHEN REGEXP_LIKE(c.c_email_address, '@.*\\.edu$') THEN 'EducationDomain' ELSE 'OtherDomain' END AS email_domain_category,
    sw.cs_ext_sales_price,
    sw.cs_net_profit
FROM sales_warehouse sw
INNER JOIN item i
    ON sw.cs_item_sk = i.i_item_sk
INNER JOIN customer c
    ON sw.cs_bill_customer_sk = c.c_customer_sk
WHERE sw.cs_order_number IN (SELECT cs_order_number FROM order_diff)
  AND REGEXP_LIKE(i.i_item_desc, '\\d')
  AND c.c_email_address LIKE '%@%edu'
ORDER BY sw.cs_net_profit DESC
OFFSET 10 ROWS
LIMIT 100
