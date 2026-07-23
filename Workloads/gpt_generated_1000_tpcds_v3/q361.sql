WITH item_month_sales AS (
  SELECT
    i.i_item_id,
    i.i_category,
    i.i_brand,
    d_cs_sold.d_year,
    d_cs_sold.d_month_seq,
    SUM(cs.cs_net_profit) AS sum_cs_net_profit,
    SUM(ws.ws_net_profit) AS sum_ws_net_profit,
    SUM(cs.cs_quantity) AS sum_cs_quantity,
    SUM(ws.ws_quantity) AS sum_ws_quantity,
    COUNT(DISTINCT p.p_promo_name) AS distinct_promos,
    MAX(inv.inv_quantity_on_hand) AS max_inventory,
    SUM(CASE WHEN cs.cs_net_profit > 0 THEN cs.cs_net_profit ELSE 0 END) AS sum_positive_cs_profit
  FROM catalog_sales cs
  JOIN date_dim d_cs_sold
    ON cs.cs_sold_date_sk = d_cs_sold.d_date_sk
  JOIN date_dim d_cs_ship
    ON cs.cs_ship_date_sk = d_cs_ship.d_date_sk
  JOIN call_center cc
    ON cs.cs_call_center_sk = cc.cc_call_center_sk
  JOIN promotion p
    ON cs.cs_promo_sk = p.p_promo_sk
  JOIN item i
    ON cs.cs_item_sk = i.i_item_sk
  JOIN customer_address ca_bill
    ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
  JOIN customer_address ca_ship
    ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
  JOIN web_sales ws
    ON ws.ws_item_sk = i.i_item_sk
  JOIN date_dim d_ws_sold
    ON ws.ws_sold_date_sk = d_ws_sold.d_date_sk
  JOIN date_dim d_ws_ship
    ON ws.ws_ship_date_sk = d_ws_ship.d_date_sk
  JOIN web_site ws_site
    ON ws.ws_web_site_sk = ws_site.web_site_sk
  JOIN promotion p_ws
    ON ws.ws_promo_sk = p_ws.p_promo_sk
  JOIN inventory inv
    ON inv.inv_item_sk = i.i_item_sk
  JOIN date_dim d_inv
    ON inv.inv_date_sk = d_inv.d_date_sk
  JOIN web_returns wr
    ON wr.wr_order_number = ws.ws_order_number
  JOIN date_dim d_wr_returned
    ON wr.wr_returned_date_sk = d_wr_returned.d_date_sk
  JOIN reason r
    ON wr.wr_reason_sk = r.r_reason_sk
  JOIN date_dim d_cc_open
    ON cc.cc_open_date_sk = d_cc_open.d_date_sk
  JOIN date_dim d_cc_closed
    ON cc.cc_closed_date_sk = d_cc_closed.d_date_sk
  JOIN date_dim d_promo_start
    ON p.p_start_date_sk = d_promo_start.d_date_sk
  JOIN date_dim d_promo_end
    ON p.p_end_date_sk = d_promo_end.d_date_sk
  JOIN date_dim d_ws_open
    ON ws_site.web_open_date_sk = d_ws_open.d_date_sk
  JOIN date_dim d_ws_close
    ON ws_site.web_close_date_sk = d_ws_close.d_date_sk
  WHERE d_cs_sold.d_year = 2001
    AND ca_bill.ca_state = 'CA'
    AND i.i_brand = 'BrandX'
    AND p.p_discount_active = 'Y'
    AND ws_site.web_country = 'United States'
    AND inv.inv_quantity_on_hand > 0
  GROUP BY i.i_item_id, i.i_category, i.i_brand, d_cs_sold.d_year, d_cs_sold.d_month_seq
)
SELECT
  ims.i_category,
  ims.i_brand,
  AVG(ims.sum_cs_net_profit + ims.sum_ws_net_profit) AS avg_total_net_profit,
  CASE
    WHEN AVG(ims.sum_cs_net_profit + ims.sum_ws_net_profit) > 10000 THEN 'High'
    WHEN AVG(ims.sum_cs_net_profit + ims.sum_ws_net_profit) BETWEEN 0 AND 10000 THEN 'Medium'
    ELSE 'Low'
  END AS profit_level,
  COUNT(DISTINCT ims.i_item_id) AS distinct_items,
  (SELECT AVG(p2.p_cost) FROM promotion p2 WHERE p2.p_discount_active = 'Y') AS avg_active_promo_cost
FROM item_month_sales ims
WHERE ims.max_inventory > 100
  AND ims.distinct_promos >= 1
GROUP BY ims.i_category, ims.i_brand
HAVING AVG(ims.sum_cs_net_profit + ims.sum_ws_net_profit) > 0
ORDER BY avg_total_net_profit DESC
LIMIT 100
