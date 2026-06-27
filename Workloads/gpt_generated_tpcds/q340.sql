WITH store_agg AS (
    SELECT
        ss.ss_item_sk AS ss_item_sk,
        SUM(ss.ss_quantity) AS store_qty,
        SUM(ss.ss_ext_sales_price) AS store_sales_amount,
        SUM(ss.ss_net_profit) AS store_profit
    FROM store_sales ss
    GROUP BY ss.ss_item_sk
),
web_sales_agg AS (
    SELECT
        ws.ws_item_sk AS ws_item_sk,
        SUM(ws.ws_quantity) AS web_qty,
        SUM(ws.ws_ext_sales_price) AS web_sales_amount,
        SUM(ws.ws_net_profit) AS web_profit
    FROM web_sales ws
    GROUP BY ws.ws_item_sk
),
web_returns_agg AS (
    SELECT
        wr.wr_item_sk AS wr_item_sk,
        SUM(wr.wr_return_quantity) AS return_qty,
        SUM(wr.wr_return_amt_inc_tax) AS return_amount,
        SUM(wr.wr_net_loss) AS return_loss
    FROM web_returns wr
    GROUP BY wr.wr_item_sk
)
SELECT
    i.i_item_id,
    i.i_product_name,
    i.i_brand,
    i.i_category,
    COALESCE(sa.store_qty, 0) AS store_qty,
    COALESCE(sa.store_sales_amount, 0) AS store_sales_amount,
    COALESCE(sa.store_profit, 0) AS store_profit,
    COALESCE(wa.web_qty, 0) AS web_qty,
    COALESCE(wa.web_sales_amount, 0) AS web_sales_amount,
    COALESCE(wa.web_profit, 0) AS web_profit,
    COALESCE(ra.return_qty, 0) AS web_return_qty,
    COALESCE(ra.return_amount, 0) AS web_return_amount,
    COALESCE(ra.return_loss, 0) AS web_return_loss,
    (COALESCE(wa.web_qty, 0) - COALESCE(ra.return_qty, 0)) AS net_web_qty,
    (COALESCE(wa.web_sales_amount, 0) - COALESCE(ra.return_amount, 0)) AS net_web_sales_amount,
    (COALESCE(wa.web_profit, 0) - COALESCE(ra.return_loss, 0)) AS net_web_profit,
    (COALESCE(sa.store_profit, 0) + COALESCE(wa.web_profit, 0) - COALESCE(ra.return_loss, 0)) AS total_profit_across_channels,
    RANK() OVER (ORDER BY (COALESCE(sa.store_profit, 0) + COALESCE(wa.web_profit, 0) - COALESCE(ra.return_loss, 0)) DESC) AS profit_rank
FROM item i
LEFT JOIN store_agg sa ON sa.ss_item_sk = i.i_item_sk
LEFT JOIN web_sales_agg wa ON wa.ws_item_sk = i.i_item_sk
LEFT JOIN web_returns_agg ra ON ra.wr_item_sk = i.i_item_sk
ORDER BY total_profit_across_channels DESC
LIMIT 10
