WITH filtered_store_sales AS (
    SELECT *
    FROM store_sales TABLESAMPLE BERNOULLI (10)
)
SELECT
    s.s_store_name,
    s.s_city,
    CASE WHEN ss.ss_net_profit > 0 THEN 'Profitable' ELSE 'Loss' END AS profit_flag,
    COUNT(DISTINCT ss.ss_ticket_number) AS order_count,
    SUM(ss.ss_net_profit) AS total_profit,
    AVG(cs.cs_ext_sales_price) AS avg_catalog_sales,
    MAX(ss.ss_net_paid) AS max_net_paid
FROM filtered_store_sales ss
JOIN customer c_bill ON ss.ss_customer_sk = c_bill.c_customer_sk
JOIN household_demographics hd_bill ON ss.ss_hdemo_sk = hd_bill.hd_demo_sk
JOIN customer_address ca_bill ON ss.ss_addr_sk = ca_bill.ca_address_sk
JOIN store s ON ss.ss_store_sk = s.s_store_sk
JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number AND sr.sr_item_sk = ss.ss_item_sk
JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
JOIN customer c_ret ON sr.sr_customer_sk = c_ret.c_customer_sk
JOIN household_demographics hd_ret ON sr.sr_hdemo_sk = hd_ret.hd_demo_sk
JOIN customer_address ca_ret ON sr.sr_addr_sk = ca_ret.ca_address_sk
JOIN call_center cc ON true                         -- reused as a cross‑join to enable later join
JOIN catalog_sales cs ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN web_sales ws ON ws.ws_bill_customer_sk = c_bill.c_customer_sk
JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
JOIN reason r2 ON wr.wr_reason_sk = r2.r_reason_sk
WHERE cs.cs_ext_sales_price > (
    SELECT avg(cs_sub.cs_ext_sales_price)
    FROM catalog_sales cs_sub
    WHERE cs_sub.cs_sold_date_sk = 2450000
)
GROUP BY
    s.s_store_name,
    s.s_city,
    CASE WHEN ss.ss_net_profit > 0 THEN 'Profitable' ELSE 'Loss' END
ORDER BY total_profit DESC
LIMIT 100
