WITH
    store_sales_agg AS (
        SELECT d.d_date AS sales_date,
               sum(ss.ss_net_paid)   AS store_net_paid,
               sum(ss.ss_net_profit) AS store_net_profit
        FROM store_sales ss
        JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
        GROUP BY d.d_date
    ),
    web_sales_agg AS (
        SELECT d.d_date AS sales_date,
               sum(ws.ws_net_paid)   AS web_net_paid,
               sum(ws.ws_net_profit) AS web_net_profit
        FROM web_sales ws
        JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
        GROUP BY d.d_date
    ),
    catalog_sales_agg AS (
        SELECT d.d_date AS sales_date,
               sum(cs.cs_net_paid)   AS catalog_net_paid,
               sum(cs.cs_net_profit) AS catalog_net_profit
        FROM catalog_sales cs
        JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
        GROUP BY d.d_date
    ),
    store_returns_agg AS (
        SELECT d.d_date AS return_date,
               sum(sr.sr_net_loss)          AS store_return_loss,
               sum(sr.sr_return_amt_inc_tax) AS store_return_amount
        FROM store_returns sr
        JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
        GROUP BY d.d_date
    ),
    inventory_agg AS (
        SELECT d.d_date AS inv_date,
               sum(inv.inv_quantity_on_hand) AS total_inventory
        FROM inventory inv
        JOIN date_dim d ON inv.inv_date_sk = d.d_date_sk
        GROUP BY d.d_date
    )
SELECT
    d.d_date AS sales_date,
    ss.store_net_paid,
    ss.store_net_profit,
    ws.web_net_paid,
    ws.web_net_profit,
    cs.catalog_net_paid,
    cs.catalog_net_profit,
    sr.store_return_loss,
    sr.store_return_amount,
    inv.total_inventory
FROM date_dim d
LEFT JOIN store_sales_agg ss   ON d.d_date = ss.sales_date
LEFT JOIN web_sales_agg ws     ON d.d_date = ws.sales_date
LEFT JOIN catalog_sales_agg cs ON d.d_date = cs.sales_date
LEFT JOIN store_returns_agg sr ON d.d_date = sr.return_date
LEFT JOIN inventory_agg inv    ON d.d_date = inv.inv_date
WHERE d.d_date BETWEEN DATE '2022-01-01' AND DATE '2022-12-31'
ORDER BY d.d_date
