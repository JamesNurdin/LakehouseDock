WITH base AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        d1.d_year,
        p.p_promo_name,
        cd.cd_gender,
        SUM(ss.ss_net_paid) AS total_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS distinct_tickets,
        AVG(ss.ss_quantity) AS avg_quantity,
        MAX(ss.ss_net_profit) AS max_profit,
        (
            SELECT COUNT(*)
            FROM store_returns sr2
            WHERE sr2.sr_store_sk = s.s_store_sk
              AND sr2.sr_returned_date_sk = d1.d_date_sk
        ) AS store_return_cnt
    FROM store_sales ss
    JOIN date_dim d1
      ON ss.ss_sold_date_sk = d1.d_date_sk
    JOIN time_dim t1
      ON ss.ss_sold_time_sk = t1.t_time_sk
    JOIN store s
      ON ss.ss_store_sk = s.s_store_sk
    JOIN promotion p
      ON ss.ss_promo_sk = p.p_promo_sk
    JOIN customer_demographics cd
      ON ss.ss_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN store_returns sr
      ON sr.sr_ticket_number = ss.ss_ticket_number
     AND sr.sr_item_sk = ss.ss_item_sk
    LEFT JOIN reason r
      ON sr.sr_reason_sk = r.r_reason_sk
    JOIN catalog_sales cs
      ON cs.cs_sold_date_sk = d1.d_date_sk
    JOIN call_center cc
      ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN ship_mode sm
      ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w
      ON cs.cs_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN web_returns wr
      ON wr.wr_returned_date_sk = d1.d_date_sk
    LEFT JOIN web_page wp
      ON wr.wr_web_page_sk = wp.wp_web_page_sk
    WHERE d1.d_year = 2001
      AND p.p_cost > 500
      AND s.s_state = 'CA'
      AND t1.t_hour BETWEEN 9 AND 17
    GROUP BY
        s.s_store_id,
        s.s_store_name,
        d1.d_year,
        p.p_promo_name,
        cd.cd_gender,
        s.s_store_sk,
        d1.d_date_sk
    HAVING SUM(ss.ss_net_paid) > 10000
)
SELECT DISTINCT *
FROM base
ORDER BY total_sales DESC
LIMIT 100
