WITH
store_sales_agg AS (
    SELECT
        ss.ss_item_sk AS i_item_sk,
        SUM(ss.ss_ext_sales_price) AS store_sales_amount,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_txns
    FROM store_sales ss
    WHERE ss.ss_ext_sales_price > 0
    GROUP BY ss.ss_item_sk
),
web_sales_agg AS (
    SELECT
        ws.ws_item_sk AS i_item_sk,
        SUM(ws.ws_ext_sales_price) AS web_sales_amount,
        COUNT(DISTINCT ws.ws_order_number) AS web_txns
    FROM web_sales ws
    GROUP BY ws.ws_item_sk
),
item_sales AS (
    SELECT
        i.i_item_sk,
        i.i_item_id,
        i.i_category,
        i.i_color,
        i.i_units,
        i.i_manufact_id,
        COALESCE(ss.store_sales_amount, 0) AS store_sales_amount,
        COALESCE(ws.web_sales_amount, 0) AS web_sales_amount,
        COALESCE(ss.store_txns, 0) AS store_txns,
        COALESCE(ws.web_txns, 0) AS web_txns
    FROM item i
    LEFT JOIN store_sales_agg ss ON ss.i_item_sk = i.i_item_sk
    LEFT JOIN web_sales_agg ws ON ws.i_item_sk = i.i_item_sk
    WHERE i.i_color IN ('pale', 'sienna', 'papaya')
      AND i.i_units = 'Each'
      AND i.i_manufact_id IN (117, 26)
)
SELECT
    isales.i_item_sk,
    isales.i_item_id,
    isales.i_category,
    isales.i_color,
    isales.store_sales_amount,
    isales.web_sales_amount,
    (isales.store_sales_amount + isales.web_sales_amount) AS total_sales,
    latest_inv.inv_quantity_on_hand,
    RANK() OVER (PARTITION BY isales.i_category ORDER BY (isales.store_sales_amount + isales.web_sales_amount) DESC) AS category_rank,
    COUNT(*) OVER (PARTITION BY isales.i_category) AS category_item_count
FROM item_sales AS isales
CROSS JOIN LATERAL (
    SELECT inv_quantity_on_hand
    FROM inventory inv
    WHERE inv.inv_item_sk = isales.i_item_sk
      AND inv.inv_warehouse_sk = 1
    ORDER BY inv.inv_date_sk DESC
    LIMIT 1
) AS latest_inv
WHERE EXISTS (
    SELECT 1
    FROM store_sales ss
    JOIN customer_address ca
        ON ss.ss_addr_sk = ca.ca_address_sk
    WHERE ss.ss_item_sk = isales.i_item_sk
      AND ca.ca_state = 'CA'
)
AND NOT EXISTS (
    SELECT 1
    FROM web_returns wr
    WHERE wr.wr_item_sk = isales.i_item_sk
      AND wr.wr_return_quantity > 0
)
AND latest_inv.inv_quantity_on_hand > 0
ORDER BY total_sales DESC
LIMIT 100
