/*
Goal: Identify the most profitable store‑promotion combinations after filtering for active discount promotions, recent end dates, high sales, and modest return costs. The query joins promotion, store_sales, and store_returns, filters on five+ predicates, aggregates sales and returns per store and promotion, computes net profit, ranks the combinations by profit, and returns the top 100.
*/
WITH joined_data AS (
    SELECT
        ss.ss_store_sk                     AS store_sk,
        p.p_promo_name                     AS promo_name,
        ss.ss_net_paid_inc_tax             AS net_paid_inc_tax,
        ss.ss_net_profit                   AS net_profit,
        sr.sr_return_ship_cost             AS return_ship_cost,
        sr.sr_net_loss                     AS return_net_loss,
        p.p_purpose                        AS promo_purpose,
        p.p_channel_event                  AS promo_channel_event,
        p.p_end_date_sk                    AS promo_end_date_sk
    FROM tpcds.store_sales ss
    JOIN tpcds.promotion p
        ON ss.ss_promo_sk = p.p_promo_sk
    JOIN tpcds.store_returns sr
        ON sr.sr_item_sk = ss.ss_item_sk
        AND sr.sr_ticket_number = ss.ss_ticket_number
    WHERE p.p_purpose = 'Discount'
      AND p.p_channel_event = 'N'
      AND p.p_end_date_sk BETWEEN 2450300 AND 2450400
      AND ss.ss_net_paid_inc_tax > 1000
      AND sr.sr_return_ship_cost < 500
      AND sr.sr_reversed_charge > 10
)
,
aggregated AS (
    SELECT
        store_sk,
        promo_name,
        SUM(net_paid_inc_tax)          AS total_sales,
        SUM(return_ship_cost)          AS total_return_ship_cost,
        SUM(net_profit) - SUM(return_net_loss) AS net_profit
    FROM joined_data
    GROUP BY store_sk, promo_name
)
SELECT
    store_sk,
    promo_name,
    total_sales,
    total_return_ship_cost,
    net_profit,
    RANK() OVER (ORDER BY net_profit DESC) AS profit_rank
FROM aggregated
ORDER BY profit_rank
LIMIT 100
