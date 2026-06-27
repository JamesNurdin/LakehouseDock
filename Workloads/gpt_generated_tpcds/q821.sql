WITH catalog_ret AS (
    SELECT
        cr_reason_sk,
        SUM(cr_return_quantity) AS catalog_return_qty,
        SUM(cr_return_amount) AS catalog_return_amt,
        SUM(cr_net_loss) AS catalog_net_loss,
        SUM(cs_net_profit) AS catalog_net_profit,
        AVG(cs_ext_discount_amt) AS catalog_avg_discount
    FROM catalog_returns
    JOIN catalog_sales
        ON catalog_returns.cr_item_sk = catalog_sales.cs_item_sk
        AND catalog_returns.cr_order_number = catalog_sales.cs_order_number
    GROUP BY cr_reason_sk
),
store_ret AS (
    SELECT
        sr_reason_sk,
        SUM(sr_return_quantity) AS store_return_qty,
        SUM(sr_return_amt) AS store_return_amt,
        SUM(sr_net_loss) AS store_net_loss
    FROM store_returns
    GROUP BY sr_reason_sk
),
web_ret AS (
    SELECT
        wr_reason_sk,
        SUM(wr_return_quantity) AS web_return_qty,
        SUM(wr_return_amt) AS web_return_amt,
        SUM(wr_net_loss) AS web_net_loss
    FROM web_returns
    GROUP BY wr_reason_sk
)
SELECT
    r.r_reason_desc,
    COALESCE(c.catalog_return_qty, 0) AS catalog_return_qty,
    COALESCE(s.store_return_qty, 0) AS store_return_qty,
    COALESCE(w.web_return_qty, 0) AS web_return_qty,
    COALESCE(c.catalog_return_amt, 0.0) AS catalog_return_amt,
    COALESCE(s.store_return_amt, 0.0) AS store_return_amt,
    COALESCE(w.web_return_amt, 0.0) AS web_return_amt,
    COALESCE(c.catalog_net_loss, 0.0) + COALESCE(s.store_net_loss, 0.0) + COALESCE(w.web_net_loss, 0.0) AS total_net_loss,
    COALESCE(c.catalog_net_profit, 0.0) AS catalog_net_profit,
    COALESCE(c.catalog_avg_discount, 0.0) AS catalog_avg_discount,
    COALESCE(c.catalog_return_qty, 0) + COALESCE(s.store_return_qty, 0) + COALESCE(w.web_return_qty, 0) AS total_return_qty,
    COALESCE(c.catalog_return_amt, 0.0) + COALESCE(s.store_return_amt, 0.0) + COALESCE(w.web_return_amt, 0.0) AS total_return_amt
FROM reason r
LEFT JOIN catalog_ret c ON r.r_reason_sk = c.cr_reason_sk
LEFT JOIN store_ret s ON r.r_reason_sk = s.sr_reason_sk
LEFT JOIN web_ret w ON r.r_reason_sk = w.wr_reason_sk
ORDER BY total_net_loss DESC
LIMIT 20
