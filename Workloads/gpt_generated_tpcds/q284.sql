WITH
    store_sales_agg AS (
        SELECT
            i.i_category,
            SUM(ss.ss_net_paid) AS store_net_paid,
            SUM(ss.ss_net_profit) AS store_net_profit,
            SUM(ss.ss_quantity) AS store_qty_sold
        FROM store_sales ss
        JOIN item i ON ss.ss_item_sk = i.i_item_sk
        GROUP BY i.i_category
    ),
    store_returns_agg AS (
        SELECT
            i.i_category,
            SUM(sr.sr_return_amt_inc_tax) AS store_return_amount,
            SUM(sr.sr_net_loss) AS store_return_loss,
            SUM(sr.sr_return_quantity) AS store_qty_returned
        FROM store_returns sr
        JOIN item i ON sr.sr_item_sk = i.i_item_sk
        GROUP BY i.i_category
    ),
    catalog_sales_agg AS (
        SELECT
            i.i_category,
            SUM(cs.cs_net_paid) AS catalog_net_paid,
            SUM(cs.cs_net_profit) AS catalog_net_profit,
            SUM(cs.cs_quantity) AS catalog_qty_sold
        FROM catalog_sales cs
        JOIN item i ON cs.cs_item_sk = i.i_item_sk
        GROUP BY i.i_category
    ),
    catalog_returns_agg AS (
        SELECT
            i.i_category,
            SUM(cr.cr_return_amt_inc_tax) AS catalog_return_amount,
            SUM(cr.cr_net_loss) AS catalog_return_loss,
            SUM(cr.cr_return_quantity) AS catalog_qty_returned
        FROM catalog_returns cr
        JOIN item i ON cr.cr_item_sk = i.i_item_sk
        GROUP BY i.i_category
    ),
    web_sales_agg AS (
        SELECT
            i.i_category,
            SUM(ws.ws_net_paid) AS web_net_paid,
            SUM(ws.ws_net_profit) AS web_net_profit,
            SUM(ws.ws_quantity) AS web_qty_sold
        FROM web_sales ws
        JOIN item i ON ws.ws_item_sk = i.i_item_sk
        GROUP BY i.i_category
    ),
    inventory_agg AS (
        SELECT
            i.i_category,
            SUM(inv.inv_quantity_on_hand) AS inventory_qty,
            SUM(inv.inv_quantity_on_hand * i.i_current_price) AS inventory_value
        FROM inventory inv
        JOIN item i ON inv.inv_item_sk = i.i_item_sk
        GROUP BY i.i_category
    )
SELECT
    COALESCE(s.i_category, sr.i_category, ca.i_category, cr.i_category, w.i_category, inv.i_category) AS category,
    COALESCE(s.store_net_paid, 0) - COALESCE(sr.store_return_amount, 0) AS net_paid_store,
    COALESCE(s.store_net_profit, 0) - COALESCE(sr.store_return_loss, 0) AS net_profit_store,
    COALESCE(ca.catalog_net_paid, 0) - COALESCE(cr.catalog_return_amount, 0) AS net_paid_catalog,
    COALESCE(ca.catalog_net_profit, 0) - COALESCE(cr.catalog_return_loss, 0) AS net_profit_catalog,
    COALESCE(w.web_net_paid, 0) AS net_paid_web,
    COALESCE(w.web_net_profit, 0) AS net_profit_web,
    COALESCE(inv.inventory_qty, 0) AS inventory_quantity,
    COALESCE(inv.inventory_value, 0) AS inventory_value,
    (COALESCE(s.store_net_paid, 0) - COALESCE(sr.store_return_amount, 0) +
     COALESCE(ca.catalog_net_paid, 0) - COALESCE(cr.catalog_return_amount, 0) +
     COALESCE(w.web_net_paid, 0)) AS total_net_paid,
    (COALESCE(s.store_net_profit, 0) - COALESCE(sr.store_return_loss, 0) +
     COALESCE(ca.catalog_net_profit, 0) - COALESCE(cr.catalog_return_loss, 0) +
     COALESCE(w.web_net_profit, 0)) AS total_net_profit
FROM store_sales_agg s
FULL OUTER JOIN store_returns_agg sr ON s.i_category = sr.i_category
FULL OUTER JOIN catalog_sales_agg ca ON COALESCE(s.i_category, sr.i_category) = ca.i_category
FULL OUTER JOIN catalog_returns_agg cr ON COALESCE(s.i_category, sr.i_category, ca.i_category) = cr.i_category
FULL OUTER JOIN web_sales_agg w ON COALESCE(s.i_category, sr.i_category, ca.i_category, cr.i_category) = w.i_category
FULL OUTER JOIN inventory_agg inv ON COALESCE(s.i_category, sr.i_category, ca.i_category, cr.i_category, w.i_category) = inv.i_category
ORDER BY total_net_profit DESC
LIMIT 20
