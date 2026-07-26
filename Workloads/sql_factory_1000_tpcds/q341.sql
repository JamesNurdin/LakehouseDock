SELECT
    i.i_item_sk,
    i.i_item_id,
    i.i_product_name,
    i.i_brand,
    SUM(ss.ss_net_profit) AS total_sales_profit,
    COALESCE(SUM(wr.wr_net_loss), 0) AS total_return_loss,
    SUM(ss.ss_net_profit) - COALESCE(SUM(wr.wr_net_loss), 0) AS net_profit_after_returns,
    COUNT(DISTINCT ss.ss_ticket_number) AS sales_transactions,
    COUNT(DISTINCT wr.wr_order_number) AS return_transactions,
    MAX(p.p_promo_name) AS latest_promo_name,
    CASE WHEN MAX(p.p_discount_active) = 'Y' THEN 'Active' ELSE 'Inactive' END AS promo_status,
    RANK() OVER (ORDER BY SUM(ss.ss_net_profit) - COALESCE(SUM(wr.wr_net_loss), 0) DESC) AS profit_rank
FROM item i
LEFT JOIN store_sales ss ON ss.ss_item_sk = i.i_item_sk
LEFT JOIN web_returns wr ON wr.wr_item_sk = i.i_item_sk
LEFT JOIN promotion p ON p.p_item_sk = i.i_item_sk
GROUP BY i.i_item_sk, i.i_item_id, i.i_product_name, i.i_brand
HAVING SUM(ss.ss_net_profit) > 0
ORDER BY net_profit_after_returns DESC
LIMIT 10
