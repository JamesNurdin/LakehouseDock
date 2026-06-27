WITH sales AS (
    SELECT i.i_item_sk,
           i.i_category,
           i.i_brand,
           SUM(cs.cs_ext_sales_price) AS total_sales,
           SUM(cs.cs_net_paid) AS total_net_paid,
           SUM(cs.cs_net_profit) AS total_profit,
           SUM(cs.cs_ext_discount_amt) AS total_discount
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    GROUP BY i.i_item_sk, i.i_category, i.i_brand
),
catalog_ret AS (
    SELECT i.i_item_sk,
           SUM(cr.cr_return_amount) AS total_catalog_return,
           SUM(cr.cr_net_loss) AS total_catalog_loss
    FROM catalog_returns cr
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    GROUP BY i.i_item_sk
),
store_ret AS (
    SELECT i.i_item_sk,
           SUM(sr.sr_return_amt) AS total_store_return,
           SUM(sr.sr_net_loss) AS total_store_loss
    FROM store_returns sr
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    GROUP BY i.i_item_sk
),
web_ret AS (
    SELECT i.i_item_sk,
           SUM(wr.wr_return_amt) AS total_web_return,
           SUM(wr.wr_net_loss) AS total_web_loss
    FROM web_returns wr
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    GROUP BY i.i_item_sk
),
inv AS (
    SELECT i.i_item_sk,
           SUM(inv.inv_quantity_on_hand) AS total_inventory
    FROM inventory inv
    JOIN item i ON inv.inv_item_sk = i.i_item_sk
    GROUP BY i.i_item_sk
),
promo AS (
    SELECT i.i_item_sk,
           COUNT(*) AS promo_count,
           SUM(p.p_cost) AS total_promo_cost
    FROM promotion p
    JOIN item i ON p.p_item_sk = i.i_item_sk
    GROUP BY i.i_item_sk
)
SELECT
    i.i_item_sk,
    i.i_product_name,
    i.i_category,
    i.i_brand,
    COALESCE(s.total_sales, 0) AS total_sales,
    COALESCE(s.total_profit, 0) AS total_profit,
    COALESCE(cr.total_catalog_return, 0) AS total_catalog_return,
    COALESCE(sr.total_store_return, 0) AS total_store_return,
    COALESCE(wr.total_web_return, 0) AS total_web_return,
    COALESCE(cr.total_catalog_loss, 0) + COALESCE(sr.total_store_loss, 0) + COALESCE(wr.total_web_loss, 0) AS total_return_loss,
    COALESCE(iq.total_inventory, 0) AS total_inventory,
    COALESCE(p.promo_count, 0) AS promo_count,
    COALESCE(p.total_promo_cost, 0) AS total_promo_cost,
    (COALESCE(s.total_sales, 0) - (COALESCE(cr.total_catalog_return, 0) + COALESCE(sr.total_store_return, 0) + COALESCE(wr.total_web_return, 0))) AS net_sales_after_returns,
    (COALESCE(s.total_profit, 0) - (COALESCE(cr.total_catalog_loss, 0) + COALESCE(sr.total_store_loss, 0) + COALESCE(wr.total_web_loss, 0))) AS net_profit_after_returns
FROM item i
LEFT JOIN sales s ON i.i_item_sk = s.i_item_sk
LEFT JOIN catalog_ret cr ON i.i_item_sk = cr.i_item_sk
LEFT JOIN store_ret sr ON i.i_item_sk = sr.i_item_sk
LEFT JOIN web_ret wr ON i.i_item_sk = wr.i_item_sk
LEFT JOIN inv iq ON i.i_item_sk = iq.i_item_sk
LEFT JOIN promo p ON i.i_item_sk = p.i_item_sk
WHERE COALESCE(s.total_sales, 0) > 0
ORDER BY net_profit_after_returns DESC
LIMIT 20
