WITH profit_by_manager AS (
    SELECT
        cc.cc_market_manager,
        p.p_channel_email,
        SUM(cs.cs_net_profit) AS total_profit
    FROM catalog_sales cs
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    WHERE cc.cc_division = 3
      AND p.p_discount_active = 'Y'
      AND t.t_hour BETWEEN 9 AND 17
      AND ca.ca_state = 'CA'
    GROUP BY cc.cc_market_manager, p.p_channel_email
)
SELECT
    cc_market_manager,
    p_channel_email,
    total_profit,
    RANK() OVER (PARTITION BY p_channel_email ORDER BY total_profit DESC) AS profit_rank
FROM profit_by_manager
ORDER BY total_profit DESC
