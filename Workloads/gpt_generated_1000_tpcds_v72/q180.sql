WITH base AS (
    SELECT
        i.i_item_sk,
        i.i_item_id,
        i.i_product_name,
        i.i_category,
        i.i_category_id,
        i.i_current_price,
        i.i_rec_end_date,
        ss.ss_quantity,
        ss.ss_ext_tax,
        ss.ss_ext_discount_amt,
        ss.ss_net_paid_inc_tax,
        ss.ss_net_profit,
        p.p_promo_name,
        ROW_NUMBER() OVER (PARTITION BY i.i_category ORDER BY ss.ss_net_profit DESC) AS profit_rank
    FROM tpcds.store_sales ss
    JOIN tpcds.item i
        ON ss.ss_item_sk = i.i_item_sk
    JOIN tpcds.promotion p
        ON ss.ss_promo_sk = p.p_promo_sk
        AND p.p_item_sk = i.i_item_sk
    WHERE i.i_category_id IN (1, 2, 3)
      AND i.i_current_price BETWEEN 10 AND 100
      AND ss.ss_ext_tax < 500
      AND ss.ss_ext_discount_amt > 100
      AND p.p_channel_email = 'N'
      AND i.i_rec_end_date > DATE '2000-01-01'
),
high AS (
    SELECT * FROM base WHERE profit_rank <= 10
),
low AS (
    SELECT * FROM base WHERE profit_rank > 10 AND i_category_id = 2
)
SELECT
    h.i_item_id,
    h.i_product_name,
    h.i_category,
    h.i_current_price,
    h.ss_quantity,
    h.ss_net_paid_inc_tax,
    h.ss_net_profit,
    h.p_promo_name,
    h.profit_rank
FROM high h
WHERE NOT EXISTS (
    SELECT 1 FROM tpcds.promotion p2
    WHERE p2.p_item_sk = h.i_item_sk
      AND p2.p_discount_active = 'Y'
)
UNION ALL
SELECT
    l.i_item_id,
    l.i_product_name,
    l.i_category,
    l.i_current_price,
    l.ss_quantity,
    l.ss_net_paid_inc_tax,
    l.ss_net_profit,
    l.p_promo_name,
    l.profit_rank
FROM low l
WHERE NOT EXISTS (
    SELECT 1 FROM tpcds.promotion p2
    WHERE p2.p_item_sk = l.i_item_sk
      AND p2.p_discount_active = 'Y'
)
ORDER BY profit_rank, i_item_id
LIMIT 100
