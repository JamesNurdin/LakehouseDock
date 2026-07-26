SELECT
    ca.ca_state,
    p.p_promo_name,
    SUM(cs.cs_net_paid) AS total_sales_paid,
    SUM(cs.cs_net_profit) AS total_sales_profit,
    COALESCE(SUM(wr.wr_net_loss), 0) AS total_return_loss,
    SUM(cs.cs_net_profit) - COALESCE(SUM(wr.wr_net_loss), 0) AS net_profit,
    CASE WHEN SUM(cs.cs_net_profit) - COALESCE(SUM(wr.wr_net_loss), 0) > 0 THEN 'POSITIVE' ELSE 'NEGATIVE' END AS profit_flag,
    RANK() OVER (ORDER BY SUM(cs.cs_net_profit) - COALESCE(SUM(wr.wr_net_loss), 0) DESC) AS profit_rank
FROM catalog_sales cs
INNER JOIN customer_address ca
    ON cs.cs_bill_addr_sk = ca.ca_address_sk
INNER JOIN promotion p
    ON cs.cs_promo_sk = p.p_promo_sk
LEFT JOIN web_returns wr
    ON cs.cs_order_number = wr.wr_order_number
    AND ca.ca_address_sk = wr.wr_refunded_addr_sk
GROUP BY ca.ca_state, p.p_promo_name
ORDER BY net_profit DESC
LIMIT 20
