WITH sampled_sales AS (
    SELECT *
    FROM tpcds.catalog_sales
    TABLESAMPLE BERNOULLI (10)
),
item_avg AS (
    SELECT cs_item_sk, AVG(cs_net_paid) AS avg_net_paid
    FROM sampled_sales
    GROUP BY cs_item_sk
),
filtered_sales AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_order_number,
        cs.cs_net_paid,
        cs.cs_net_profit,
        cs.cs_item_sk,
        cs.cs_bill_customer_sk,
        i.i_item_desc,
        i.i_category,
        c.c_customer_id,
        ca.ca_city,
        ROW_NUMBER() OVER (PARTITION BY cs.cs_bill_customer_sk ORDER BY cs.cs_net_profit DESC) AS rn
    FROM sampled_sales cs
    JOIN tpcds.item i
        ON cs.cs_item_sk = i.i_item_sk
    JOIN tpcds.customer c
        ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN tpcds.customer_address ca
        ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN item_avg ia
        ON cs.cs_item_sk = ia.cs_item_sk
    WHERE cs.cs_net_paid > ia.avg_net_paid
      AND regexp_like(i.i_item_desc, '.*Gold.*')
      AND ca.ca_city LIKE '%Hill%'
      AND i.i_category = 'Electronics'
)
SELECT
    f.cs_order_number,
    f.c_customer_id,
    f.ca_city,
    f.i_item_desc,
    f.i_category,
    f.cs_net_paid,
    f.cs_net_profit,
    f.rn
FROM filtered_sales f
WHERE EXISTS (
    SELECT 1
    FROM tpcds.store_sales ss
    WHERE ss.ss_item_sk = f.cs_item_sk
      AND ss.ss_net_profit > 0
)
ORDER BY f.cs_net_profit DESC
LIMIT 100
