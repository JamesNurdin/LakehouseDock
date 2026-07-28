WITH promo_distinct AS (
        SELECT DISTINCT p.p_promo_sk,
               p.p_promo_name,
               p.p_cost,
               p.p_channel_email
        FROM promotion p
    ),
    cs_joined AS (
        SELECT
            cs.cs_warehouse_sk,
            cs.cs_promo_sk,
            d_cs.d_year,
            SUM(cs.cs_net_profit)                       AS cs_net_profit,
            COUNT(cr.cr_order_number)                    AS return_cnt,
            MAX(cc.cc_name)                              AS call_center_name,
            MAX(s.s_store_name)                          AS store_name,
            MAX(ca.ca_country)                           AS bill_country
        FROM catalog_sales cs
        JOIN date_dim d_cs ON cs.cs_sold_date_sk = d_cs.d_date_sk
        JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
        JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
        JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
        JOIN store s ON s.s_closed_date_sk = d_cs.d_date_sk
        JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
        LEFT JOIN catalog_returns cr
            ON cr.cr_order_number = cs.cs_order_number
           AND cr.cr_item_sk = cs.cs_item_sk
        WHERE d_cs.d_date = DATE '2001-01-01'
          AND p.p_channel_email = 'N'
          AND s.s_state = 'CA'
          AND w.w_gmt_offset > 0
        GROUP BY cs.cs_warehouse_sk, cs.cs_promo_sk, d_cs.d_year
    ),
    ws_joined AS (
        SELECT
            ws.ws_warehouse_sk,
            ws.ws_promo_sk,
            d_ws.d_year,
            SUM(ws.ws_net_profit) AS ws_net_profit,
            MAX(we.web_name)      AS web_name,
            MAX(wp.wp_type)      AS page_type
        FROM web_sales ws
        JOIN date_dim d_ws ON ws.ws_sold_date_sk = d_ws.d_date_sk
        JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
        JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
        JOIN web_site we ON ws.ws_web_site_sk = we.web_site_sk
        JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
        WHERE d_ws.d_date = DATE '2001-01-01'
          AND p.p_channel_email = 'N'
          AND w.w_gmt_offset > 0
          AND ws.ws_net_paid_inc_ship > 1000
        GROUP BY ws.ws_warehouse_sk, ws.ws_promo_sk, d_ws.d_year
    )
SELECT
    cs.store_name,
    cs.call_center_name,
    cs.bill_country,
    cs.d_year,
    pd.p_promo_name,
    cs.cs_net_profit,
    ws.ws_net_profit,
    (cs.cs_net_profit + ws.ws_net_profit)                                 AS total_net_profit,
    cs.return_cnt,
    (SELECT MAX(p2.p_cost) FROM promotion p2 WHERE p2.p_promo_sk = cs.cs_promo_sk) AS max_promo_cost,
    CASE
        WHEN (cs.cs_net_profit + ws.ws_net_profit) > 100000 THEN 'High'
        WHEN (cs.cs_net_profit + ws.ws_net_profit) > 50000  THEN 'Medium'
        ELSE 'Low'
    END                                                                     AS profit_level,
    RANK() OVER (PARTITION BY cs.d_year ORDER BY (cs.cs_net_profit + ws.ws_net_profit) DESC) AS profit_rank
FROM cs_joined cs
JOIN ws_joined ws
      ON cs.cs_warehouse_sk = ws.ws_warehouse_sk
     AND cs.cs_promo_sk    = ws.ws_promo_sk
     AND cs.d_year         = ws.d_year
JOIN promo_distinct pd ON pd.p_promo_sk = cs.cs_promo_sk
ORDER BY total_net_profit DESC
LIMIT 100
