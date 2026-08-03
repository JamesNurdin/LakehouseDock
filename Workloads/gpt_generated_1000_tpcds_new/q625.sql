SELECT
    c.c_customer_id,
    i.i_item_id,
    cc.cc_name,
    ws.ws_net_profit,
    hd.hd_buy_potential,
    CASE WHEN hd.hd_buy_potential = '>10000' THEN 'High' ELSE 'Other' END AS potential_flag,
    p.p_promo_name,
    channel_detail,
    RANK() OVER (PARTITION BY cc.cc_division ORDER BY ws.ws_net_profit DESC) AS profit_rank
FROM call_center cc
JOIN catalog_sales cs ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN store_sales ss ON ss.ss_item_sk = cs.cs_item_sk
JOIN web_sales ws ON ws.ws_item_sk = cs.cs_item_sk
JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
JOIN web_page wp ON wp.wp_web_page_sk = ws.ws_web_page_sk
JOIN web_site wsite ON wsite.web_site_sk = ws.ws_web_site_sk
JOIN item i ON i.i_item_sk = cs.cs_item_sk
JOIN promotion p ON p.p_promo_sk = cs.cs_promo_sk
JOIN customer c ON c.c_customer_sk = cs.cs_bill_customer_sk
JOIN customer_address ca ON ca.ca_address_sk = cs.cs_bill_addr_sk
JOIN customer_demographics cd ON cd.cd_demo_sk = cs.cs_bill_cdemo_sk
JOIN household_demographics hd ON hd.hd_demo_sk = cs.cs_bill_hdemo_sk
CROSS JOIN UNNEST(split(p.p_channel_details, ',')) AS t(channel_detail)
WHERE cc.cc_state = 'CA'
  AND wsite.web_city = 'Friendship'
  AND i.i_category = 'Electronics'
  AND cs.cs_sold_date_sk IN (
        SELECT cs2.cs_sold_date_sk
        FROM catalog_sales cs2
        WHERE cs2.cs_quantity > 5
      )
UNION DISTINCT
SELECT
    c.c_customer_id,
    i.i_item_id,
    cc.cc_name,
    ws.ws_net_profit,
    hd.hd_buy_potential,
    CASE WHEN hd.hd_buy_potential = '>10000' THEN 'High' ELSE 'Other' END AS potential_flag,
    p.p_promo_name,
    channel_detail,
    RANK() OVER (PARTITION BY cc.cc_division ORDER BY ws.ws_net_profit DESC) AS profit_rank
FROM call_center cc
JOIN catalog_sales cs ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN store_sales ss ON ss.ss_item_sk = cs.cs_item_sk
JOIN web_sales ws ON ws.ws_item_sk = cs.cs_item_sk
JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
JOIN web_page wp ON wp.wp_web_page_sk = ws.ws_web_page_sk
JOIN web_site wsite ON wsite.web_site_sk = ws.ws_web_site_sk
JOIN item i ON i.i_item_sk = cs.cs_item_sk
JOIN promotion p ON p.p_promo_sk = cs.cs_promo_sk
JOIN customer c ON c.c_customer_sk = cs.cs_bill_customer_sk
JOIN customer_address ca ON ca.ca_address_sk = cs.cs_bill_addr_sk
JOIN customer_demographics cd ON cd.cd_demo_sk = cs.cs_bill_cdemo_sk
JOIN household_demographics hd ON hd.hd_demo_sk = cs.cs_bill_hdemo_sk
CROSS JOIN UNNEST(split(p.p_channel_details, ',')) AS t(channel_detail)
WHERE cc.cc_state = 'CA'
  AND wsite.web_city = 'Shiloh'
  AND i.i_category = 'Electronics'
  AND cs.cs_sold_date_sk IN (
        SELECT cs2.cs_sold_date_sk
        FROM catalog_sales cs2
        WHERE cs2.cs_quantity > 5
      )
ORDER BY profit_rank, c_customer_id
