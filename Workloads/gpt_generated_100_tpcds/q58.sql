WITH catalog_sales_agg AS (
    SELECT
        i.i_category,
        d.d_year,
        d.d_month_seq,
        SUM(cs.cs_net_paid) AS catalog_net_paid,
        SUM(cs.cs_net_profit) AS catalog_net_profit
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    GROUP BY i.i_category, d.d_year, d.d_month_seq
),
web_sales_agg AS (
    SELECT
        i.i_category,
        d.d_year,
        d.d_month_seq,
        SUM(ws.ws_net_paid) AS web_net_paid,
        SUM(ws.ws_net_profit) AS web_net_profit
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    GROUP BY i.i_category, d.d_year, d.d_month_seq
),
store_returns_agg AS (
    SELECT
        i.i_category,
        d.d_year,
        d.d_month_seq,
        SUM(sr.sr_return_amt_inc_tax) AS returns_amount,
        SUM(sr.sr_net_loss) AS returns_net_loss
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    GROUP BY i.i_category, d.d_year, d.d_month_seq
),
inventory_agg AS (
    SELECT
        i.i_category,
        d.d_year,
        d.d_month_seq,
        AVG(inv.inv_quantity_on_hand) AS avg_inventory_on_hand
    FROM inventory inv
    JOIN date_dim d ON inv.inv_date_sk = d.d_date_sk
    JOIN item i ON inv.inv_item_sk = i.i_item_sk
    GROUP BY i.i_category, d.d_year, d.d_month_seq
)
SELECT
    ca.i_category,
    ca.d_year,
    ca.d_month_seq,
    ca.catalog_net_paid,
    ca.catalog_net_profit,
    ws.web_net_paid,
    ws.web_net_profit,
    sr.returns_amount,
    sr.returns_net_loss,
    inv.avg_inventory_on_hand,
    (ca.catalog_net_profit + ws.web_net_profit - sr.returns_net_loss) AS total_net_profit
FROM catalog_sales_agg ca
LEFT JOIN web_sales_agg ws
    ON ca.i_category = ws.i_category
    AND ca.d_year = ws.d_year
    AND ca.d_month_seq = ws.d_month_seq
LEFT JOIN store_returns_agg sr
    ON ca.i_category = sr.i_category
    AND ca.d_year = sr.d_year
    AND ca.d_month_seq = sr.d_month_seq
LEFT JOIN inventory_agg inv
    ON ca.i_category = inv.i_category
    AND ca.d_year = inv.d_year
    AND ca.d_month_seq = inv.d_month_seq
ORDER BY ca.i_category, ca.d_year, ca.d_month_seq
