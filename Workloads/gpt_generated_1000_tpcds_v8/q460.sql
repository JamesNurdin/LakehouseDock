WITH
    catalog_sales_agg AS (
        SELECT cs_item_sk,
               cs_sold_date_sk,
               SUM(cs_net_profit) AS total_profit,
               COUNT(*) AS sales_cnt
        FROM catalog_sales
        WHERE cs_net_profit > 0
        GROUP BY cs_item_sk, cs_sold_date_sk
    ),
    store_sales_agg AS (
        SELECT ss_item_sk,
               ss_sold_date_sk,
               SUM(ss_net_profit) AS store_total_profit,
               COUNT(*) AS store_sales_cnt
        FROM store_sales
        WHERE ss_net_profit > 0
        GROUP BY ss_item_sk, ss_sold_date_sk
    ),
    item_set_a AS (
        SELECT cs_item_sk AS item_sk
        FROM catalog_sales
        WHERE cs_quantity > 0
    ),
    item_set_b AS (
        SELECT ws_item_sk AS item_sk
        FROM web_sales
        WHERE ws_quantity > 0
    ),
    item_excluded AS (
        SELECT item_sk FROM item_set_a
        EXCEPT
        SELECT cr_item_sk FROM catalog_returns
    ),
    item_intersection AS (
        SELECT item_sk FROM item_set_a
        INTERSECT
        SELECT item_sk FROM item_set_b
    )
SELECT
    d.d_year,
    s.s_store_name,
    p_cs.p_promo_name,
    ca.total_profit,
    ss_agg.store_total_profit,
    ws.ws_net_profit,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    city_part,
    COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
    SUM(cs.cs_net_paid) AS total_net_paid
FROM catalog_sales cs
JOIN catalog_sales_agg ca
  ON cs.cs_item_sk = ca.cs_item_sk
 AND cs.cs_sold_date_sk = ca.cs_sold_date_sk
JOIN date_dim d
  ON cs.cs_sold_date_sk = d.d_date_sk
JOIN customer_demographics cd_bill
  ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
JOIN customer_demographics cd_ship
  ON cs.cs_ship_cdemo_sk = cd_ship.cd_demo_sk
JOIN household_demographics hd_bill
  ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
JOIN household_demographics hd_ship
  ON cs.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
JOIN warehouse w_cs
  ON cs.cs_warehouse_sk = w_cs.w_warehouse_sk
JOIN promotion p_cs
  ON cs.cs_promo_sk = p_cs.p_promo_sk
LEFT JOIN catalog_returns cr
  ON cr.cr_order_number = cs.cs_order_number
LEFT JOIN date_dim d_cr_return
  ON cr.cr_returned_date_sk = d_cr_return.d_date_sk
LEFT JOIN customer_demographics cd_refund
  ON cr.cr_refunded_cdemo_sk = cd_refund.cd_demo_sk
LEFT JOIN household_demographics hd_refund
  ON cr.cr_refunded_hdemo_sk = hd_refund.hd_demo_sk
LEFT JOIN warehouse w_cr
  ON cr.cr_warehouse_sk = w_cr.w_warehouse_sk
JOIN store_sales ss
  ON ss.ss_sold_date_sk = d.d_date_sk
JOIN store_sales_agg ss_agg
  ON ss.ss_item_sk = ss_agg.ss_item_sk
 AND ss.ss_sold_date_sk = ss_agg.ss_sold_date_sk
JOIN store s
  ON ss.ss_store_sk = s.s_store_sk
JOIN store_returns sr
  ON sr.sr_ticket_number = ss.ss_ticket_number
 AND sr.sr_item_sk = ss.ss_item_sk
JOIN date_dim d_sr_return
  ON sr.sr_returned_date_sk = d_sr_return.d_date_sk
JOIN inventory i
  ON i.inv_warehouse_sk = w_cs.w_warehouse_sk
 AND i.inv_date_sk = d.d_date_sk
JOIN income_band ib
  ON hd_bill.hd_income_band_sk = ib.ib_income_band_sk
JOIN web_sales ws
  ON ws.ws_sold_date_sk = d.d_date_sk
JOIN web_page wp
  ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN web_site we
  ON ws.ws_web_site_sk = we.web_site_sk
CROSS JOIN LATERAL (
    SELECT split(s.s_city, ' ') AS city_arr
) t(city_arr)
CROSS JOIN UNNEST(t.city_arr) AS u(city_part)
WHERE d.d_year = 2000
  AND w_cs.w_gmt_offset = -5.00
  AND p_cs.p_discount_active = 'Y'
  AND cd_bill.cd_gender = 'M'
  AND ib.ib_upper_bound > 50000
  AND EXISTS (SELECT 1 FROM item_excluded ie WHERE ie.item_sk = cs.cs_item_sk)
  AND EXISTS (SELECT 1 FROM item_intersection ii WHERE ii.item_sk = cs.cs_item_sk)
GROUP BY
    d.d_year,
    s.s_store_name,
    p_cs.p_promo_name,
    ca.total_profit,
    ss_agg.store_total_profit,
    ws.ws_net_profit,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    city_part
ORDER BY d.d_year DESC, s.s_store_name
