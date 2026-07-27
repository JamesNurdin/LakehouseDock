/*
Goal: Compute per‑promotion, state, page type and hour level metrics that combine sales performance with aggregated web return amounts, applying multiple business filters.
*/
WITH returns_agg AS (
    SELECT
        wr_order_number,
        wr_returned_date_sk,
        wr_returned_time_sk,
        SUM(wr_return_amt) AS total_return_amt,
        SUM(wr_net_loss) AS total_net_loss,
        COUNT(*) AS return_cnt
    FROM web_returns
    WHERE wr_return_amt > 50
      AND wr_account_credit < 200
      AND wr_fee BETWEEN 0 AND 20
      AND wr_return_quantity >= 1
    GROUP BY wr_order_number, wr_returned_date_sk, wr_returned_time_sk
)
SELECT
    p.p_promo_name,
    ca.ca_state,
    wp.wp_type,
    t.t_hour,
    SUM(ws.ws_net_profit) AS sum_net_profit,
    SUM(r.total_return_amt) AS sum_return_amt,
    COUNT(DISTINCT ws.ws_order_number) AS orders_cnt
FROM returns_agg r
JOIN web_sales ws
    ON ws.ws_order_number = r.wr_order_number
JOIN time_dim t
    ON ws.ws_sold_time_sk = t.t_time_sk
JOIN promotion p
    ON ws.ws_promo_sk = p.p_promo_sk
JOIN customer_address ca
    ON ws.ws_bill_addr_sk = ca.ca_address_sk
JOIN web_page wp
    ON ws.ws_web_page_sk = wp.wp_web_page_sk
WHERE p.p_channel_dmail = 'Y'
  AND ca.ca_state = 'CA'
  AND wp.wp_autogen_flag = 'N'
  AND t.t_hour BETWEEN 8 AND 18
  AND ws.ws_quantity >= 2
GROUP BY p.p_promo_name, ca.ca_state, wp.wp_type, t.t_hour
HAVING SUM(ws.ws_net_profit) > 1000
ORDER BY sum_net_profit DESC
LIMIT 100
