WITH catalog_agg AS (
    SELECT
        cr_item_sk AS item_sk,
        cr_returned_date_sk AS date_sk,
        SUM(cr_return_amount) AS cat_return_amount,
        SUM(cr_net_loss) AS cat_net_loss,
        SUM(cr_return_quantity) AS cat_quantity,
        COUNT(*) AS cat_returns,
        AVG(cr_fee) AS cat_avg_fee
    FROM catalog_returns
    WHERE cr_fee > 50.00
    GROUP BY cr_item_sk, cr_returned_date_sk
),
store_agg AS (
    SELECT
        sr_item_sk AS item_sk,
        sr_returned_date_sk AS date_sk,
        SUM(sr_return_amt) AS store_return_amount,
        SUM(sr_net_loss) AS store_net_loss,
        SUM(sr_return_quantity) AS store_quantity,
        COUNT(*) AS store_returns,
        AVG(sr_fee) AS store_avg_fee
    FROM store_returns
    WHERE sr_fee > 50.00
    GROUP BY sr_item_sk, sr_returned_date_sk
),
web_agg AS (
    SELECT
        wr_item_sk AS item_sk,
        wr_returned_date_sk AS date_sk,
        SUM(wr_return_amt) AS web_return_amount,
        SUM(wr_net_loss) AS web_net_loss,
        SUM(wr_return_quantity) AS web_quantity,
        COUNT(*) AS web_returns,
        AVG(wr_fee) AS web_avg_fee
    FROM web_returns
    WHERE wr_fee > 50.00
    GROUP BY wr_item_sk, wr_returned_date_sk
),
joined AS (
    SELECT
        COALESCE(c.item_sk, s.item_sk, w.item_sk) AS item_sk,
        COALESCE(c.date_sk, s.date_sk, w.date_sk) AS date_sk,
        COALESCE(c.cat_return_amount, 0) + COALESCE(s.store_return_amount, 0) + COALESCE(w.web_return_amount, 0) AS total_return_amount,
        COALESCE(c.cat_net_loss, 0) + COALESCE(s.store_net_loss, 0) + COALESCE(w.web_net_loss, 0) AS total_net_loss,
        COALESCE(c.cat_quantity, 0) + COALESCE(s.store_quantity, 0) + COALESCE(w.web_quantity, 0) AS total_quantity,
        COALESCE(c.cat_returns, 0) + COALESCE(s.store_returns, 0) + COALESCE(w.web_returns, 0) AS total_returns,
        (COALESCE(c.cat_avg_fee * c.cat_returns, 0) + COALESCE(s.store_avg_fee * s.store_returns, 0) + COALESCE(w.web_avg_fee * w.web_returns, 0)) /
            NULLIF(COALESCE(c.cat_returns, 0) + COALESCE(s.store_returns, 0) + COALESCE(w.web_returns, 0), 0) AS avg_fee,
        COALESCE(c.cat_returns, 0) AS catalog_returns,
        COALESCE(s.store_returns, 0) AS store_returns,
        COALESCE(w.web_returns, 0) AS web_returns
    FROM catalog_agg c
    FULL OUTER JOIN store_agg s
        ON c.item_sk = s.item_sk AND c.date_sk = s.date_sk
    FULL OUTER JOIN web_agg w
        ON COALESCE(c.item_sk, s.item_sk) = w.item_sk AND COALESCE(c.date_sk, s.date_sk) = w.date_sk
),
ranked AS (
    SELECT
        item_sk,
        date_sk,
        total_return_amount,
        total_net_loss,
        total_quantity,
        total_returns,
        avg_fee,
        catalog_returns,
        store_returns,
        web_returns,
        ROW_NUMBER() OVER (ORDER BY total_net_loss DESC) AS rn
    FROM joined
)
SELECT
    item_sk,
    date_sk,
    total_return_amount,
    total_net_loss,
    total_quantity,
    total_returns,
    avg_fee,
    catalog_returns,
    store_returns,
    web_returns
FROM ranked
WHERE rn <= 10
ORDER BY total_net_loss DESC
