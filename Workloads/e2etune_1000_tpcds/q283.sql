WITH sales_agg AS (
    SELECT
        ss.ss_store_sk,
        i.i_category,
        SUM(ss.ss_net_profit) AS total_sales_profit,
        SUM(ss.ss_ext_discount_amt) AS total_discount_amt,
        COUNT(DISTINCT ss.ss_promo_sk) AS promo_count,
        SUM(ss.ss_quantity) AS total_quantity_sold
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE ss.ss_sold_date_sk BETWEEN 2459000 AND 2459125
      AND i.i_category = 'Electronics'
      AND p.p_discount_active = 'Y'
      AND p.p_start_date_sk <= ss.ss_sold_date_sk
      AND p.p_end_date_sk >= ss.ss_sold_date_sk
    GROUP BY ss.ss_store_sk, i.i_category
),
returns_agg AS (
    SELECT
        sr.sr_store_sk,
        i.i_category,
        SUM(sr.sr_net_loss) AS total_return_loss,
        SUM(sr.sr_return_quantity) AS total_return_quantity
    FROM store_returns sr
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    WHERE sr.sr_returned_date_sk BETWEEN 2459000 AND 2459125
      AND i.i_category = 'Electronics'
    GROUP BY sr.sr_store_sk, i.i_category
)
SELECT
    s.s_store_name,
    s.s_city,
    s.s_state,
    COALESCE(sa.total_sales_profit, 0) - COALESCE(ra.total_return_loss, 0) AS net_profit_after_returns,
    COALESCE(sa.total_discount_amt, 0) AS total_discount_amt,
    CASE WHEN COALESCE(sa.promo_count, 0) > 0 THEN COALESCE(sa.total_discount_amt, 0) / sa.promo_count ELSE NULL END AS avg_discount_per_promo,
    COALESCE(sa.total_quantity_sold, 0) - COALESCE(ra.total_return_quantity, 0) AS net_quantity_sold,
    RANK() OVER (ORDER BY COALESCE(sa.total_sales_profit, 0) - COALESCE(ra.total_return_loss, 0) DESC) AS profit_rank
FROM sales_agg sa
LEFT JOIN returns_agg ra
    ON sa.ss_store_sk = ra.sr_store_sk
    AND sa.i_category = ra.i_category
JOIN store s
    ON s.s_store_sk = sa.ss_store_sk
ORDER BY net_profit_after_returns DESC
LIMIT 10
