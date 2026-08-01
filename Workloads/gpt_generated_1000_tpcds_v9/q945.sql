WITH joined_data AS (
    SELECT
        w.w_warehouse_name,
        w.w_city,
        c.c_customer_id,
        cs.cs_ext_sales_price,
        cs.cs_net_profit,
        COALESCE(wr.wr_return_amt, 0) AS wr_return_amt,
        i.inv_quantity_on_hand
    FROM warehouse w
    INNER JOIN catalog_sales cs
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    INNER JOIN customer c
        ON cs.cs_bill_customer_sk = c.c_customer_sk
    LEFT JOIN inventory i
        ON i.inv_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN store_sales ss
        ON ss.ss_customer_sk = c.c_customer_sk
    INNER JOIN web_sales ws
        ON ws.ws_bill_customer_sk = c.c_customer_sk
        AND ws.ws_warehouse_sk = w.w_warehouse_sk
    INNER JOIN web_site web
        ON ws.ws_web_site_sk = web.web_site_sk
    LEFT JOIN web_returns wr
        ON wr.wr_order_number = ws.ws_order_number
        AND wr.wr_item_sk = ws.ws_item_sk
        AND wr.wr_refunded_customer_sk = c.c_customer_sk
    WHERE w.w_city = 'Spring'
      AND c.c_preferred_cust_flag = 'Y'
      AND ws.ws_net_paid_inc_ship_tax > 1000
)
SELECT
    w_name,
    w_city,
    COUNT(DISTINCT customer_id) AS unique_customers,
    SUM(cs_ext_sales_price) AS total_sales,
    SUM(wr_return_amt) AS total_returns,
    AVG(cs_net_profit) AS avg_net_profit,
    CASE
        WHEN SUM(cs_ext_sales_price) > 100000 THEN 'High Sales'
        ELSE 'Regular Sales'
    END AS sales_category
FROM (
    SELECT
        w_warehouse_name AS w_name,
        w_city,
        c_customer_id AS customer_id,
        cs_ext_sales_price,
        cs_net_profit,
        wr_return_amt
    FROM joined_data
) sub
GROUP BY w_name, w_city
HAVING SUM(cs_ext_sales_price) > 0
ORDER BY total_sales DESC
LIMIT 100
