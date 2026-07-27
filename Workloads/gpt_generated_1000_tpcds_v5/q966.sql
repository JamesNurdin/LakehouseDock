WITH catalog_sales_agg AS (
    SELECT
        cs.cs_item_sk,
        i.i_item_id,
        i.i_manager_id,
        i.i_size,
        SUM(cs.cs_ext_sales_price) AS catalog_sales,
        SUM(cs.cs_ext_tax) AS catalog_tax,
        COUNT(*) AS catalog_orders
    FROM tpcds.catalog_sales cs
    JOIN tpcds.catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN tpcds.item i ON cs.cs_item_sk = i.i_item_sk
    WHERE i.i_size = 'medium'
      AND i.i_manager_id IN (21, 23)
      AND cs.cs_ext_tax > 20.00
    GROUP BY cs.cs_item_sk, i.i_item_id, i.i_manager_id, i.i_size
),
web_sales_agg AS (
    SELECT
        ws.ws_item_sk,
        i.i_item_id,
        i.i_manager_id,
        i.i_size,
        ws.ws_web_site_sk,
        SUM(ws.ws_ext_sales_price) AS web_sales,
        SUM(ws.ws_quantity) AS total_quantity,
        COUNT(*) AS web_orders
    FROM tpcds.web_sales ws
    JOIN tpcds.item i ON ws.ws_item_sk = i.i_item_sk
    JOIN tpcds.web_site wsit ON ws.ws_web_site_sk = wsit.web_site_sk
    WHERE i.i_size = 'medium'
      AND i.i_manager_id IN (21, 23)
      AND ws.ws_quantity >= 2
      AND wsit.web_state = 'CA'
    GROUP BY ws.ws_item_sk, i.i_item_id, i.i_manager_id, i.i_size, ws.ws_web_site_sk
),
combined_sales AS (
    SELECT
        cs.cs_item_sk AS item_sk,
        cs.i_item_id,
        cs.i_manager_id,
        cs.i_size,
        NULL AS web_site_sk,
        cs.catalog_sales AS sales_amount,
        cs.catalog_tax AS tax_amount,
        cs.catalog_orders AS orders_cnt,
        0 AS quantity
    FROM catalog_sales_agg cs
    UNION ALL
    SELECT
        ws.ws_item_sk,
        ws.i_item_id,
        ws.i_manager_id,
        ws.i_size,
        ws.ws_web_site_sk,
        ws.web_sales,
        0 AS tax_amount,
        ws.web_orders,
        ws.total_quantity
    FROM web_sales_agg ws
),
returns_agg AS (
    SELECT
        wr.wr_item_sk,
        SUM(wr.wr_return_amt) AS total_return_amount,
        COUNT(*) AS return_cnt
    FROM tpcds.web_returns wr
    WHERE EXISTS (
        SELECT 1 FROM tpcds.web_sales ws2
        WHERE ws2.ws_item_sk = wr.wr_item_sk
          AND ws2.ws_order_number = wr.wr_order_number
    )
    GROUP BY wr.wr_item_sk
),
inventory_agg AS (
    SELECT
        inv.inv_item_sk,
        SUM(inv.inv_quantity_on_hand) AS total_on_hand,
        AVG(inv.inv_quantity_on_hand) AS avg_on_hand
    FROM tpcds.inventory inv
    WHERE inv.inv_quantity_on_hand < 500
    GROUP BY inv.inv_item_sk
)
SELECT
    cs.item_sk,
    cs.i_item_id,
    cs.i_manager_id,
    cs.i_size,
    cs.web_site_sk,
    SUM(cs.sales_amount) AS total_sales,
    SUM(cs.tax_amount) AS total_tax,
    SUM(cs.quantity) AS total_quantity,
    SUM(cs.orders_cnt) AS total_orders,
    COALESCE(r.total_return_amount, 0) AS total_returns,
    COALESCE(i.total_on_hand, 0) AS inventory_on_hand,
    ROW_NUMBER() OVER (PARTITION BY cs.i_manager_id ORDER BY SUM(cs.sales_amount) DESC) AS revenue_rank,
    (SELECT AVG(avg_on_hand) FROM inventory_agg) AS overall_avg_inventory
FROM combined_sales cs
LEFT JOIN returns_agg r ON cs.item_sk = r.wr_item_sk
LEFT JOIN inventory_agg i ON cs.item_sk = i.inv_item_sk
WHERE EXISTS (
    SELECT 1 FROM tpcds.inventory inv_check
    WHERE inv_check.inv_item_sk = cs.item_sk
      AND inv_check.inv_quantity_on_hand > 100
)
GROUP BY
    cs.item_sk,
    cs.i_item_id,
    cs.i_manager_id,
    cs.i_size,
    cs.web_site_sk,
    r.total_return_amount,
    i.total_on_hand
HAVING SUM(cs.sales_amount) > 1000
ORDER BY total_sales DESC, revenue_rank
LIMIT 100
