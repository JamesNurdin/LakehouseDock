WITH sales_detail AS (
    SELECT
        ws.ws_order_number,
        ws.ws_net_paid_inc_ship,
        ws.ws_ext_discount_amt,
        ws.ws_list_price,
        ws.ws_sold_date_sk,
        ws.ws_bill_customer_sk,
        d.d_date,
        d.d_year,
        d.d_holiday,
        c.c_customer_id,
        c.c_birth_month
    FROM tpcds.web_sales ws
    JOIN tpcds.date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN tpcds.customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE d.d_date >= DATE '2001-01-01'
      AND d.d_date < DATE '2002-01-01'
      AND d.d_holiday = 'Y'
      AND ws.ws_net_paid_inc_ship > 1000
      AND ws.ws_list_price BETWEEN 20 AND 80
      AND c.c_birth_month IN (1, 2, 12)
)
SELECT
    sd.d_date,
    sd.c_customer_id,
    sd.ws_order_number,
    sd.ws_net_paid_inc_ship,
    CASE WHEN sd.ws_ext_discount_amt > 0 THEN 'Discounted' ELSE 'Full Price' END AS price_type,
    RANK() OVER (PARTITION BY sd.d_year ORDER BY sd.ws_net_paid_inc_ship DESC) AS sales_rank,
    (
        SELECT SUM(ws2.ws_net_profit)
        FROM tpcds.web_sales ws2
        JOIN tpcds.date_dim d2 ON ws2.ws_sold_date_sk = d2.d_date_sk
        WHERE d2.d_year = sd.d_year
    ) AS year_total_profit
FROM sales_detail sd
ORDER BY sales_rank ASC, sd.ws_net_paid_inc_ship DESC
LIMIT 100
