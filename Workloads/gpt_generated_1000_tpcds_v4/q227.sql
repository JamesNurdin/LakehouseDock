WITH ss AS (
    SELECT
        ss_sold_date_sk,
        ss_sold_time_sk,
        ss_item_sk,
        ss_customer_sk,
        ss_cdemo_sk,
        ss_hdemo_sk,
        ss_store_sk,
        ss_ticket_number,
        ss_quantity,
        ss_ext_sales_price,
        ss_net_profit
    FROM store_sales
)
SELECT
    s.s_store_name,
    i.i_brand,
    d_ss.d_year,
    r.r_reason_desc,
    SUM(ss.ss_ext_sales_price)                                 AS total_sales,
    SUM(COALESCE(sr.sr_net_loss, 0))                           AS total_store_return_loss,
    SUM(COALESCE(cr.cr_net_loss, 0))                           AS total_catalog_return_loss,
    SUM(COALESCE(wr.wr_net_loss, 0))                           AS total_web_return_loss,
    SUM(ss.ss_net_profit)                                      AS total_net_profit,
    COUNT(DISTINCT ss.ss_ticket_number)                        AS distinct_tickets
FROM ss
-- join dimensions to the central fact store_sales (ss)
JOIN date_dim d_ss ON ss.ss_sold_date_sk = d_ss.d_date_sk
JOIN time_dim t   ON ss.ss_sold_time_sk = t.t_time_sk
JOIN item i       ON ss.ss_item_sk = i.i_item_sk
JOIN customer c   ON ss.ss_customer_sk = c.c_customer_sk
JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
JOIN store s      ON ss.ss_store_sk = s.s_store_sk
-- store returns directly linked to store_sales
LEFT JOIN store_returns sr
       ON ss.ss_ticket_number = sr.sr_ticket_number
      AND ss.ss_item_sk = sr.sr_item_sk
LEFT JOIN reason r
       ON sr.sr_reason_sk = r.r_reason_sk
-- catalog returns (joined via date and item, plus call_center for completeness)
LEFT JOIN catalog_returns cr
       ON ss.ss_sold_date_sk = cr.cr_returned_date_sk
      AND ss.ss_item_sk = cr.cr_item_sk
LEFT JOIN call_center cc
       ON cr.cr_call_center_sk = cc.cc_call_center_sk
-- web sales (separate fact) joined to its own date dimension
LEFT JOIN web_sales ws
       ON ss.ss_ticket_number = ws.ws_order_number
LEFT JOIN date_dim d_ws ON ws.ws_sold_date_sk = d_ws.d_date_sk
LEFT JOIN time_dim t_ws ON ws.ws_sold_time_sk = t_ws.t_time_sk
LEFT JOIN web_site we ON ws.ws_web_site_sk = we.web_site_sk
-- web returns linked to web_sales
LEFT JOIN web_returns wr
       ON ws.ws_order_number = wr.wr_order_number
LEFT JOIN date_dim d_wr ON wr.wr_returned_date_sk = d_wr.d_date_sk
LEFT JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
WHERE d_ss.d_year = 2002
  AND i.i_category = 'Sports'
  AND s.s_state = 'CA'
  AND we.web_country = 'United States'
GROUP BY s.s_store_name, i.i_brand, d_ss.d_year, r.r_reason_desc
HAVING SUM(ss.ss_ext_sales_price) > 10000
ORDER BY total_net_profit DESC
LIMIT 100
