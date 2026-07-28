WITH sales_by_promo AS (
    SELECT
        p.p_promo_sk,
        p.p_promo_id,
        p.p_channel_dmail,
        p.p_channel_email,
        COUNT(*) AS txn_cnt,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_net_profit) AS total_profit,
        AVG(ss.ss_quantity) AS avg_qty
    FROM tpcds.store_sales ss
    JOIN tpcds.promotion p
        ON ss.ss_promo_sk = p.p_promo_sk
    WHERE ss.ss_net_paid_inc_tax > 1000                -- predicate 1
      AND ss.ss_ext_discount_amt BETWEEN 0 AND 500    -- predicate 2
      AND p.p_channel_dmail = 'Y'                     -- predicate 3
      AND p.p_end_date_sk > 2450100                   -- predicate 4
      AND ss.ss_quantity >= 1                         -- predicate 5
      AND ss.ss_sold_date_sk BETWEEN 2450000 AND 2450500 -- predicate 6
    GROUP BY p.p_promo_sk, p.p_promo_id, p.p_channel_dmail, p.p_channel_email
)
SELECT
    sp.p_promo_id,
    sp.p_channel_dmail,
    sp.txn_cnt,
    sp.total_sales,
    sp.total_profit,
    sp.avg_qty,
    CASE
        WHEN sp.total_sales > (SELECT AVG(total_sales) FROM sales_by_promo) THEN 'Above Avg'
        ELSE 'Below Avg'
    END AS sales_category
FROM sales_by_promo sp
WHERE sp.total_profit > 0
  AND EXISTS (
        SELECT 1
        FROM tpcds.promotion p2
        WHERE p2.p_promo_sk = sp.p_promo_sk
          AND p2.p_channel_email = 'Y'
    )
ORDER BY sp.total_sales DESC, sp.p_promo_id
LIMIT 100
