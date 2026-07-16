SELECT
    s.s_store_name,
    d.d_year,
    i.i_category,
    SUM(ss.ss_net_profit) AS total_store_profit,
    SUM(ss.ss_ext_sales_price) AS total_store_sales,
    SUM(COALESCE(cr.cr_return_amount, 0)) AS total_catalog_returns,
    SUM(COALESCE(ws.ws_net_profit, 0)) AS total_web_profit,
    SUM(COALESCE(ws.ws_ext_sales_price, 0)) AS total_web_sales,
    SUM(COALESCE(sr.sr_net_loss, 0)) AS total_store_returns_loss
FROM store_sales ss
JOIN store s ON ss.ss_store_sk = s.s_store_sk
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
JOIN item i ON ss.ss_item_sk = i.i_item_sk
LEFT JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
LEFT JOIN catalog_sales cs ON ss.ss_item_sk = cs.cs_item_sk AND ss.ss_sold_date_sk = cs.cs_sold_date_sk
LEFT JOIN catalog_returns cr ON cs.cs_order_number = cr.cr_order_number
LEFT JOIN web_sales ws ON ss.ss_item_sk = ws.ws_item_sk AND ss.ss_sold_date_sk = ws.ws_sold_date_sk
LEFT JOIN web_returns wr ON ws.ws_order_number = wr.wr_order_number
LEFT JOIN store_returns sr ON ss.ss_ticket_number = sr.sr_ticket_number
WHERE d.d_year = 2000
  AND i.i_category = 'Sports'
  AND (p.p_discount_active = 'Y' OR p.p_discount_active IS NULL)
GROUP BY
    s.s_store_name,
    d.d_year,
    i.i_category
ORDER BY total_store_profit DESC
LIMIT 100
