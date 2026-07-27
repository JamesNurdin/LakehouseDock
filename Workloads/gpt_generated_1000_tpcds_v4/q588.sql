WITH catalog AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_sold_time_sk,
        cs.cs_item_sk,
        cs.cs_bill_addr_sk,
        cs.cs_ship_addr_sk,
        cs.cs_call_center_sk,
        cs.cs_catalog_page_sk,
        cs.cs_ship_mode_sk,
        cs.cs_warehouse_sk,
        cs.cs_promo_sk,
        cs.cs_order_number,
        cs.cs_quantity,
        cs.cs_net_paid,
        cs.cs_net_profit
    FROM catalog_sales cs
    WHERE cs.cs_quantity >= 2
      AND cs.cs_net_paid >= 50
)
SELECT
    d.d_year,
    i.i_category,
    s.s_store_name,
    cc.cc_name,
    cp.cp_type,
    sm.sm_type,
    w.w_warehouse_name,
    p.p_promo_name,
    r.r_reason_desc,
    SUM(c.cs_net_paid) AS catalog_sales_net_paid,
    SUM(cr.cr_net_loss) AS returns_net_loss,
    SUM(ss.ss_net_paid) AS store_sales_net_paid,
    SUM(ws.ws_net_paid) AS web_sales_net_paid,
    COUNT(DISTINCT c.cs_order_number) AS distinct_catalog_orders,
    MIN(c.cs_net_profit) AS min_catalog_profit,
    MAX(c.cs_net_profit) AS max_catalog_profit
FROM catalog c
JOIN catalog_returns cr
  ON cr.cr_order_number = c.cs_order_number
  AND cr.cr_item_sk = c.cs_item_sk
JOIN date_dim d
  ON c.cs_sold_date_sk = d.d_date_sk
JOIN time_dim t
  ON c.cs_sold_time_sk = t.t_time_sk
JOIN item i
  ON c.cs_item_sk = i.i_item_sk
JOIN call_center cc
  ON c.cs_call_center_sk = cc.cc_call_center_sk
JOIN catalog_page cp
  ON c.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN ship_mode sm
  ON c.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w
  ON c.cs_warehouse_sk = w.w_warehouse_sk
JOIN promotion p
  ON c.cs_promo_sk = p.p_promo_sk
JOIN reason r
  ON cr.cr_reason_sk = r.r_reason_sk
JOIN customer_address ca_bill
  ON c.cs_bill_addr_sk = ca_bill.ca_address_sk
JOIN store_sales ss
  ON ss.ss_sold_date_sk = d.d_date_sk
  AND ss.ss_item_sk = i.i_item_sk
JOIN store s
  ON ss.ss_store_sk = s.s_store_sk
JOIN web_sales ws
  ON ws.ws_sold_date_sk = d.d_date_sk
  AND ws.ws_item_sk = i.i_item_sk
WHERE d.d_year = 2000
  AND i.i_brand = 'Brand#12'
  AND w.w_city = 'Oakland'
  AND p.p_discount_active = 'Y'
GROUP BY
    d.d_year,
    i.i_category,
    s.s_store_name,
    cc.cc_name,
    cp.cp_type,
    sm.sm_type,
    w.w_warehouse_name,
    p.p_promo_name,
    r.r_reason_desc
ORDER BY catalog_sales_net_paid DESC
LIMIT 100
