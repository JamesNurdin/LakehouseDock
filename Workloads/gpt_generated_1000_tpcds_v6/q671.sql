WITH sales_returns AS (
    SELECT
        s.s_store_id,
        p.p_promo_id,
        cd.cd_gender,
        i.i_category,
        SUM(ss.ss_net_profit) AS total_sales_profit,
        SUM(wr.wr_net_loss) AS total_return_loss,
        COUNT(DISTINCT ss.ss_ticket_number) AS sales_transactions,
        COUNT(DISTINCT wr.wr_order_number) AS return_transactions
    FROM store_sales ss
    JOIN item i
        ON ss.ss_item_sk = i.i_item_sk
    JOIN promotion p
        ON ss.ss_promo_sk = p.p_promo_sk
        AND p.p_item_sk = i.i_item_sk
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    JOIN customer_demographics cd
        ON ss.ss_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_returns wr
        ON wr.wr_item_sk = i.i_item_sk
        AND wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
    WHERE
        s.s_state = 'TX'                                         -- predicate 1
        AND p.p_discount_active = 'N'                             -- predicate 2
        AND i.i_units IN ('Pallet', 'Gram')                       -- predicate 3
        AND ss.ss_sold_date_sk BETWEEN 2450540 AND 2450600        -- predicate 4 (surrogate date key)
        AND cd.cd_gender = 'M'                                    -- predicate 5
    GROUP BY
        s.s_store_id,
        p.p_promo_id,
        cd.cd_gender,
        i.i_category
)
SELECT
    sr.s_store_id,
    sr.p_promo_id,
    sr.cd_gender,
    sr.i_category,
    sr.total_sales_profit,
    sr.total_return_loss,
    sr.sales_transactions,
    sr.return_transactions,
    CASE
        WHEN sr.total_return_loss = 0 THEN NULL
        ELSE sr.total_sales_profit / sr.total_return_loss
    END AS profit_to_loss_ratio
FROM sales_returns sr
WHERE
    sr.total_sales_profit > 1000
    AND (sr.total_return_loss IS NULL OR sr.total_return_loss < 5000)
    AND EXISTS (
        SELECT 1
        FROM promotion p2
        WHERE p2.p_promo_id = sr.p_promo_id
          AND p2.p_response_target > 0
    )
ORDER BY profit_to_loss_ratio DESC NULLS LAST
LIMIT 100
