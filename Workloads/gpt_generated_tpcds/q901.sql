WITH
    store_sales_agg AS (
        SELECT
            d.d_year,
            d.d_month_seq,
            p.p_promo_id,
            p.p_channel_email,
            SUM(ss.ss_net_paid) AS total_net_paid,
            SUM(ss.ss_net_profit) AS total_net_profit,
            COUNT(DISTINCT ss.ss_customer_sk) AS distinct_customers,
            SUM(ss.ss_quantity) AS total_quantity
        FROM store_sales ss
        JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
        JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
        GROUP BY d.d_year, d.d_month_seq, p.p_promo_id, p.p_channel_email
    ),
    store_returns_agg AS (
        SELECT
            d.d_year,
            d.d_month_seq,
            p.p_promo_id,
            p.p_channel_email,
            SUM(sr.sr_net_loss) AS total_net_loss,
            SUM(sr.sr_return_quantity) AS total_return_qty
        FROM store_returns sr
        JOIN store_sales ss ON sr.sr_item_sk = ss.ss_item_sk
                               AND sr.sr_ticket_number = ss.ss_ticket_number
        JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
        JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
        GROUP BY d.d_year, d.d_month_seq, p.p_promo_id, p.p_channel_email
    )
SELECT
    s.d_year,
    s.d_month_seq,
    s.p_promo_id,
    s.p_channel_email,
    s.total_net_paid,
    COALESCE(r.total_net_loss, 0) AS total_net_loss,
    s.total_net_profit,
    s.distinct_customers,
    s.total_quantity,
    COALESCE(r.total_return_qty, 0) AS total_return_qty,
    (s.total_net_paid - COALESCE(r.total_net_loss, 0)) AS net_revenue_after_returns
FROM store_sales_agg s
LEFT JOIN store_returns_agg r
    ON s.d_year = r.d_year
   AND s.d_month_seq = r.d_month_seq
   AND s.p_promo_id = r.p_promo_id
   AND s.p_channel_email = r.p_channel_email
ORDER BY s.d_year, s.d_month_seq, net_revenue_after_returns DESC
