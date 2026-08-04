WITH
  sales_agg AS (
    SELECT
      i.i_item_id,
      i.i_product_name,
      p.p_promo_name,
      t.t_hour,
      SUM(cs.cs_net_paid)            AS catalog_sales_net,
      SUM(ss.ss_net_paid)            AS store_sales_net,
      SUM(ws.ws_net_paid)            AS web_sales_net,
      SUM(cs.cs_net_paid) + SUM(ss.ss_net_paid) + SUM(ws.ws_net_paid) AS total_net
    FROM item i
      JOIN catalog_sales cs          ON cs.cs_item_sk = i.i_item_sk
      JOIN store_sales ss            ON ss.ss_item_sk = i.i_item_sk
      JOIN web_sales ws              ON ws.ws_item_sk = i.i_item_sk
      JOIN promotion p               ON cs.cs_promo_sk = p.p_promo_sk
      JOIN call_center cc            ON cs.cs_call_center_sk = cc.cc_call_center_sk
      JOIN ship_mode sm              ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
      JOIN time_dim t                ON cs.cs_sold_time_sk = t.t_time_sk
      JOIN customer_address ca       ON cs.cs_bill_addr_sk = ca.ca_address_sk
      JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
      LEFT JOIN catalog_returns cr   ON cr.cr_item_sk = i.i_item_sk
                                      AND cr.cr_order_number = cs.cs_order_number
      LEFT JOIN store_returns sr     ON sr.sr_item_sk = i.i_item_sk
                                      AND sr.sr_ticket_number = ss.ss_ticket_number
      LEFT JOIN reason r             ON cr.cr_reason_sk = r.r_reason_sk
      LEFT JOIN inventory inv        ON inv.inv_item_sk = i.i_item_sk
      LEFT JOIN web_page wp          ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE
      t.t_hour BETWEEN 9 AND 17
      AND sm.sm_code = 'AIR'
      AND cc.cc_state = 'CA'
      AND i.i_current_price > 100
    GROUP BY
      i.i_item_id,
      i.i_product_name,
      p.p_promo_name,
      t.t_hour
  ),
  items_without_returns AS (
    SELECT i.i_item_id
    FROM item i
    EXCEPT
    SELECT i2.i_item_id
    FROM catalog_returns cr
      JOIN item i2 ON cr.cr_item_sk = i2.i_item_sk
  )
SELECT
  sa.p_promo_name,
  SUM(sa.total_net)               AS promo_total_net,
  AVG(sa.total_net)               AS promo_avg_net
FROM sales_agg sa
WHERE sa.i_item_id IN (SELECT i_item_id FROM items_without_returns)
  AND sa.i_item_id NOT IN (
        SELECT i3.i_item_id
        FROM store_returns sr2
          JOIN item i3 ON sr2.sr_item_sk = i3.i_item_sk
      )
GROUP BY sa.p_promo_name
HAVING AVG(sa.total_net) > 5000
ORDER BY promo_total_net DESC
LIMIT 100
