/*
Goal: Calculate the total net contribution (profit minus return loss) for each store‑promotion combination in the year 2001, broken down by customer gender and household buying potential, and flag whether the net is positive. The query joins all selected TPC‑DS tables using the defined surrogate‑key relationships, applies multiple filters, uses a CASE expression, a scalar subquery, and an EXISTS semi‑join, and finally limits the output to the top 100 rows.
*/
WITH base AS (
    SELECT
        s.s_store_id               AS store_id,
        p.p_promo_id               AS promo_id,
        d.d_year                   AS year,
        cd.cd_gender               AS gender,
        hd.hd_buy_potential        AS buy_potential,
        ib.ib_lower_bound          AS lower_income_bound,
        SUM(ss.ss_net_profit)          AS store_sales_profit,
        SUM(cs.cs_net_profit)          AS catalog_sales_profit,
        SUM(ws.ws_net_profit)          AS web_sales_profit,
        SUM(sr.sr_net_loss)            AS return_loss
    FROM store s
    JOIN store_sales ss
      ON ss.ss_store_sk = s.s_store_sk
    JOIN date_dim d
      ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN customer_demographics cd
      ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd
      ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
      ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN promotion p
      ON ss.ss_promo_sk = p.p_promo_sk
    JOIN catalog_sales cs
      ON cs.cs_promo_sk = p.p_promo_sk
     AND cs.cs_sold_date_sk = d.d_date_sk
    JOIN ship_mode sm
      ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN store_returns sr
      ON sr.sr_store_sk = s.s_store_sk
     AND sr.sr_ticket_number = ss.ss_ticket_number
    JOIN web_sales ws
      ON ws.ws_promo_sk = p.p_promo_sk
     AND ws.ws_sold_date_sk = d.d_date_sk
     AND ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE d.d_year = 2001
      AND cd.cd_gender = 'M'
      AND hd.hd_buy_potential IN ('Low', 'Medium')
      AND ib.ib_lower_bound >= 50000
      AND sm.sm_type = 'AIR'
      AND p.p_discount_active = 'Y'
    GROUP BY
        s.s_store_id,
        p.p_promo_id,
        d.d_year,
        cd.cd_gender,
        hd.hd_buy_potential,
        ib.ib_lower_bound
)
SELECT
    store_id,
    promo_id,
    year,
    gender,
    buy_potential,
    lower_income_bound,
    (store_sales_profit + catalog_sales_profit + web_sales_profit - return_loss) AS total_net,
    CASE
        WHEN (store_sales_profit + catalog_sales_profit + web_sales_profit - return_loss) > 0 THEN 'Positive'
        ELSE 'Non-Positive'
    END AS profit_flag,
    (SELECT COUNT(*) FROM promotion p2 WHERE p2.p_promo_id = base.promo_id) AS promo_occurrences
FROM base
WHERE EXISTS (
    SELECT 1
    FROM promotion p3
    WHERE p3.p_promo_id = base.promo_id
      AND p3.p_discount_active = 'Y'
)
ORDER BY total_net DESC
LIMIT 100
