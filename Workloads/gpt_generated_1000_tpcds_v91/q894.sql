WITH customer_sales AS (
    SELECT
        c.c_customer_sk,
        c.c_customer_id,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        AVG(ws.ws_net_paid_inc_tax) AS avg_net_paid_inc_tax,
        COUNT(*) AS sales_count
    FROM customer c
    JOIN web_sales ws
        ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE
        ws.ws_net_paid_inc_tax > 500.00
        AND ws.ws_net_paid_inc_ship < 5000.00
        AND ws.ws_quantity >= 1
        AND ws.ws_ship_addr_sk IN (5101605, 1202391, 2716335)
        AND c.c_current_cdemo_sk <> 965059
        AND c.c_preferred_cust_flag = 'Y'
        AND c.c_birth_year BETWEEN 1950 AND 1990
    GROUP BY
        c.c_customer_sk,
        c.c_customer_id
)
SELECT
    cs.c_customer_sk,
    cs.c_customer_id,
    cs.total_sales,
    cs.avg_net_paid_inc_tax,
    cs.sales_count,
    cs.total_sales / cs.sales_count AS avg_sale_per_transaction,
    ROUND(cs.total_sales, 2) AS rounded_total_sales
FROM customer_sales cs
WHERE NOT EXISTS (
    SELECT 1
    FROM web_sales ws2
    WHERE ws2.ws_bill_customer_sk = cs.c_customer_sk
      AND ws2.ws_ext_discount_amt > 100.00
)
  AND cs.total_sales > (SELECT AVG(total_sales) FROM customer_sales)
ORDER BY cs.total_sales DESC, cs.c_customer_id ASC
OFFSET 0
LIMIT 100
