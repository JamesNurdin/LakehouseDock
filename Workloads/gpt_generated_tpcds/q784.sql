WITH sales AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_store_sk,
        ss.ss_ticket_number,
        ss.ss_item_sk,
        ss.ss_net_paid,
        ss.ss_net_profit,
        ss.ss_promo_sk,
        d.d_year,
        d.d_moy
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
),
returns AS (
    SELECT
        sr.sr_ticket_number,
        sr.sr_item_sk,
        sr.sr_store_sk,
        sr.sr_net_loss
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
),
sales_joined AS (
    SELECT
        s.ss_sold_date_sk,
        s.d_year,
        s.d_moy,
        s.ss_store_sk,
        st.s_store_name,
        s.ss_ticket_number,
        s.ss_item_sk,
        s.ss_net_paid,
        s.ss_net_profit,
        s.ss_promo_sk,
        p.p_promo_id,
        p.p_channel_tv
    FROM sales s
    JOIN store st ON s.ss_store_sk = st.s_store_sk
    JOIN promotion p ON s.ss_promo_sk = p.p_promo_sk
)
SELECT
    sj.d_year,
    sj.d_moy,
    sj.s_store_name,
    sj.p_promo_id,
    sj.p_channel_tv,
    SUM(sj.ss_net_paid) AS total_sales,
    SUM(sj.ss_net_profit) AS total_profit,
    SUM(COALESCE(r.sr_net_loss, 0)) AS total_return_loss,
    SUM(sj.ss_net_profit) - SUM(COALESCE(r.sr_net_loss, 0)) AS net_profit_after_returns
FROM sales_joined sj
LEFT JOIN returns r
    ON sj.ss_ticket_number = r.sr_ticket_number
    AND sj.ss_item_sk = r.sr_item_sk
    AND sj.ss_store_sk = r.sr_store_sk
GROUP BY
    sj.d_year,
    sj.d_moy,
    sj.s_store_name,
    sj.p_promo_id,
    sj.p_channel_tv
ORDER BY net_profit_after_returns DESC
LIMIT 10
