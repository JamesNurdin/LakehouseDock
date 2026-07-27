WITH base AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        p.p_promo_name,
        d.d_year,
        d.d_month_seq,
        hd.hd_income_band_sk,
        SUM(cs.cs_net_profit)               AS catalog_net_profit,
        SUM(ss.ss_net_profit)               AS store_net_profit,
        -SUM(sr.sr_net_loss)                AS returns_net_gain
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN store_sales ss ON ss.ss_sold_date_sk = d.d_date_sk
        AND ss.ss_sold_time_sk = t.t_time_sk
        AND ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
        AND sr.sr_store_sk = s.s_store_sk
        AND sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    WHERE d.d_year = 2001
      AND s.s_manager IN ('Scott Mclaughlin', 'John Mccoy')
      AND p.p_discount_active = 'Y'
      AND hd.hd_vehicle_count >= 2
      AND EXISTS (
          SELECT 1
          FROM (SELECT DISTINCT p2.p_promo_sk FROM promotion p2 WHERE p2.p_discount_active = 'Y') dp
          WHERE dp.p_promo_sk = p.p_promo_sk
      )
    GROUP BY
        s.s_store_id,
        s.s_store_name,
        p.p_promo_name,
        d.d_year,
        d.d_month_seq,
        hd.hd_income_band_sk
),
avg_total AS (
    SELECT AVG(catalog_net_profit + store_net_profit + returns_net_gain) AS avg_net
    FROM base
)
SELECT
    COALESCE(b.store_id, 'ALL')          AS store_id,
    COALESCE(b.promo_name, 'ALL')        AS promo_name,
    b.month_seq,
    SUM(b.total_net)                     AS sum_total_net,
    COUNT(*)                             AS rows_cnt
FROM (
    SELECT
        s_store_id   AS store_id,
        p_promo_name AS promo_name,
        d_month_seq  AS month_seq,
        (catalog_net_profit + store_net_profit + returns_net_gain) AS total_net
    FROM base
) b
CROSS JOIN avg_total a
WHERE b.total_net > a.avg_net
GROUP BY GROUPING SETS (
    (store_id, promo_name, month_seq),
    (store_id, promo_name),
    (store_id),
    ()
)
HAVING SUM(b.total_net) > 0
ORDER BY store_id, promo_name, month_seq
