SELECT
    cp.cp_catalog_page_id,
    cp.cp_type,
    i.i_category,
    SUM(cs.cs_net_profit) AS total_net_profit,
    SUM(cs.cs_quantity) AS total_quantity,
    AVG(cs.cs_ext_discount_amt) AS avg_discount,
    COUNT(DISTINCT cs.cs_bill_customer_sk) AS distinct_customers,
    ROW_NUMBER() OVER (PARTITION BY i.i_category ORDER BY SUM(cs.cs_net_profit) DESC) AS category_page_rank
FROM
    catalog_sales cs
JOIN
    catalog_page cp
    ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN
    item i
    ON cs.cs_item_sk = i.i_item_sk
JOIN
    customer_address ca
    ON cs.cs_bill_addr_sk = ca.ca_address_sk
JOIN
    customer_demographics cd
    ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
WHERE
    cp.cp_type = 'monthly'
    AND cp.cp_catalog_page_number BETWEEN 1 AND 5
    AND i.i_category = 'Sports'
    AND ca.ca_country = 'United States'
    AND cd.cd_gender = 'M'
    AND cs.cs_sold_date_sk BETWEEN 2450900 AND 2451100
GROUP BY
    cp.cp_catalog_page_id,
    cp.cp_type,
    i.i_category
HAVING
    SUM(cs.cs_net_profit) > 10000
ORDER BY
    total_net_profit DESC
LIMIT 20
