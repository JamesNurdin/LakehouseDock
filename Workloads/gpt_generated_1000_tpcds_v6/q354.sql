SELECT
    s.s_state,
    s.s_city,
    s.s_store_name,
    COUNT(DISTINCT cs.cs_order_number) AS num_catalog_orders,
    SUM(cs.cs_net_profit) AS catalog_net_profit,
    SUM(ss.ss_net_profit) AS store_sales_net_profit,
    SUM(sr.sr_net_loss) AS store_returns_net_loss,
    (SUM(cs.cs_net_profit) + SUM(ss.ss_net_profit) - SUM(sr.sr_net_loss)) AS total_contribution
FROM catalog_sales cs
JOIN customer_demographics cd_bill
  ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
JOIN customer_address ca_bill
  ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
JOIN customer_demographics cd_ship
  ON cs.cs_ship_cdemo_sk = cd_ship.cd_demo_sk
JOIN customer_address ca_ship
  ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
JOIN store_sales ss
  ON ss.ss_cdemo_sk = cd_bill.cd_demo_sk               -- use the same gender/age dimension as the billing customer
 AND ss.ss_addr_sk = ca_bill.ca_address_sk               -- use the same address dimension as the billing address
JOIN customer_demographics cd_sales
  ON ss.ss_cdemo_sk = cd_sales.cd_demo_sk
JOIN customer_address ca_sales
  ON ss.ss_addr_sk = ca_sales.ca_address_sk
JOIN store s
  ON ss.ss_store_sk = s.s_store_sk
JOIN store_returns sr
  ON sr.sr_item_sk = ss.ss_item_sk
 AND sr.sr_ticket_number = ss.ss_ticket_number
JOIN customer_demographics cd_ret
  ON sr.sr_cdemo_sk = cd_ret.cd_demo_sk
JOIN customer_address ca_ret
  ON sr.sr_addr_sk = ca_ret.ca_address_sk
JOIN store s_ret
  ON sr.sr_store_sk = s_ret.s_store_sk
WHERE EXISTS (
    SELECT 1
    FROM catalog_sales cs_check
    WHERE cs_check.cs_bill_customer_sk = cs.cs_bill_customer_sk
      AND cs_check.cs_net_profit > 1000
)
GROUP BY s.s_state, s.s_city, s.s_store_name
ORDER BY total_contribution DESC
LIMIT 100
