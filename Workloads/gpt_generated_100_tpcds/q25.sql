WITH promo_sales AS (
    SELECT
        p.p_promo_sk,
        p.p_promo_id,
        p.p_promo_name,
        p.p_start_date_sk,
        p.p_end_date_sk,
        p.p_cost,
        p.p_response_target,
        p.p_channel_dmail,
        p.p_channel_email,
        p.p_channel_catalog,
        p.p_channel_tv,
        p.p_channel_radio,
        p.p_channel_press,
        p.p_channel_event,
        p.p_channel_demo,
        p.p_channel_details,
        p.p_purpose,
        p.p_discount_active,
        COUNT(ss.ss_ticket_number) AS num_transactions,
        SUM(ss.ss_quantity) AS total_quantity,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_ext_discount_amt) AS total_discount,
        SUM(ss.ss_net_paid) AS total_net_paid,
        SUM(ss.ss_net_profit) AS total_net_profit,
        AVG(ss.ss_sales_price) AS avg_sales_price,
        SUM(ss.ss_ext_sales_price) - SUM(ss.ss_ext_discount_amt) AS net_sales_after_discount
    FROM store_sales ss
    JOIN promotion p
        ON ss.ss_promo_sk = p.p_promo_sk
    WHERE p.p_discount_active = 'Y'
      AND ss.ss_sold_date_sk BETWEEN 2450000 AND 2459999
    GROUP BY
        p.p_promo_sk,
        p.p_promo_id,
        p.p_promo_name,
        p.p_start_date_sk,
        p.p_end_date_sk,
        p.p_cost,
        p.p_response_target,
        p.p_channel_dmail,
        p.p_channel_email,
        p.p_channel_catalog,
        p.p_channel_tv,
        p.p_channel_radio,
        p.p_channel_press,
        p.p_channel_event,
        p.p_channel_demo,
        p.p_channel_details,
        p.p_purpose,
        p.p_discount_active
    HAVING COUNT(ss.ss_ticket_number) >= 100
)
SELECT
    p_promo_id,
    p_promo_name,
    p_start_date_sk,
    p_end_date_sk,
    p_cost,
    p_response_target,
    p_channel_tv,
    p_channel_email,
    num_transactions,
    total_quantity,
    total_sales,
    total_discount,
    total_net_paid,
    total_net_profit,
    avg_sales_price,
    net_sales_after_discount,
    total_discount / nullif(total_sales, 0) AS discount_rate,
    total_net_profit / nullif(total_sales, 0) AS profit_margin,
    RANK() OVER (ORDER BY total_net_profit DESC) AS profit_rank
FROM promo_sales
ORDER BY total_net_profit DESC
LIMIT 100
