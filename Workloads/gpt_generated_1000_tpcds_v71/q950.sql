WITH avg_item_profit AS (
    SELECT cs.cs_item_sk,
           AVG(cs.cs_net_profit) AS avg_net_profit
    FROM catalog_sales cs
    GROUP BY cs.cs_item_sk
)
SELECT DISTINCT
    c.c_customer_id,
    i.i_item_id,
    i.i_product_name,
    cs.cs_order_number,
    cs.cs_sales_price,
    ss.ss_quantity,
    cs.cs_net_profit,
    avg_ip.avg_net_profit,
    CASE 
        WHEN cs.cs_net_profit > avg_ip.avg_net_profit THEN 'Above Avg'
        ELSE 'Below Avg'
    END AS profit_comp,
    (SELECT COUNT(*) FROM store_sales ss2 WHERE ss2.ss_item_sk = i.i_item_sk) AS total_store_sales_for_item,
    RANK() OVER (PARTITION BY c.c_customer_id ORDER BY cs.cs_net_profit DESC) AS profit_rank
FROM catalog_sales cs
JOIN customer c
    ON cs.cs_bill_customer_sk = c.c_customer_sk
JOIN item i
    ON cs.cs_item_sk = i.i_item_sk
JOIN store_sales ss
    ON ss.ss_customer_sk = c.c_customer_sk
   AND ss.ss_item_sk = i.i_item_sk
JOIN avg_item_profit avg_ip
    ON cs.cs_item_sk = avg_ip.cs_item_sk
WHERE c.c_birth_month = 6
  AND i.i_category_id = 2
  AND cs.cs_sales_price > 30
  AND ss.ss_quantity >= 2
  AND c.c_email_address LIKE '%@%.com'
ORDER BY c.c_customer_id, profit_rank
LIMIT 100
