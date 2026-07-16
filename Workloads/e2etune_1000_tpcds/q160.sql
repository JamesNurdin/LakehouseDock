WITH sales_agg AS (
    SELECT
        ws.ws_promo_sk,
        ws.ws_bill_customer_sk,
        SUM(ws.ws_net_profit) AS total_net_profit,
        SUM(ws.ws_ext_discount_amt) AS total_discount,
        COUNT(*) AS sales_cnt
    FROM web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE c.c_preferred_cust_flag = 'Y'
    GROUP BY ws.ws_promo_sk, ws.ws_bill_customer_sk
),
returns_agg AS (
    SELECT
        ws.ws_promo_sk,
        wr.wr_refunded_customer_sk AS customer_sk,
        SUM(wr.wr_net_loss) AS total_net_loss,
        SUM(wr.wr_return_amt) AS total_return_amt,
        COUNT(*) AS return_cnt
    FROM web_returns wr
    JOIN web_sales ws ON wr.wr_order_number = ws.ws_order_number
                     AND wr.wr_item_sk = ws.ws_item_sk
    JOIN customer c ON wr.wr_refunded_customer_sk = c.c_customer_sk
    WHERE c.c_preferred_cust_flag = 'Y'
    GROUP BY ws.ws_promo_sk, wr.wr_refunded_customer_sk
)
SELECT
    p.p_promo_id,
    p.p_promo_name,
    p.p_channel_email,
    SUM(s.total_net_profit) AS promo_net_profit,
    COALESCE(SUM(r.total_net_loss), 0) AS promo_net_loss,
    SUM(s.total_net_profit) - COALESCE(SUM(r.total_net_loss), 0) AS net_profit_after_returns,
    COUNT(DISTINCT s.ws_bill_customer_sk) AS distinct_customers,
    AVG(s.total_discount) AS avg_discount_per_customer,
    RANK() OVER (ORDER BY SUM(s.total_net_profit) DESC) AS profit_rank
FROM promotion p
LEFT JOIN sales_agg s ON p.p_promo_sk = s.ws_promo_sk
LEFT JOIN returns_agg r ON p.p_promo_sk = r.ws_promo_sk
WHERE p.p_discount_active = 'Y'
  AND p.p_start_date_sk BETWEEN 2450000 AND 2451500
GROUP BY p.p_promo_id, p.p_promo_name, p.p_channel_email
HAVING SUM(s.total_net_profit) > 10000
ORDER BY net_profit_after_returns DESC
LIMIT 10
