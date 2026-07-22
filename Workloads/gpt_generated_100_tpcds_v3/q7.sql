WITH sales_agg AS (
    SELECT
        cs.cs_bill_customer_sk AS cust_sk,
        cs.cs_ship_mode_sk AS ship_mode_sk,
        sm.sm_type AS ship_type,
        sm.sm_carrier,
        wp.wp_type AS web_page_type,
        SUM(cs.cs_net_paid) AS total_net_paid,
        SUM(cs.cs_net_profit) AS total_net_profit,
        COUNT(*) AS sales_cnt
    FROM catalog_sales cs
    JOIN customer c
        ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN web_page wp
        ON wp.wp_customer_sk = c.c_customer_sk
    WHERE cs.cs_sold_date_sk BETWEEN 2450810 AND 2450830
      AND cs.cs_quantity >= 2
      AND cs.cs_ext_tax > 50.00
      AND cs.cs_ext_list_price BETWEEN 1000.00 AND 20000.00
    GROUP BY cs.cs_bill_customer_sk, cs.cs_ship_mode_sk, sm.sm_type, sm.sm_carrier, wp.wp_type
    HAVING SUM(cs.cs_net_profit) > 5000.00
)
SELECT
    s.cust_sk,
    c.c_first_name,
    c.c_last_name,
    s.ship_type,
    s.sm_carrier,
    s.web_page_type,
    s.total_net_paid,
    s.total_net_profit,
    s.sales_cnt,
    (
        SELECT COALESCE(SUM(wr.wr_return_amt), 0)
        FROM web_returns wr
        WHERE wr.wr_refunded_customer_sk = s.cust_sk
    ) AS total_return_amt,
    RANK() OVER (PARTITION BY s.ship_type ORDER BY s.total_net_profit DESC) AS profit_rank_in_ship_type
FROM sales_agg s
JOIN customer c
    ON s.cust_sk = c.c_customer_sk
WHERE EXISTS (
    SELECT 1
    FROM web_returns wr
    WHERE wr.wr_refunded_customer_sk = s.cust_sk
      AND wr.wr_return_amt > 0
)
ORDER BY s.total_net_profit DESC, profit_rank_in_ship_type
LIMIT 100
