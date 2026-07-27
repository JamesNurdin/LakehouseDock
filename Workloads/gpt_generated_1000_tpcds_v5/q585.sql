WITH base AS (
    SELECT
        p.p_promo_sk,
        p.p_promo_id,
        ss.ss_ext_sales_price        AS ss_ext_sales_price,
        ss.ss_net_profit            AS ss_net_profit,
        sr.sr_return_amt            AS sr_return_amt,
        sr.sr_net_loss              AS sr_net_loss,
        ss.ss_quantity              AS ss_quantity,
        ss.ss_wholesale_cost        AS ss_wholesale_cost,
        sr.sr_return_quantity       AS sr_return_quantity,
        ss.ss_ticket_number         AS ss_ticket_number
    FROM store_sales ss
    JOIN promotion p
      ON ss.ss_promo_sk = p.p_promo_sk
    JOIN store_returns sr
      ON sr.sr_ticket_number = ss.ss_ticket_number
     AND sr.sr_item_sk = ss.ss_item_sk
    WHERE p.p_discount_active = 'N'
      AND p.p_channel_catalog = 'N'
      AND ss.ss_wholesale_cost > 10
      AND ss.ss_quantity >= 2
      AND sr.sr_return_quantity > 0
      AND EXISTS (
          SELECT 1
          FROM reason r
          WHERE r.r_reason_sk = sr.sr_reason_sk
            AND r.r_reason_desc LIKE '%damaged%'
      )
),
agg_per_promo AS (
    SELECT
        p_promo_sk,
        p_promo_id,
        SUM(ss_ext_sales_price) AS total_sales,
        SUM(ss_net_profit)     AS total_profit,
        SUM(sr_return_amt)     AS total_return_amt,
        SUM(sr_net_loss)       AS total_return_loss,
        COUNT(DISTINCT ss_ticket_number) AS num_tickets
    FROM base
    GROUP BY p_promo_sk, p_promo_id
)
SELECT
    a.p_promo_id,
    a.total_sales,
    a.total_profit,
    a.total_return_amt,
    a.total_return_loss,
    (a.total_profit - a.total_return_loss) AS net_gain,
    CASE WHEN a.total_sales > 10000 THEN 'High' ELSE 'Low' END AS sales_category,
    g.avg_net_gain
FROM (
    SELECT AVG(total_profit - total_return_loss) AS avg_net_gain
    FROM agg_per_promo
) g
CROSS JOIN agg_per_promo a
WHERE a.total_sales > 5000
ORDER BY net_gain DESC
LIMIT 100
