WITH catalog_sales_agg AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        i.i_category,
        SUM(cs.cs_net_profit) AS catalog_net_profit,
        SUM(cs.cs_ext_sales_price) AS catalog_sales_amount,
        COUNT(DISTINCT cs.cs_order_number) AS catalog_orders
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    GROUP BY d.d_year, d.d_month_seq, i.i_category
),
web_sales_agg AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        i.i_category,
        SUM(ws.ws_net_profit) AS web_net_profit,
        SUM(ws.ws_ext_sales_price) AS web_sales_amount,
        COUNT(DISTINCT ws.ws_order_number) AS web_orders
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    GROUP BY d.d_year, d.d_month_seq, i.i_category
),
catalog_returns_agg AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        i.i_category,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_refunded_cash) AS total_refunded_cash,
        COUNT(DISTINCT cr.cr_order_number) AS return_orders
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    GROUP BY d.d_year, d.d_month_seq, i.i_category
),
inventory_agg AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        i.i_category,
        SUM(inv.inv_quantity_on_hand) AS total_inventory_on_hand
    FROM inventory inv
    JOIN date_dim d ON inv.inv_date_sk = d.d_date_sk
    JOIN item i ON inv.inv_item_sk = i.i_item_sk
    GROUP BY d.d_year, d.d_month_seq, i.i_category
)
SELECT
    COALESCE(cs.d_year, ws.d_year, cr.d_year, inv.d_year) AS year,
    COALESCE(cs.d_month_seq, ws.d_month_seq, cr.d_month_seq, inv.d_month_seq) AS month_seq,
    COALESCE(cs.i_category, ws.i_category, cr.i_category, inv.i_category) AS category,
    cs.catalog_net_profit,
    ws.web_net_profit,
    cr.total_return_amount,
    inv.total_inventory_on_hand
FROM catalog_sales_agg cs
FULL OUTER JOIN web_sales_agg ws
    ON cs.d_year = ws.d_year
    AND cs.d_month_seq = ws.d_month_seq
    AND cs.i_category = ws.i_category
FULL OUTER JOIN catalog_returns_agg cr
    ON COALESCE(cs.d_year, ws.d_year) = cr.d_year
    AND COALESCE(cs.d_month_seq, ws.d_month_seq) = cr.d_month_seq
    AND COALESCE(cs.i_category, ws.i_category) = cr.i_category
FULL OUTER JOIN inventory_agg inv
    ON COALESCE(cs.d_year, ws.d_year, cr.d_year) = inv.d_year
    AND COALESCE(cs.d_month_seq, ws.d_month_seq, cr.d_month_seq) = inv.d_month_seq
    AND COALESCE(cs.i_category, ws.i_category, cr.i_category) = inv.i_category
ORDER BY year, month_seq, category
