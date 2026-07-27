SELECT
    s.s_store_name,
    p.p_promo_name,
    sm.sm_type,
    cp.cp_department,
    r.r_reason_desc,
    COUNT(DISTINCT ws.ws_order_number) AS order_cnt,
    SUM(ss.ss_net_profit) AS total_store_profit,
    SUM(ws.ws_net_profit) AS total_web_profit,
    SUM(cs.cs_net_profit) AS total_catalog_profit,
    AVG(ss.ss_ext_sales_price) AS avg_store_sale_price
FROM store_sales ss
JOIN store s
  ON ss.ss_store_sk = s.s_store_sk
JOIN promotion p
  ON ss.ss_promo_sk = p.p_promo_sk
JOIN catalog_sales cs
  ON cs.cs_promo_sk = p.p_promo_sk
JOIN catalog_page cp
  ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN ship_mode sm
  ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN web_sales ws
  ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
 AND ws.ws_promo_sk = p.p_promo_sk
JOIN web_returns wr
  ON wr.wr_order_number = ws.ws_order_number
 AND wr.wr_item_sk = ws.ws_item_sk
JOIN reason r
  ON wr.wr_reason_sk = r.r_reason_sk
WHERE
    ss.ss_quantity > 5
    AND ss.ss_ext_sales_price > 1000
    AND cs.cs_sales_price BETWEEN 10 AND 100
    AND cp.cp_catalog_page_number IN (9, 11, 17)
    AND sm.sm_type = 'AIR'
    AND p.p_discount_active = 'Y'
    AND ss.ss_net_profit > (
        SELECT AVG(ss2.ss_net_profit)
        FROM store_sales ss2
        WHERE ss2.ss_store_sk = s.s_store_sk
    )
GROUP BY
    s.s_store_name,
    p.p_promo_name,
    sm.sm_type,
    cp.cp_department,
    r.r_reason_desc
HAVING
    SUM(ss.ss_net_profit) > 10000
ORDER BY
    total_store_profit DESC
LIMIT 100
