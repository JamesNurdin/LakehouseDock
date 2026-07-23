SELECT
    i.i_category,
    i.i_category_id,
    d.d_year,
    SUM(COALESCE(ss.ss_net_profit, 0)) AS total_store_profit,
    SUM(COALESCE(cs.cs_net_profit, 0)) AS total_catalog_profit,
    SUM(COALESCE(ws.ws_net_profit, 0)) AS total_web_profit,
    SUM(COALESCE(cr.cr_net_loss, 0)) AS total_catalog_return_loss,
    SUM(COALESCE(wr.wr_net_loss, 0)) AS total_web_return_loss,
    SUM(
        COALESCE(ss.ss_net_profit, 0) +
        COALESCE(cs.cs_net_profit, 0) +
        COALESCE(ws.ws_net_profit, 0) -
        COALESCE(cr.cr_net_loss, 0) -
        COALESCE(wr.wr_net_loss, 0)
    ) AS net_profit_all_channels
FROM store_sales ss
LEFT JOIN date_dim d
    ON ss.ss_sold_date_sk = d.d_date_sk
LEFT JOIN item i
    ON ss.ss_item_sk = i.i_item_sk
LEFT JOIN customer c
    ON ss.ss_customer_sk = c.c_customer_sk
LEFT JOIN customer_address ca
    ON ss.ss_addr_sk = ca.ca_address_sk
LEFT JOIN promotion p
    ON ss.ss_promo_sk = p.p_promo_sk
LEFT JOIN catalog_sales cs
    ON cs.cs_item_sk = i.i_item_sk
   AND cs.cs_sold_date_sk = d.d_date_sk
LEFT JOIN call_center cc
    ON cc.cc_call_center_sk = cs.cs_call_center_sk
LEFT JOIN date_dim d_cc_open
    ON cc.cc_open_date_sk = d_cc_open.d_date_sk
LEFT JOIN date_dim d_cc_closed
    ON cc.cc_closed_date_sk = d_cc_closed.d_date_sk
LEFT JOIN catalog_returns cr
    ON cr.cr_item_sk = i.i_item_sk
   AND cr.cr_returned_date_sk = d.d_date_sk
LEFT JOIN web_sales ws
    ON ws.ws_item_sk = i.i_item_sk
   AND ws.ws_sold_date_sk = d.d_date_sk
LEFT JOIN web_page wp_sales
    ON wp_sales.wp_web_page_sk = ws.ws_web_page_sk
LEFT JOIN web_site ws_site
    ON ws_site.web_site_sk = ws.ws_web_site_sk
LEFT JOIN web_returns wr
    ON wr.wr_item_sk = i.i_item_sk
   AND wr.wr_returned_date_sk = d.d_date_sk
LEFT JOIN web_page wp_returns
    ON wp_returns.wp_web_page_sk = wr.wr_web_page_sk
GROUP BY
    i.i_category,
    i.i_category_id,
    d.d_year
ORDER BY net_profit_all_channels DESC
LIMIT 100
