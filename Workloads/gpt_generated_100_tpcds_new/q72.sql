WITH base AS (
    SELECT
        t.t_time_sk,
        t.t_hour,
        t.t_meal_time,
        ss.ss_sold_date_sk,
        ss.ss_ticket_number,
        ss.ss_quantity,
        ss.ss_net_paid,
        ss.ss_net_profit,
        ss.ss_promo_sk,
        ss.ss_hdemo_sk,
        sr.sr_return_time_sk,
        sr.sr_net_loss,
        sr.sr_reason_sk,
        cs.cs_sales_price,
        cs.cs_quantity,
        cs.cs_ext_sales_price,
        ws.ws_order_number,
        ws.ws_quantity AS ws_quantity,
        ws.ws_net_paid AS ws_net_paid,
        ws.ws_promo_sk,
        wr.wr_net_loss AS wr_net_loss,
        wr.wr_reason_sk,
        hd.hd_demo_sk,
        hd.hd_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        p.p_promo_sk,
        p.p_channel_demo,
        p.p_purpose,
        r.r_reason_sk,
        r.r_reason_desc
    FROM time_dim t
    JOIN store_sales ss
        ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN store_returns sr
        ON sr.sr_return_time_sk = t.t_time_sk
        AND sr.sr_ticket_number = ss.ss_ticket_number
    JOIN catalog_sales cs
        ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN web_sales ws
        ON ws.ws_sold_time_sk = t.t_time_sk
    JOIN web_returns wr
        ON wr.wr_returned_time_sk = t.t_time_sk
        AND wr.wr_order_number = ws.ws_order_number
    JOIN promotion p
        ON p.p_promo_sk = ss.ss_promo_sk
    JOIN household_demographics hd
        ON hd.hd_demo_sk = ss.ss_hdemo_sk
    JOIN income_band ib
        ON ib.ib_income_band_sk = hd.hd_income_band_sk
    JOIN reason r
        ON r.r_reason_sk = sr.sr_reason_sk
)
SELECT
    t_hour,
    t_meal_time,
    p_purpose,
    ib_lower_bound,
    ib_upper_bound,
    COUNT(DISTINCT ss_ticket_number) AS orders_count,
    SUM(ss_net_paid) AS total_store_sales,
    SUM(sr_net_loss) AS total_store_returns_loss,
    AVG(cs_sales_price) AS avg_catalog_sales_price,
    SUM(ws_net_paid) AS total_web_sales,
    SUM(wr_net_loss) AS total_web_returns_loss,
    MIN(ss_net_profit) AS min_store_profit,
    MAX(ss_net_profit) AS max_store_profit
FROM base
WHERE t_hour = 14
  AND t_meal_time = 'Dinner'
  AND p_channel_demo = 'N'
  AND ib_lower_bound >= 30000
  AND EXISTS (
        SELECT 1 FROM promotion p2
        WHERE p2.p_promo_sk = base.p_promo_sk
          AND p2.p_discount_active = 'Y'
    )
GROUP BY
    t_hour,
    t_meal_time,
    p_purpose,
    ib_lower_bound,
    ib_upper_bound
ORDER BY
    total_store_sales DESC
LIMIT 100
