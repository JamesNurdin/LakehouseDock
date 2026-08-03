/*
Goal: Analyze net loss from store and web returns by customer credit rating and household buying potential, categorise loss levels, and rank credit rating groups. The query joins all seven selected TPC‑DS tables using the permitted keys, re‑uses several tables under different aliases, includes a cross‑join with a small computed set, a scalar EXISTS sub‑query, a CASE expression, and a ranking window function. Results are limited to the top 100 rows.
*/
WITH flags AS (
    SELECT 1 AS flag UNION ALL SELECT 2 AS flag
),
joined_data AS (
    SELECT
        ss.ss_cdemo_sk,
        cd.cd_credit_rating,
        hd.hd_buy_potential,
        sr.sr_net_loss,
        wr.wr_net_loss
    FROM store_sales ss
    JOIN store_returns sr
        ON ss.ss_item_sk = sr.sr_item_sk
        AND ss.ss_ticket_number = sr.sr_ticket_number
    JOIN customer_demographics cd
        ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN web_returns wr
        ON ss.ss_ticket_number = wr.wr_order_number
    /* additional required joins */
    JOIN time_dim td_sold
        ON ss.ss_sold_time_sk = td_sold.t_time_sk
    JOIN time_dim td_ret
        ON sr.sr_return_time_sk = td_ret.t_time_sk
    JOIN time_dim td_web
        ON wr.wr_returned_time_sk = td_web.t_time_sk
    JOIN customer_demographics cd_ref
        ON wr.wr_refunded_cdemo_sk = cd_ref.cd_demo_sk
    JOIN household_demographics hd_ref
        ON wr.wr_refunded_hdemo_sk = hd_ref.hd_demo_sk
),
agg AS (
    SELECT
        jd.cd_credit_rating,
        jd.hd_buy_potential,
        SUM(COALESCE(jd.sr_net_loss, 0) + COALESCE(jd.wr_net_loss, 0)) AS total_net_loss
    FROM joined_data jd
    CROSS JOIN flags f
    WHERE f.flag = 1
      AND EXISTS (
          SELECT 1
          FROM store_returns r
          WHERE r.sr_cdemo_sk = jd.ss_cdemo_sk
            AND r.sr_net_loss > 0
      )
    GROUP BY jd.cd_credit_rating, jd.hd_buy_potential
)
SELECT
    a.cd_credit_rating,
    a.hd_buy_potential,
    a.total_net_loss,
    CASE
        WHEN a.total_net_loss > 10000 THEN 'High'
        WHEN a.total_net_loss > 5000  THEN 'Medium'
        ELSE 'Low'
    END AS loss_category,
    ROW_NUMBER() OVER (PARTITION BY a.cd_credit_rating ORDER BY a.total_net_loss DESC) AS loss_rank
FROM agg a
ORDER BY a.total_net_loss DESC
LIMIT 100
