WITH cs AS (
    SELECT
        cs.cs_order_number,
        cs.cs_sold_time_sk,
        cs.cs_bill_customer_sk,
        cs.cs_item_sk,
        cs.cs_warehouse_sk,
        cs.cs_quantity,
        cs.cs_net_paid_inc_ship_tax,
        cs.cs_sales_price,
        cs.cs_net_profit
    FROM catalog_sales cs
    WHERE cs.cs_net_paid_inc_ship_tax > 2000
      AND cs.cs_quantity BETWEEN 1 AND 20
      AND cs.cs_sales_price > 100
),
ws AS (
    SELECT
        ws.ws_order_number,
        ws.ws_sold_time_sk,
        ws.ws_bill_customer_sk,
        ws.ws_item_sk,
        ws.ws_warehouse_sk,
        ws.ws_net_profit,
        ws.ws_sales_price
    FROM web_sales ws
    WHERE ws.ws_sales_price > 150
)
SELECT
    c.c_customer_id,
    i.i_category,
    w.w_warehouse_name,
    t.t_hour,
    site.web_name,
    SUM(cs.cs_net_paid_inc_ship_tax) AS total_net_paid,
    AVG(ws.ws_net_profit) AS avg_web_profit,
    COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
    CASE
        WHEN SUM(cs.cs_quantity) > 100 THEN 'High Volume'
        ELSE 'Low Volume'
    END AS volume_category,
    COUNT(DISTINCT CASE WHEN cs.cs_quantity > 5 THEN cs.cs_order_number END) AS large_orders_cnt
FROM cs
JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
JOIN item i ON cs.cs_item_sk = i.i_item_sk
JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
JOIN web_sales ws ON ws.ws_bill_customer_sk = c.c_customer_sk
    AND ws.ws_item_sk = i.i_item_sk
    AND ws.ws_warehouse_sk = w.w_warehouse_sk
    AND ws.ws_sold_time_sk = t.t_time_sk
JOIN web_site site ON ws.ws_web_site_sk = site.web_site_sk
WHERE i.i_brand = 'BrandX'
  AND w.w_warehouse_sq_ft > 600000
  AND t.t_hour BETWEEN 9 AND 17
  AND site.web_country = 'United States'
  AND EXISTS (
        SELECT 1
        FROM store_returns sr
        WHERE sr.sr_customer_sk = c.c_customer_sk
          AND sr.sr_return_amt > 500
          AND sr.sr_item_sk = i.i_item_sk
    )
GROUP BY
    c.c_customer_id,
    i.i_category,
    w.w_warehouse_name,
    t.t_hour,
    site.web_name
ORDER BY total_net_paid DESC
LIMIT 100
