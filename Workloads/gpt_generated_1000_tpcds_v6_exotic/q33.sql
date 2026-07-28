SELECT
    p_cs.p_channel_tv,
    i_cs.i_category,
    SUM(cs.cs_net_paid) AS total_cs_net_paid,
    SUM(ss.ss_net_paid) AS total_ss_net_paid,
    SUM(sr.sr_net_loss) AS total_sr_net_loss,
    (SELECT AVG(cs2.cs_net_paid) FROM catalog_sales cs2) AS overall_avg_cs_net_paid
FROM catalog_sales cs
JOIN customer cust_bill
    ON cs.cs_bill_customer_sk = cust_bill.c_customer_sk
JOIN customer cust_ship
    ON cs.cs_ship_customer_sk = cust_ship.c_customer_sk
JOIN customer_address addr_bill
    ON cs.cs_bill_addr_sk = addr_bill.ca_address_sk
JOIN item i_cs
    ON cs.cs_item_sk = i_cs.i_item_sk
JOIN promotion p_cs
    ON cs.cs_promo_sk = p_cs.p_promo_sk
JOIN item i_prom
    ON p_cs.p_item_sk = i_prom.i_item_sk
JOIN store_sales ss
    ON ss.ss_item_sk = i_cs.i_item_sk
JOIN promotion p_ss
    ON ss.ss_promo_sk = p_ss.p_promo_sk
JOIN customer cust_ss
    ON ss.ss_customer_sk = cust_ss.c_customer_sk
JOIN customer_address addr_ss
    ON ss.ss_addr_sk = addr_ss.ca_address_sk
JOIN store_returns sr
    ON sr.sr_ticket_number = ss.ss_ticket_number
JOIN item i_sr
    ON sr.sr_item_sk = i_sr.i_item_sk
JOIN customer cust_sr
    ON sr.sr_customer_sk = cust_sr.c_customer_sk
JOIN customer_address addr_sr
    ON sr.sr_addr_sk = addr_sr.ca_address_sk
WHERE p_cs.p_channel_tv = 'Y'
GROUP BY ROLLUP (p_cs.p_channel_tv, i_cs.i_category)
HAVING SUM(cs.cs_net_paid) > 5000
ORDER BY total_cs_net_paid DESC
LIMIT 100
