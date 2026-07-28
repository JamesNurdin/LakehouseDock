WITH catalog_ret AS (
        SELECT cr.cr_item_sk,
               cr.cr_call_center_sk,
               cr.cr_catalog_page_sk,
               cr.cr_warehouse_sk,
               cr.cr_reason_sk,
               cr.cr_return_amount,
               cr.cr_return_quantity
        FROM catalog_returns cr
        WHERE cr.cr_return_amount > 0
    ),
    store_ret AS (
        SELECT sr.sr_item_sk,
               sr.sr_reason_sk,
               sr.sr_return_amt,
               sr.sr_return_quantity
        FROM store_returns sr
        WHERE sr.sr_return_amt > 0
    )
SELECT
    i.i_item_id,
    i.i_product_name,
    i.i_current_price,
    cc.cc_name,
    cp.cp_catalog_number,
    ws.ws_sold_date_sk,
    ws.ws_net_paid,
    CASE
        WHEN ws.ws_net_profit > 0 THEN 'Profitable'
        ELSE 'Loss'
    END AS profit_flag,
    SUM(ws.ws_net_paid) OVER (PARTITION BY i.i_item_sk
                              ORDER BY ws.ws_sold_date_sk
                              ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_sales,
    ROW_NUMBER() OVER (PARTITION BY i.i_item_sk ORDER BY ws.ws_net_paid DESC) AS rn_item_sales,
    RANK() OVER (ORDER BY ws.ws_net_paid DESC) AS overall_sales_rank
FROM web_sales ws
JOIN item i
  ON ws.ws_item_sk = i.i_item_sk
JOIN promotion p
  ON ws.ws_promo_sk = p.p_promo_sk
JOIN web_page wp
  ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN web_site wsite
  ON ws.ws_web_site_sk = wsite.web_site_sk
JOIN warehouse w
  ON ws.ws_warehouse_sk = w.w_warehouse_sk
JOIN customer_demographics cd_bill
  ON ws.ws_bill_cdemo_sk = cd_bill.cd_demo_sk
JOIN household_demographics hd
  ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
JOIN customer_address ca_bill
  ON ws.ws_bill_addr_sk = ca_bill.ca_address_sk
JOIN catalog_ret cr
  ON cr.cr_item_sk = i.i_item_sk
JOIN call_center cc
  ON cr.cr_call_center_sk = cc.cc_call_center_sk
JOIN catalog_page cp
  ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN reason r
  ON cr.cr_reason_sk = r.r_reason_sk
JOIN store_ret sr
  ON sr.sr_item_sk = i.i_item_sk
JOIN inventory inv
  ON inv.inv_item_sk = i.i_item_sk
 AND inv.inv_warehouse_sk = w.w_warehouse_sk
WHERE i.i_current_price BETWEEN 20 AND 100
  AND cc.cc_state = 'CA'
  AND wp.wp_type = 'Home'
  AND i.i_rec_start_date >= DATE '2000-01-01'
  AND EXISTS (
        SELECT 1
        FROM promotion p2
        WHERE p2.p_item_sk = i.i_item_sk
          AND p2.p_discount_active = 'Y'
          AND p2.p_channel_dmail = 'Y'
      )
ORDER BY overall_sales_rank
LIMIT 100
