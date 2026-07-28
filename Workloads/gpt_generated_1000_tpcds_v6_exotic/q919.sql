WITH base AS (
    SELECT
        d_sold.d_year AS year,
        i.i_category AS category,
        w.w_state AS state,
        cs.cs_ext_sales_price AS catalog_sales_price,
        cs.cs_quantity AS catalog_qty,
        cr.cr_net_loss AS return_net_loss,
        ws.ws_ext_sales_price AS web_sales_price,
        ws.ws_quantity AS web_qty
    FROM catalog_sales cs
    JOIN date_dim d_sold ON cs.cs_sold_date_sk = d_sold.d_date_sk
    JOIN date_dim d_ship ON cs.cs_ship_date_sk = d_ship.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN catalog_returns cr
        ON cr.cr_order_number = cs.cs_order_number
        AND cr.cr_item_sk = cs.cs_item_sk
        AND cr.cr_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN web_sales ws
        ON ws.ws_item_sk = cs.cs_item_sk
        AND ws.ws_warehouse_sk = w.w_warehouse_sk
        AND ws.ws_sold_date_sk = cs.cs_sold_date_sk
    WHERE d_sold.d_year = 2001
      AND i.i_brand_id IN (6008007, 8007005)
      AND w.w_state = 'CA'
      AND cs.cs_quantity > 5
),
joined_data AS (
    SELECT
        year,
        category,
        state,
        SUM(catalog_sales_price) AS total_catalog_sales,
        SUM(COALESCE(web_sales_price, 0)) AS total_web_sales,
        SUM(catalog_qty) AS total_catalog_qty,
        SUM(COALESCE(web_qty, 0)) AS total_web_qty,
        SUM(COALESCE(return_net_loss, 0)) AS total_return_loss
    FROM base
    GROUP BY year, category, state
)
SELECT
    year,
    category,
    state,
    total_catalog_sales,
    total_web_sales,
    total_return_loss,
    (total_catalog_sales + total_web_sales - total_return_loss) AS net_revenue,
    (total_catalog_qty + total_web_qty) AS total_quantity
FROM joined_data
WHERE (total_catalog_sales + total_web_sales - total_return_loss) > 50000
ORDER BY net_revenue DESC
LIMIT 100
