WITH filtered_catalog AS (
        SELECT
            cs.cs_order_number,
            cs.cs_sold_date_sk,
            cs.cs_ship_date_sk,
            cs.cs_bill_customer_sk,
            cs.cs_ship_customer_sk,
            cs.cs_call_center_sk,
            cs.cs_ext_sales_price,
            cs.cs_net_profit,
            cs.cs_quantity
        FROM catalog_sales cs
        JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
        JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
        WHERE d.d_year = 1912
          AND cc.cc_tax_percentage BETWEEN 0.05 AND 0.12
          AND cs.cs_quantity >= 2
          AND cs.cs_ext_sales_price >= 500
    ),
    filtered_store AS (
        SELECT
            ss.ss_ticket_number,
            ss.ss_sold_date_sk,
            ss.ss_customer_sk,
            ss.ss_ext_sales_price,
            ss.ss_net_profit,
            ss.ss_quantity
        FROM store_sales ss
        JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
        WHERE d.d_year = 1912
          AND ss.ss_quantity >= 1
          AND ss.ss_ext_sales_price > 200
    )
SELECT
    cc.cc_name,
    d_sold.d_year,
    d_sold.d_month_seq,
    cust_bill.c_first_name,
    cust_bill.c_last_name,
    SUM(fc.cs_ext_sales_price) AS total_catalog_sales,
    SUM(fs.ss_ext_sales_price) AS total_store_sales,
    AVG(fc.cs_net_profit) AS avg_catalog_profit,
    COUNT(DISTINCT fc.cs_order_number) AS distinct_orders,
    CASE
        WHEN SUM(fc.cs_net_profit) > 0 THEN 'POSITIVE'
        WHEN SUM(fc.cs_net_profit) < 0 THEN 'NEGATIVE'
        ELSE 'ZERO'
    END AS profit_category,
    SUM(COALESCE(wr.wr_net_loss, 0)) AS total_return_loss
FROM filtered_catalog fc
JOIN date_dim d_sold ON fc.cs_sold_date_sk = d_sold.d_date_sk
JOIN customer cust_bill ON fc.cs_bill_customer_sk = cust_bill.c_customer_sk
JOIN customer cust_ship ON fc.cs_ship_customer_sk = cust_ship.c_customer_sk
JOIN call_center cc ON fc.cs_call_center_sk = cc.cc_call_center_sk
LEFT JOIN web_returns wr ON wr.wr_order_number = fc.cs_order_number
LEFT JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
JOIN filtered_store fs ON fs.ss_customer_sk = cust_bill.c_customer_sk
    AND fs.ss_sold_date_sk = d_sold.d_date_sk
WHERE d_sold.d_month_seq BETWEEN 1200 AND 1220
  AND cust_bill.c_preferred_cust_flag = 'Y'
  AND cust_ship.c_birth_year IS NOT NULL AND cust_ship.c_birth_year < 1960
  AND (r.r_reason_desc = 'Damaged' OR r.r_reason_desc IS NULL)
GROUP BY
    cc.cc_name,
    d_sold.d_year,
    d_sold.d_month_seq,
    cust_bill.c_first_name,
    cust_bill.c_last_name
ORDER BY total_catalog_sales DESC
LIMIT 100
