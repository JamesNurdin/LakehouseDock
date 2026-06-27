WITH store_sales_agg AS (
    SELECT
        ss.ss_item_sk AS item_sk,
        SUM(ss.ss_net_paid) AS store_net_paid,
        SUM(ss.ss_net_profit) AS store_net_profit,
        COUNT(*) AS store_sales_cnt
    FROM store_sales ss
    GROUP BY ss.ss_item_sk
),
store_returns_agg AS (
    SELECT
        sr.sr_item_sk AS item_sk,
        SUM(sr.sr_net_loss) AS store_returns_loss,
        COUNT(*) AS store_returns_cnt
    FROM store_returns sr
    GROUP BY sr.sr_item_sk
),
catalog_sales_agg AS (
    SELECT
        cs.cs_item_sk AS item_sk,
        SUM(cs.cs_net_paid) AS catalog_net_paid,
        SUM(cs.cs_net_profit) AS catalog_net_profit,
        COUNT(*) AS catalog_sales_cnt
    FROM catalog_sales cs
    GROUP BY cs.cs_item_sk
),
catalog_returns_agg AS (
    SELECT
        cr.cr_item_sk AS item_sk,
        SUM(cr.cr_net_loss) AS catalog_returns_loss,
        COUNT(*) AS catalog_returns_cnt
    FROM catalog_returns cr
    GROUP BY cr.cr_item_sk
),
web_sales_agg AS (
    SELECT
        ws.ws_item_sk AS item_sk,
        SUM(ws.ws_net_paid) AS web_net_paid,
        SUM(ws.ws_net_profit) AS web_net_profit,
        COUNT(*) AS web_sales_cnt
    FROM web_sales ws
    GROUP BY ws.ws_item_sk
),
web_returns_agg AS (
    SELECT
        wr.wr_item_sk AS item_sk,
        SUM(wr.wr_net_loss) AS web_returns_loss,
        COUNT(*) AS web_returns_cnt
    FROM web_returns wr
    GROUP BY wr.wr_item_sk
),
inventory_agg AS (
    SELECT
        inv.inv_item_sk AS item_sk,
        SUM(inv.inv_quantity_on_hand) AS quantity_on_hand
    FROM inventory inv
    GROUP BY inv.inv_item_sk
),
promo_agg AS (
    SELECT
        p.p_item_sk AS item_sk,
        SUM(p.p_cost) AS total_promo_cost,
        COUNT(*) AS promo_cnt
    FROM promotion p
    GROUP BY p.p_item_sk
)
SELECT
    i.i_item_sk,
    i.i_product_name,
    i.i_brand,
    i.i_category,
    COALESCE(ssa.store_net_paid, 0) AS store_net_paid,
    COALESCE(ssa.store_net_profit, 0) AS store_net_profit,
    COALESCE(sra.store_returns_loss, 0) AS store_returns_loss,
    COALESCE(csa.catalog_net_paid, 0) AS catalog_net_paid,
    COALESCE(csa.catalog_net_profit, 0) AS catalog_net_profit,
    COALESCE(cra.catalog_returns_loss, 0) AS catalog_returns_loss,
    COALESCE(wsa.web_net_paid, 0) AS web_net_paid,
    COALESCE(wsa.web_net_profit, 0) AS web_net_profit,
    COALESCE(wra.web_returns_loss, 0) AS web_returns_loss,
    COALESCE(ia.quantity_on_hand, 0) AS quantity_on_hand,
    COALESCE(pa.total_promo_cost, 0) AS total_promo_cost,
    COALESCE(ssa.store_sales_cnt, 0) + COALESCE(csa.catalog_sales_cnt, 0) + COALESCE(wsa.web_sales_cnt, 0) AS total_sales_transactions,
    COALESCE(sra.store_returns_cnt, 0) + COALESCE(cra.catalog_returns_cnt, 0) + COALESCE(wra.web_returns_cnt, 0) AS total_return_transactions
FROM item i
LEFT JOIN store_sales_agg ssa ON i.i_item_sk = ssa.item_sk
LEFT JOIN store_returns_agg sra ON i.i_item_sk = sra.item_sk
LEFT JOIN catalog_sales_agg csa ON i.i_item_sk = csa.item_sk
LEFT JOIN catalog_returns_agg cra ON i.i_item_sk = cra.item_sk
LEFT JOIN web_sales_agg wsa ON i.i_item_sk = wsa.item_sk
LEFT JOIN web_returns_agg wra ON i.i_item_sk = wra.item_sk
LEFT JOIN inventory_agg ia ON i.i_item_sk = ia.item_sk
LEFT JOIN promo_agg pa ON i.i_item_sk = pa.item_sk
ORDER BY i.i_item_sk
LIMIT 100
