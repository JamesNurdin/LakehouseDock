WITH sales_agg AS (
    SELECT
        i.i_item_sk,
        i.i_item_id,
        i.i_product_name,
        i.i_brand,
        i.i_category,
        inv.inv_warehouse_sk,
        inv.inv_quantity_on_hand,
        ca_store.ca_city AS store_city,
        ca_bill.ca_city AS bill_city,
        ca_ship.ca_city AS ship_city,
        SUM(ss.ss_net_paid) AS store_net_paid,
        SUM(ws.ws_net_paid) AS web_net_paid,
        SUM(ss.ss_net_paid) + SUM(ws.ws_net_paid) AS total_net_paid
    FROM item i
    JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
    JOIN store_sales ss ON ss.ss_item_sk = i.i_item_sk
    JOIN customer_address ca_store ON ss.ss_addr_sk = ca_store.ca_address_sk
    JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
    JOIN customer_address ca_bill ON ws.ws_bill_addr_sk = ca_bill.ca_address_sk
    JOIN customer_address ca_ship ON ws.ws_ship_addr_sk = ca_ship.ca_address_sk
    WHERE i.i_brand = 'Brand#12'
      AND i.i_category = 'Electronics'
      AND ca_store.ca_state = 'CA'
      AND ca_store.ca_gmt_offset = -5.00
      AND ca_bill.ca_city = 'Greenville'
      AND ca_ship.ca_city = 'Valley View'
      AND inv.inv_warehouse_sk IN (3, 4, 5)
      AND ss.ss_wholesale_cost > 20.00
      AND ws.ws_sales_price > 30.00
    GROUP BY
        i.i_item_sk,
        i.i_item_id,
        i.i_product_name,
        i.i_brand,
        i.i_category,
        inv.inv_warehouse_sk,
        inv.inv_quantity_on_hand,
        ca_store.ca_city,
        ca_bill.ca_city,
        ca_ship.ca_city
    HAVING SUM(ss.ss_net_paid) + SUM(ws.ws_net_paid) > 0
)
SELECT
    i_item_id,
    i_product_name,
    i_brand,
    i_category,
    inv_warehouse_sk,
    inv_quantity_on_hand,
    store_city,
    bill_city,
    ship_city,
    store_net_paid,
    web_net_paid,
    total_net_paid,
    RANK() OVER (PARTITION BY i_category ORDER BY total_net_paid DESC) AS category_rank,
    CASE
        WHEN total_net_paid > 200000 THEN 'Top'
        WHEN total_net_paid > 100000 THEN 'Medium'
        ELSE 'Low'
    END AS revenue_tier
FROM sales_agg
ORDER BY total_net_paid DESC
LIMIT 100
