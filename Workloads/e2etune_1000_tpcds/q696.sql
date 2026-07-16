WITH profit_by_customer AS (
    SELECT
        cs.cs_bill_customer_sk,
        SUM(cs.cs_net_profit) AS total_net_profit,
        SUM(cs.cs_quantity) AS total_quantity,
        AVG(cs.cs_ext_discount_amt) AS avg_discount,
        COUNT(DISTINCT cs.cs_order_number) AS order_cnt
    FROM catalog_sales cs
    WHERE cs.cs_ext_discount_amt > 200
      AND cs.cs_ext_tax > 0
    GROUP BY cs.cs_bill_customer_sk
),
ranked_customers AS (
    SELECT
        pb.*, 
        RANK() OVER (ORDER BY total_net_profit DESC) AS profit_rank
    FROM profit_by_customer pb
)
SELECT
    rc.profit_rank,
    rc.cs_bill_customer_sk AS customer_sk,
    c.c_last_name,
    c.c_first_name,
    c.c_birth_year,
    rc.total_net_profit,
    rc.total_quantity,
    rc.avg_discount,
    rc.order_cnt
FROM ranked_customers rc
JOIN customer c
    ON rc.cs_bill_customer_sk = c.c_customer_sk
WHERE rc.profit_rank <= 10
ORDER BY rc.profit_rank
