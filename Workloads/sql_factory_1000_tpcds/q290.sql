WITH warehouse_profit AS (
    SELECT
        w.w_warehouse_id AS w_id,
        w.w_warehouse_name AS w_name,
        SUM(cs.cs_net_profit) AS total_net_profit,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        AVG(cs.cs_ext_discount_amt) AS avg_discount,
        COUNT(DISTINCT cs.cs_order_number) AS order_cnt
    FROM catalog_sales cs
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN web_page wp ON wp.wp_customer_sk = c.c_customer_sk
    GROUP BY w.w_warehouse_id, w.w_warehouse_name
    HAVING COUNT(DISTINCT cs.cs_order_number) > 10
)
SELECT
    w_id,
    w_name,
    total_net_profit,
    total_sales,
    avg_discount,
    CASE
        WHEN total_net_profit > 100000 THEN 'HIGH'
        WHEN total_net_profit BETWEEN 50000 AND 100000 THEN 'MEDIUM'
        ELSE 'LOW'
    END AS profit_category,
    RANK() OVER (ORDER BY total_net_profit DESC) AS profit_rank
FROM warehouse_profit
ORDER BY profit_rank
