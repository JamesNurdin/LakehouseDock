WITH inv_agg AS (
    SELECT inv_item_sk,
           SUM(inv_quantity_on_hand) AS total_on_hand
    FROM inventory
    GROUP BY inv_item_sk
)
SELECT
    i.i_item_id,
    i.i_product_name,
    i.i_current_price,
    ss.ss_sold_date_sk,
    ss.ss_ext_sales_price,
    sr.sr_return_quantity,
    cr.cr_return_amount,
    wr.wr_return_amt,
    inv_agg.total_on_hand,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    p.p_promo_name,
    r.r_reason_desc,
    cc.cc_name,
    ROW_NUMBER() OVER (PARTITION BY i.i_brand ORDER BY ss.ss_ext_sales_price DESC) AS brand_item_rank,
    CASE WHEN ss.ss_net_profit > 1000 THEN 'High' ELSE 'Low' END AS profit_category
FROM store_sales ss
JOIN time_dim td
    ON ss.ss_sold_time_sk = td.t_time_sk
JOIN item i
    ON ss.ss_item_sk = i.i_item_sk
JOIN household_demographics hd
    ON ss.ss_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib
    ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN customer_address ca
    ON ss.ss_addr_sk = ca.ca_address_sk
JOIN promotion p
    ON ss.ss_promo_sk = p.p_promo_sk
JOIN store_returns sr
    ON sr.sr_ticket_number = ss.ss_ticket_number
JOIN reason r
    ON sr.sr_reason_sk = r.r_reason_sk
JOIN catalog_returns cr
    ON cr.cr_item_sk = i.i_item_sk
JOIN call_center cc
    ON cr.cr_call_center_sk = cc.cc_call_center_sk
JOIN web_sales ws
    ON ws.ws_item_sk = i.i_item_sk
JOIN web_returns wr
    ON wr.wr_order_number = ws.ws_order_number
JOIN web_page wp
    ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN web_site wsite
    ON ws.ws_web_site_sk = wsite.web_site_sk
LEFT JOIN inv_agg
    ON inv_agg.inv_item_sk = i.i_item_sk
WHERE ss.ss_sold_time_sk IN (65495, 54836, 45986)
  AND i.i_current_price > 100.00
  AND cc.cc_state = 'CA'
  AND ib.ib_upper_bound <= 50000
  AND ca.ca_country = 'United States'
ORDER BY brand_item_rank, i.i_item_id
LIMIT 100
