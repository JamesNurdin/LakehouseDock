WITH sales_agg AS (
    SELECT
        ss.ss_ticket_number,
        ss.ss_customer_sk,
        ss.ss_sold_date_sk,
        ss.ss_sold_time_sk,
        ss.ss_item_sk,
        ss.ss_promo_sk,
        ss.ss_hdemo_sk,
        ss.ss_quantity,
        ss.ss_net_paid,
        ss.ss_net_profit,
        d.d_year,
        c.c_first_name,
        c.c_last_name,
        hd.hd_income_band_sk,
        p.p_promo_name,
        p.p_discount_active,
        -- running total of profit per customer ordered by the sales date
        SUM(ss.ss_net_profit) OVER (PARTITION BY ss.ss_customer_sk ORDER BY d.d_date ROWS UNBOUNDED PRECEDING) AS cum_profit,
        -- previous profit amount for the same customer
        LAG(ss.ss_net_profit) OVER (PARTITION BY ss.ss_customer_sk ORDER BY d.d_date) AS prev_net_profit
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    RIGHT JOIN web_site w ON w.web_open_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
)
SELECT
    sa.ss_ticket_number,
    sa.c_first_name,
    sa.c_last_name,
    sa.d_year,
    sa.p_promo_name,
    sa.hd_income_band_sk,
    sa.cum_profit,
    sa.prev_net_profit,
    sr.sr_return_quantity,
    sr.sr_net_loss,
    r.r_reason_desc,
    cp.cp_department,
    cp.cp_type,
    t.t_meal_time
FROM sales_agg sa
-- join return facts (left join to keep sales rows even without a return)
LEFT JOIN store_returns sr
    ON sr.sr_ticket_number = sa.ss_ticket_number
   AND sr.sr_item_sk = sa.ss_item_sk
-- reason for the return
LEFT JOIN reason r
    ON sr.sr_reason_sk = r.r_reason_sk
-- catalog page that was active on the sales date
LEFT JOIN catalog_page cp
    ON cp.cp_start_date_sk = sa.ss_sold_date_sk
   AND cp.cp_end_date_sk = sa.ss_sold_date_sk
-- additional date dimension joins to expose start/end dates of the catalog page (different aliases)
LEFT JOIN date_dim d_start
    ON cp.cp_start_date_sk = d_start.d_date_sk
LEFT JOIN date_dim d_end
    ON cp.cp_end_date_sk = d_end.d_date_sk
-- time of day dimension (different alias from any previous use)
LEFT JOIN time_dim t
    ON sa.ss_sold_time_sk = t.t_time_sk
WHERE sa.ss_ticket_number NOT IN (
    SELECT sr2.sr_ticket_number
    FROM store_returns sr2
    WHERE sr2.sr_return_quantity > 5
)
ORDER BY sa.cum_profit DESC
LIMIT 100
