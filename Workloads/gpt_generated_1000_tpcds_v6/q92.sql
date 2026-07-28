WITH sales_agg AS (
    SELECT
        ss.ss_item_sk,
        i.i_item_desc,
        i.i_current_price,
        p.p_promo_id,
        p.p_channel_tv,
        SUM(ss.ss_net_profit) AS total_net_profit,
        COUNT(*) AS sales_cnt,
        AVG(ss.ss_quantity) AS avg_quantity,
        MAX(ss.ss_sold_date_sk) AS max_sold_date_sk
    FROM store_sales ss
    JOIN item i
        ON ss.ss_item_sk = i.i_item_sk
    JOIN promotion p
        ON ss.ss_promo_sk = p.p_promo_sk
    JOIN customer_demographics cd
        ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    WHERE ss.ss_net_profit > 0                                 -- profit must be positive
      AND i.i_current_price BETWEEN 20 AND 400                -- filter price range
      AND p.p_cost > 1500                                      -- expensive promotions only
      AND p.p_channel_tv = 'N'                                 -- TV channel not used
      AND i.i_rec_start_date >= DATE '2000-01-01'              -- item introduced after 2000
      AND i.i_rec_start_date <= DATE '2002-12-31'              -- and before 2003
    GROUP BY ss.ss_item_sk, i.i_item_desc, i.i_current_price, p.p_promo_id, p.p_channel_tv
),
final_agg AS (
    SELECT
        sa.p_promo_id,
        COUNT(DISTINCT sa.ss_item_sk) AS distinct_items_sold,
        SUM(sa.total_net_profit) AS promo_total_profit,
        AVG(sa.avg_quantity) AS promo_avg_quantity,
        MAX(sa.max_sold_date_sk) AS latest_sold_date_sk
    FROM sales_agg sa
    WHERE EXISTS (
        SELECT 1
        FROM store_returns sr
        JOIN store_sales ss2
            ON sr.sr_ticket_number = ss2.ss_ticket_number
           AND sr.sr_item_sk = ss2.ss_item_sk
        WHERE ss2.ss_item_sk = sa.ss_item_sk
          AND sr.sr_net_loss > 0                         -- only items that generated a store return loss
    )
      AND EXISTS (
        SELECT 1
        FROM catalog_returns cr
        JOIN warehouse w
            ON cr.cr_warehouse_sk = w.w_warehouse_sk
        JOIN call_center cc
            ON cr.cr_call_center_sk = cc.cc_call_center_sk
        WHERE cr.cr_item_sk = sa.ss_item_sk
          AND w.w_country = 'United States'               -- returns processed in US warehouses
          AND cc.cc_state = 'CA'                           -- call center located in California
          AND cr.cr_return_amount > 0                     -- only actual return amounts
      )
    GROUP BY sa.p_promo_id
    HAVING SUM(sa.total_net_profit) > 10000                 -- keep only high‑profit promotions
)
SELECT
    fa.p_promo_id,
    fa.distinct_items_sold,
    fa.promo_total_profit,
    fa.promo_avg_quantity,
    fa.latest_sold_date_sk
FROM final_agg fa
ORDER BY fa.promo_total_profit DESC
LIMIT 100
