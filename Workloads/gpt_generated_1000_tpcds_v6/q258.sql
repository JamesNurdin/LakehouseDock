/*
Goal: Analyze net sales, profit, and return amounts by store, region (derived from state), and promotion. The query counts unique customers, aggregates net paid, net profit, total return amount, and high‑tax return metrics, and filters to only those customers who also have a catalog sale for the same promotion on the same sold date.
*/
SELECT
    s.s_store_name,
    s.s_state,
    CASE WHEN s.s_state = 'CA' THEN 'West' ELSE 'Other' END AS region_category,
    p_ss.p_promo_name,
    COUNT(DISTINCT c.c_customer_sk) AS unique_customers,
    SUM(ss.ss_net_paid) AS total_net_paid,
    SUM(ss.ss_net_profit) AS total_net_profit,
    SUM(sr.sr_return_amt) AS total_return_amount,
    SUM(CASE WHEN sr.sr_return_tax > 20 THEN sr.sr_return_tax ELSE 0 END) AS high_tax_returns,
    COUNT(*) FILTER (WHERE sr.sr_return_tax > 20) AS high_tax_return_count
FROM
    store_sales ss
JOIN customer c
    ON ss.ss_customer_sk = c.c_customer_sk
JOIN household_demographics hd_ss
    ON ss.ss_hdemo_sk = hd_ss.hd_demo_sk
JOIN customer_address ca_ss
    ON ss.ss_addr_sk = ca_ss.ca_address_sk
JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
JOIN promotion p_ss
    ON ss.ss_promo_sk = p_ss.p_promo_sk
JOIN store_returns sr
    ON sr.sr_ticket_number = ss.ss_ticket_number
   AND sr.sr_item_sk = ss.ss_item_sk
JOIN store s_sr
    ON sr.sr_store_sk = s_sr.s_store_sk
JOIN customer c_sr
    ON sr.sr_customer_sk = c_sr.c_customer_sk
JOIN household_demographics hd_sr
    ON sr.sr_hdemo_sk = hd_sr.hd_demo_sk
JOIN customer_address ca_sr
    ON sr.sr_addr_sk = ca_sr.ca_address_sk
JOIN catalog_sales cs
    ON cs.cs_bill_customer_sk = c.c_customer_sk
JOIN household_demographics hd_cs
    ON cs.cs_bill_hdemo_sk = hd_cs.hd_demo_sk
JOIN customer_address ca_cs
    ON cs.cs_bill_addr_sk = ca_cs.ca_address_sk
JOIN promotion p_cs
    ON cs.cs_promo_sk = p_cs.p_promo_sk
WHERE EXISTS (
    SELECT 1
    FROM catalog_sales cs2
    WHERE cs2.cs_bill_customer_sk = c.c_customer_sk
      AND cs2.cs_promo_sk = p_ss.p_promo_sk
      AND cs2.cs_sold_date_sk = ss.ss_sold_date_sk
)
GROUP BY
    s.s_store_name,
    s.s_state,
    CASE WHEN s.s_state = 'CA' THEN 'West' ELSE 'Other' END,
    p_ss.p_promo_name
ORDER BY
    total_net_profit DESC
LIMIT 100
