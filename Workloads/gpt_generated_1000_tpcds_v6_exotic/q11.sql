WITH agg AS (
    SELECT
        w.w_warehouse_name,
        ca_bill.ca_county,
        ws.ws_sold_date_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        AVG(ws.ws_ext_discount_amt) AS avg_discount,
        COUNT(*) AS order_count,
        MIN(ws.ws_ext_ship_cost) AS min_ship_cost,
        MAX(ws.ws_ext_ship_cost) AS max_ship_cost
    FROM web_sales ws
    JOIN customer_address ca_bill
        ON ws.ws_bill_addr_sk = ca_bill.ca_address_sk
    JOIN warehouse w
        ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN inventory i
        ON i.inv_warehouse_sk = w.w_warehouse_sk
    WHERE ws.ws_ext_discount_amt > 5000
      AND ws.ws_ext_ship_cost < 2000
      AND ws.ws_ship_customer_sk IN (9482918, 7015489)
      AND ca_bill.ca_county = 'Maricopa County'
      AND w.w_state = 'CA'
      AND i.inv_quantity_on_hand >= 100
    GROUP BY w.w_warehouse_name, ca_bill.ca_county, ws.ws_sold_date_sk
)
SELECT
    w_warehouse_name,
    ca_county,
    ws_sold_date_sk,
    total_sales,
    avg_discount,
    order_count,
    min_ship_cost,
    max_ship_cost,
    SUM(total_sales) OVER (
        PARTITION BY w_warehouse_name
        ORDER BY total_sales DESC
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cumulative_sales,
    RANK() OVER (
        PARTITION BY w_warehouse_name
        ORDER BY total_sales DESC
    ) AS sales_rank
FROM agg
ORDER BY total_sales DESC
LIMIT 100
