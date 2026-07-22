WITH promotion_sales AS (
    SELECT
        p.p_promo_sk,
        p.p_promo_id,
        p.p_item_sk,
        SUM(ss.ss_ext_sales_price) AS store_sales_amount,
        SUM(ss.ss_ext_discount_amt) AS store_discount_amount,
        SUM(ss.ss_net_paid) AS store_net_paid,
        SUM(ss.ss_net_profit) AS store_net_profit,
        COUNT(DISTINCT ss.ss_customer_sk) AS store_customer_cnt
    FROM promotion p
    JOIN store_sales ss
        ON ss.ss_promo_sk = p.p_promo_sk
    WHERE ss.ss_ext_discount_amt > 500
      AND p.p_channel_email = 'N'
    GROUP BY p.p_promo_sk, p.p_promo_id, p.p_item_sk
),

catalog_sales_agg AS (
    SELECT
        p.p_promo_sk,
        SUM(cs.cs_ext_sales_price) AS catalog_sales_amount,
        SUM(cs.cs_ext_discount_amt) AS catalog_discount_amount,
        SUM(cs.cs_net_paid) AS catalog_net_paid,
        SUM(cs.cs_net_profit) AS catalog_net_profit,
        COUNT(*) AS catalog_transaction_cnt
    FROM promotion p
    JOIN catalog_sales cs
        ON cs.cs_promo_sk = p.p_promo_sk
    WHERE cs.cs_net_paid_inc_ship > 2000
    GROUP BY p.p_promo_sk
),

joined AS (
    SELECT
        ps.p_promo_sk,
        ps.p_promo_id,
        ps.p_item_sk,
        ps.store_sales_amount,
        ca.catalog_sales_amount,
        (ps.store_sales_amount + ca.catalog_sales_amount) AS total_sales_amount,
        (ps.store_discount_amount + ca.catalog_discount_amount) AS total_discount_amount,
        (ps.store_net_profit + ca.catalog_net_profit) AS total_net_profit,
        CASE
            WHEN (ps.store_discount_amount + ca.catalog_discount_amount) > 2000 THEN 'High Discount'
            ELSE 'Low Discount'
        END AS discount_category
    FROM promotion_sales ps
    JOIN catalog_sales_agg ca
        ON ps.p_promo_sk = ca.p_promo_sk
)
SELECT
    j.p_promo_id,
    j.p_item_sk,
    j.total_sales_amount,
    j.total_discount_amount,
    j.total_net_profit,
    j.discount_category,
    ROW_NUMBER() OVER (ORDER BY j.total_net_profit DESC) AS profit_rank,
    (SELECT AVG(ss_inner.ss_ext_discount_amt) FROM store_sales ss_inner) AS avg_store_discount_all,
    (SELECT MAX(cs_inner.cs_net_paid) FROM catalog_sales cs_inner WHERE cs_inner.cs_promo_sk = j.p_promo_sk) AS max_catalog_net_paid_for_promo
FROM joined j
WHERE j.total_sales_amount > 10000
ORDER BY profit_rank
LIMIT 100
