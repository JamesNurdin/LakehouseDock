WITH catalog_sales_base AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_sold_time_sk,
        cs.cs_item_sk,
        cs.cs_warehouse_sk,
        cs.cs_bill_addr_sk,
        cs.cs_ship_addr_sk,
        cs.cs_order_number,
        cs.cs_quantity,
        cs.cs_ext_sales_price,
        cs.cs_net_profit
    FROM catalog_sales cs
)
SELECT
    w.w_warehouse_name,
    i.i_brand,
    i.i_color,
    CASE WHEN SUM(cs.cs_net_profit) > 0 THEN 'POS' ELSE 'NEG' END AS profit_flag,
    SUM(cs.cs_ext_sales_price) AS total_sales,
    COUNT(DISTINCT cs.cs_order_number) AS orders,
    AVG(cs.cs_quantity) AS avg_quantity,
    COUNT(DISTINCT sr.sr_ticket_number) AS return_tickets,
    COUNT(DISTINCT ss.ss_ticket_number) AS sold_tickets
FROM catalog_sales_base cs
JOIN item i
    ON cs.cs_item_sk = i.i_item_sk
JOIN warehouse w
    ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN time_dim t_sold
    ON cs.cs_sold_time_sk = t_sold.t_time_sk
JOIN customer_address ca_bill
    ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
JOIN customer_address ca_ship
    ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
LEFT JOIN store_sales ss
    ON ss.ss_item_sk = cs.cs_item_sk
    AND ss.ss_sold_time_sk = cs.cs_sold_time_sk
LEFT JOIN store_returns sr
    ON sr.sr_ticket_number = ss.ss_ticket_number
    AND sr.sr_item_sk = ss.ss_item_sk
JOIN time_dim t_return
    ON sr.sr_return_time_sk = t_return.t_time_sk
JOIN item i2
    ON sr.sr_item_sk = i2.i_item_sk
WHERE t_sold.t_shift = 'first'
  AND i.i_color = 'red'
  AND EXISTS (
        SELECT 1
        FROM store_sales ss2
        WHERE ss2.ss_item_sk = cs.cs_item_sk
          AND ss2.ss_quantity > 5
      )
GROUP BY w.w_warehouse_name, i.i_brand, i.i_color
ORDER BY total_sales DESC
LIMIT 100
