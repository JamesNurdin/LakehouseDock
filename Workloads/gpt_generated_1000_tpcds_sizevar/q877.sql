WITH sampled_ws AS (
    SELECT ws_item_sk,
           ws_sold_date_sk,
           ws_bill_addr_sk,
           ws_ext_sales_price,
           ws_net_profit
    FROM web_sales TABLESAMPLE BERNOULLI (10)
    WHERE ws_quantity > 0
)
SELECT *
FROM (
    SELECT
        ws.ws_item_sk AS item_sk,
        d.d_date AS sale_date,
        ca.ca_state AS state,
        ws.ws_ext_sales_price AS total_sales,
        ws.ws_net_profit AS total_profit,
        CAST(NULL AS integer) AS quantity_on_hand,
        CAST(NULL AS integer) AS warehouse_sk
    FROM sampled_ws ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
    WHERE d.d_date BETWEEN DATE '1998-01-01' AND DATE '1998-12-31'
      AND ca.ca_gmt_offset = -5.00
    
    UNION ALL
    
    SELECT
        inv.inv_item_sk AS item_sk,
        d.d_date AS sale_date,
        CAST(NULL AS varchar) AS state,
        CAST(NULL AS decimal(7,2)) AS total_sales,
        CAST(NULL AS decimal(7,2)) AS total_profit,
        inv.inv_quantity_on_hand AS quantity_on_hand,
        inv.inv_warehouse_sk AS warehouse_sk
    FROM inventory inv
    FULL OUTER JOIN date_dim d ON inv.inv_date_sk = d.d_date_sk
    WHERE inv.inv_quantity_on_hand > 500
      AND d.d_quarter_name = '1998Q1'
) AS combined
WHERE EXISTS (
    SELECT 1
    FROM inventory i
    WHERE i.inv_item_sk = combined.item_sk
      AND i.inv_quantity_on_hand > 0
)
ORDER BY combined.sale_date DESC, combined.item_sk
OFFSET 0
LIMIT 100
