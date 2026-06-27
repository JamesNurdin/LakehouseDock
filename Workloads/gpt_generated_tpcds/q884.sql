WITH store_sales_cte AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        i.i_category,
        i.i_item_id,
        ss.ss_quantity AS quantity,
        ss.ss_net_paid AS net_paid,
        ss.ss_net_profit AS net_profit,
        ss.ss_item_sk AS item_sk,
        d.d_date AS sales_date
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE d.d_date >= DATE '2000-01-01' AND d.d_date < DATE '2001-01-01'
),
catalog_sales_cte AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        i.i_category,
        i.i_item_id,
        cs.cs_quantity AS quantity,
        cs.cs_net_paid AS net_paid,
        cs.cs_net_profit AS net_profit,
        cs.cs_item_sk AS item_sk,
        d.d_date AS sales_date
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    WHERE d.d_date >= DATE '2000-01-01' AND d.d_date < DATE '2001-01-01'
),
web_sales_cte AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        i.i_category,
        i.i_item_id,
        ws.ws_quantity AS quantity,
        ws.ws_net_paid AS net_paid,
        ws.ws_net_profit AS net_profit,
        ws.ws_item_sk AS item_sk,
        d.d_date AS sales_date
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE d.d_date >= DATE '2000-01-01' AND d.d_date < DATE '2001-01-01'
),
sales_union AS (
    SELECT d_year, d_month_seq, i_category, i_item_id, quantity, net_paid, net_profit, item_sk, sales_date
    FROM store_sales_cte
    UNION ALL
    SELECT d_year, d_month_seq, i_category, i_item_id, quantity, net_paid, net_profit, item_sk, sales_date
    FROM catalog_sales_cte
    UNION ALL
    SELECT d_year, d_month_seq, i_category, i_item_id, quantity, net_paid, net_profit, item_sk, sales_date
    FROM web_sales_cte
),
store_returns_cte AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        i.i_category,
        i.i_item_id,
        sr.sr_return_quantity AS return_quantity,
        sr.sr_net_loss AS net_loss,
        sr.sr_item_sk AS item_sk,
        d.d_date AS return_date
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    WHERE d.d_date >= DATE '2000-01-01' AND d.d_date < DATE '2001-01-01'
),
catalog_returns_cte AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        i.i_category,
        i.i_item_id,
        cr.cr_return_quantity AS return_quantity,
        cr.cr_net_loss AS net_loss,
        cr.cr_item_sk AS item_sk,
        d.d_date AS return_date
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    WHERE d.d_date >= DATE '2000-01-01' AND d.d_date < DATE '2001-01-01'
),
web_returns_cte AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        i.i_category,
        i.i_item_id,
        wr.wr_return_quantity AS return_quantity,
        wr.wr_net_loss AS net_loss,
        wr.wr_item_sk AS item_sk,
        d.d_date AS return_date
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    WHERE d.d_date >= DATE '2000-01-01' AND d.d_date < DATE '2001-01-01'
),
returns_union AS (
    SELECT d_year, d_month_seq, i_category, i_item_id, return_quantity, net_loss, item_sk, return_date
    FROM store_returns_cte
    UNION ALL
    SELECT d_year, d_month_seq, i_category, i_item_id, return_quantity, net_loss, item_sk, return_date
    FROM catalog_returns_cte
    UNION ALL
    SELECT d_year, d_month_seq, i_category, i_item_id, return_quantity, net_loss, item_sk, return_date
    FROM web_returns_cte
),
inventory_agg AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        i.i_category,
        i.i_item_id,
        AVG(inv.inv_quantity_on_hand) AS avg_inventory_on_hand,
        i.i_item_sk AS item_sk
    FROM inventory inv
    JOIN date_dim d ON inv.inv_date_sk = d.d_date_sk
    JOIN item i ON inv.inv_item_sk = i.i_item_sk
    WHERE d.d_date >= DATE '2000-01-01' AND d.d_date < DATE '2001-01-01'
    GROUP BY d.d_year, d.d_month_seq, i.i_category, i.i_item_id, i.i_item_sk
)
SELECT
    s.d_year,
    s.d_month_seq,
    s.i_category,
    s.i_item_id,
    SUM(s.quantity) AS total_quantity_sold,
    SUM(s.net_paid) AS total_net_paid,
    SUM(s.net_profit) AS total_net_profit,
    COALESCE(SUM(r.return_quantity), 0) AS total_quantity_returned,
    COALESCE(SUM(r.net_loss), 0) AS total_net_loss,
    SUM(s.net_profit) - COALESCE(SUM(r.net_loss), 0) AS net_profit_after_returns,
    MAX(i.avg_inventory_on_hand) AS avg_inventory_on_hand
FROM sales_union s
LEFT JOIN returns_union r
    ON s.item_sk = r.item_sk
    AND s.d_year = r.d_year
    AND s.d_month_seq = r.d_month_seq
LEFT JOIN inventory_agg i
    ON s.item_sk = i.item_sk
    AND s.d_year = i.d_year
    AND s.d_month_seq = i.d_month_seq
GROUP BY s.d_year, s.d_month_seq, s.i_category, s.i_item_id
ORDER BY s.d_year, s.d_month_seq, s.i_category, s.i_item_id
