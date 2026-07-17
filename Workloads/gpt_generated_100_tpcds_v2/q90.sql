WITH store_sales_agg AS (
    SELECT
        p.p_promo_sk,
        p.p_promo_id,
        p.p_promo_name,
        i.i_category AS item_category,
        i.i_brand AS item_brand,
        SUM(ss.ss_ext_sales_price) AS store_sales_amount,
        SUM(ss.ss_net_profit) AS store_net_profit
    FROM store_sales ss
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN item i ON p.p_item_sk = i.i_item_sk
    GROUP BY p.p_promo_sk, p.p_promo_id, p.p_promo_name, i.i_category, i.i_brand
),
catalog_sales_agg AS (
    SELECT
        p.p_promo_sk,
        p.p_promo_id,
        p.p_promo_name,
        i.i_category AS item_category,
        i.i_brand AS item_brand,
        SUM(cs.cs_ext_sales_price) AS catalog_sales_amount,
        SUM(cs.cs_net_profit) AS catalog_net_profit
    FROM catalog_sales cs
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN item i ON p.p_item_sk = i.i_item_sk
    GROUP BY p.p_promo_sk, p.p_promo_id, p.p_promo_name, i.i_category, i.i_brand
),
returns_agg AS (
    SELECT
        p.p_promo_sk,
        p.p_promo_id,
        p.p_promo_name,
        i.i_category AS item_category,
        i.i_brand AS item_brand,
        SUM(cr.cr_return_amount) AS returns_amount,
        SUM(cr.cr_net_loss) AS returns_net_loss
    FROM catalog_returns cr
    JOIN catalog_sales cs
        ON cr.cr_order_number = cs.cs_order_number
       AND cr.cr_item_sk = cs.cs_item_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN item i ON p.p_item_sk = i.i_item_sk
    GROUP BY p.p_promo_sk, p.p_promo_id, p.p_promo_name, i.i_category, i.i_brand
)
SELECT
    COALESCE(s.p_promo_id, c.p_promo_id, r.p_promo_id) AS promotion_id,
    COALESCE(s.p_promo_name, c.p_promo_name, r.p_promo_name) AS promotion_name,
    COALESCE(s.item_category, c.item_category, r.item_category) AS item_category,
    COALESCE(s.item_brand, c.item_brand, r.item_brand) AS item_brand,
    COALESCE(s.store_sales_amount, 0) + COALESCE(c.catalog_sales_amount, 0) AS total_sales_amount,
    COALESCE(s.store_net_profit, 0) + COALESCE(c.catalog_net_profit, 0) AS total_net_profit_before_returns,
    COALESCE(r.returns_amount, 0) AS total_returns_amount,
    COALESCE(r.returns_net_loss, 0) AS total_returns_loss,
    (COALESCE(s.store_net_profit, 0) + COALESCE(c.catalog_net_profit, 0) - COALESCE(r.returns_net_loss, 0)) AS net_profit_after_returns,
    RANK() OVER (ORDER BY (COALESCE(s.store_net_profit, 0) + COALESCE(c.catalog_net_profit, 0) - COALESCE(r.returns_net_loss, 0)) DESC) AS profit_rank,
    SUM(COALESCE(s.store_net_profit, 0) + COALESCE(c.catalog_net_profit, 0) - COALESCE(r.returns_net_loss, 0))
        OVER (ORDER BY (COALESCE(s.store_net_profit, 0) + COALESCE(c.catalog_net_profit, 0) - COALESCE(r.returns_net_loss, 0)) DESC
              ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_profit
FROM store_sales_agg s
FULL OUTER JOIN catalog_sales_agg c ON s.p_promo_sk = c.p_promo_sk
FULL OUTER JOIN returns_agg r ON COALESCE(s.p_promo_sk, c.p_promo_sk) = r.p_promo_sk
WHERE COALESCE(s.store_sales_amount, 0) + COALESCE(c.catalog_sales_amount, 0) > 0
ORDER BY net_profit_after_returns DESC
LIMIT 100
