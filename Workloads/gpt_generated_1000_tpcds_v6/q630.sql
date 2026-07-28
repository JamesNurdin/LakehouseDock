WITH sales_agg AS (
    SELECT
        d.d_year,
        d.d_quarter_seq,
        p.p_promo_id,
        cp.cp_department,
        SUM(ss.ss_net_profit) AS total_store_profit,
        SUM(ws.ws_net_profit) AS total_web_profit,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_sales_cnt,
        COUNT(DISTINCT ws.ws_order_number) AS web_sales_cnt
    FROM
        store_sales ss
        JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
        JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
        JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
        JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
        JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
        JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
                               AND sr.sr_item_sk = ss.ss_item_sk
        JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
        JOIN web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk
                           AND ws.ws_sold_time_sk = t.t_time_sk
                           AND ws.ws_promo_sk = p.p_promo_sk
        JOIN catalog_page cp ON cp.cp_start_date_sk = d.d_date_sk
        JOIN inventory inv ON inv.inv_date_sk = d.d_date_sk
    WHERE
        d.d_year = 2001
        AND d.d_month_seq BETWEEN 1 AND 12
        AND ib.ib_upper_bound <= 50000
        AND p.p_discount_active = 'Y'
        AND r.r_reason_desc NOT LIKE '%warranty%'
        AND inv.inv_quantity_on_hand > 0
    GROUP BY
        d.d_year,
        d.d_quarter_seq,
        p.p_promo_id,
        cp.cp_department
    HAVING
        SUM(ss.ss_net_profit) + SUM(ws.ws_net_profit) > 100000
)
SELECT
    sa.d_year,
    sa.d_quarter_seq,
    sa.p_promo_id,
    sa.cp_department,
    sa.total_store_profit,
    sa.total_web_profit,
    (sa.total_store_profit + sa.total_web_profit) AS total_profit,
    RANK() OVER (PARTITION BY sa.d_year ORDER BY (sa.total_store_profit + sa.total_web_profit) DESC) AS profit_rank,
    (SELECT COUNT(*) FROM store_sales ss2 WHERE ss2.ss_net_paid > 5000) AS high_paid_sales_cnt
FROM
    sales_agg sa
ORDER BY
    sa.d_year,
    profit_rank
LIMIT 100
