WITH
    avg_item_discount AS (
        SELECT cs.cs_item_sk,
               AVG(cs.cs_ext_discount_amt) AS avg_discount
        FROM catalog_sales cs
        GROUP BY cs.cs_item_sk
    ),
    exclusive_items AS (
        SELECT DISTINCT ws_item_sk
        FROM web_sales
        EXCEPT
        SELECT DISTINCT cs_item_sk
        FROM catalog_sales
    )
SELECT
    s.s_store_name,
    i.i_category,
    i.i_item_id,
    cc.cc_name,
    p.p_promo_name,
    t.t_hour,
    SUM(ss.ss_net_profit)                         AS store_net_profit,
    SUM(cs.cs_net_profit)                         AS catalog_net_profit,
    SUM(ws.ws_net_profit)                         AS web_net_profit,
    COUNT(DISTINCT cs.cs_order_number)            AS distinct_catalog_orders,
    COUNT(DISTINCT ws.ws_order_number)            AS distinct_web_orders,
    AVG(cs.cs_ext_discount_amt)                  AS avg_catalog_discount,
    MAX(ad.avg_discount)                          AS avg_item_discount,
    MAX(CASE WHEN ei.ws_item_sk IS NOT NULL THEN 1 ELSE 0 END) AS exclusive_item_flag
FROM
    time_dim t
    JOIN store_sales ss ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN catalog_sales cs ON cs.cs_sold_time_sk = t.t_time_sk
                           AND cs.cs_item_sk = i.i_item_sk
                           AND cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_returns cr ON cr.cr_returned_time_sk = t.t_time_sk
                              AND cr.cr_item_sk = i.i_item_sk
                              AND cr.cr_refunded_customer_sk = c.c_customer_sk
                              AND cr.cr_call_center_sk = cc.cc_call_center_sk
                              AND cr.cr_order_number = cs.cs_order_number
    JOIN web_sales ws ON ws.ws_sold_time_sk = t.t_time_sk
                        AND ws.ws_item_sk = i.i_item_sk
                        AND ws.ws_bill_customer_sk = c.c_customer_sk
                        AND ws.ws_promo_sk = p.p_promo_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site we ON ws.ws_web_site_sk = we.web_site_sk
    JOIN web_returns wr ON wr.wr_returned_time_sk = t.t_time_sk
                           AND wr.wr_item_sk = i.i_item_sk
                           AND wr.wr_refunded_customer_sk = c.c_customer_sk
                           AND wr.wr_web_page_sk = wp.wp_web_page_sk
                           AND wr.wr_order_number = ws.ws_order_number
    LEFT JOIN avg_item_discount ad ON ad.cs_item_sk = i.i_item_sk
    LEFT JOIN exclusive_items ei ON ei.ws_item_sk = i.i_item_sk
WHERE
    cc.cc_rec_start_date >= DATE '2001-01-01'
    AND cc.cc_rec_start_date <= DATE '2002-12-31'
    AND i.i_rec_start_date >= DATE '2000-01-01'
    AND i.i_rec_start_date < DATE '2005-01-01'
    AND s.s_city = 'Seattle'
    AND we.web_country = 'United States'
    AND t.t_hour BETWEEN 9 AND 17
    AND p.p_discount_active = 'Y'
    AND EXISTS (
        SELECT 1
        FROM catalog_returns cr2
        WHERE cr2.cr_order_number = cs.cs_order_number
          AND cr2.cr_return_quantity > 0
    )
GROUP BY
    s.s_store_name,
    i.i_category,
    i.i_item_id,
    i.i_item_sk,
    cc.cc_name,
    p.p_promo_name,
    t.t_hour
ORDER BY
    store_net_profit DESC
LIMIT 100
