WITH store AS (
    SELECT
        ss.ss_item_sk,
        i.i_category,
        ss.ss_net_paid AS net_paid,
        ss.ss_net_profit AS net_profit,
        'store' AS sales_channel
    FROM tpcds.store_sales ss
    JOIN tpcds.item i ON ss.ss_item_sk = i.i_item_sk
    JOIN tpcds.customer c ON ss.ss_customer_sk = c.c_customer_sk
    WHERE i.i_category = 'Electronics'
      AND ss.ss_sold_date_sk BETWEEN 2450000 AND 2450100
),
catalog AS (
    SELECT
        cs.cs_item_sk AS ss_item_sk,
        i.i_category,
        cs.cs_net_paid AS net_paid,
        cs.cs_net_profit AS net_profit,
        'catalog' AS sales_channel
    FROM tpcds.catalog_sales cs
    JOIN tpcds.item i ON cs.cs_item_sk = i.i_item_sk
    JOIN tpcds.customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    WHERE i.i_category = 'Electronics'
      AND cs.cs_sold_date_sk BETWEEN 2450000 AND 2450100
)
SELECT
    sales_channel,
    i_category,
    SUM(net_paid)   AS total_net_paid,
    SUM(net_profit) AS total_net_profit
FROM (
    SELECT * FROM store
    UNION ALL
    SELECT * FROM catalog
) combined
GROUP BY sales_channel, i_category
ORDER BY sales_channel
