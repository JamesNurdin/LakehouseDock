WITH filtered_items AS (
    SELECT i_item_sk,
           i_brand,
           i_item_desc,
           CONCAT(i_brand, ' ', i_item_desc) AS brand_desc
    FROM tpcds.item
    WHERE regexp_like(i_item_desc, '[A-Z]{2}[0-9]{2}')
)
SELECT
    i.i_brand,
    cd.cd_gender,
    format_datetime(CAST(d.d_date AS timestamp), 'yyyy-MM') AS year_month,
    SUM(cs.cs_net_profit) AS total_net_profit,
    COUNT(*) AS sales_count,
    MAX(cs.cs_sales_price) AS max_sales_price,
    CONCAT('Brand ', i.i_brand) AS brand_label
FROM filtered_items i
JOIN tpcds.catalog_sales cs ON i.i_item_sk = cs.cs_item_sk
JOIN tpcds.date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
JOIN tpcds.customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
JOIN tpcds.customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
WHERE d.d_year = 2001
  AND (c.c_email_address LIKE '%@example.com' OR regexp_like(c.c_email_address, '.*@gmail\\.com$'))
GROUP BY i.i_brand,
         cd.cd_gender,
         format_datetime(CAST(d.d_date AS timestamp), 'yyyy-MM')
HAVING SUM(cs.cs_net_profit) > 10000
ORDER BY total_net_profit DESC
LIMIT 100
