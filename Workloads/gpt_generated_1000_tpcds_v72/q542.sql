WITH sales_enriched AS (
  SELECT
    cs.cs_sold_date_sk,
    cs.cs_order_number,
    cs.cs_quantity,
    cs.cs_net_paid,
    cs.cs_net_profit,
    cc.cc_division_name,
    cc.cc_mkt_id,
    ca_bill.ca_gmt_offset AS bill_gmt_offset,
    ca_ship.ca_gmt_offset AS ship_gmt_offset,
    p.p_channel_tv,
    p.p_end_date_sk
  FROM catalog_sales cs
  JOIN call_center cc
    ON cs.cs_call_center_sk = cc.cc_call_center_sk
  JOIN customer_address ca_bill
    ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
  JOIN customer_address ca_ship
    ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
  JOIN promotion p
    ON cs.cs_promo_sk = p.p_promo_sk
  WHERE cc.cc_mkt_id IN (2, 3)
    AND cc.cc_division_name = 'able'
    AND p.p_channel_tv = 'N'
    AND p.p_end_date_sk BETWEEN 2450280 AND 2450650
    AND ca_bill.ca_gmt_offset = -6.00
    AND cs.cs_quantity >= 5
)
SELECT
  se.cc_division_name,
  se.cc_mkt_id,
  CASE WHEN se.p_channel_tv = 'N' THEN 'TV_N' ELSE 'TV_Other' END AS tv_channel_flag,
  SUM(se.cs_net_paid) AS total_net_paid,
  AVG(se.cs_net_profit) AS avg_net_profit,
  COUNT(DISTINCT se.cs_order_number) AS distinct_orders,
  MIN(se.cs_quantity) AS min_quantity,
  MAX(se.cs_quantity) AS max_quantity
FROM sales_enriched se
GROUP BY
  se.cc_division_name,
  se.cc_mkt_id,
  CASE WHEN se.p_channel_tv = 'N' THEN 'TV_N' ELSE 'TV_Other' END
HAVING SUM(se.cs_net_paid) > 10000
ORDER BY total_net_paid DESC
LIMIT 100
