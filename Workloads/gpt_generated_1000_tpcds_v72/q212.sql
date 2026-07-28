/*
Goal: Rank stores by total return loss while incorporating catalog sales profitability, applying multiple business filters, excluding returns that have a matching catalog sale order, and demonstrating window functions, a scalar subquery, and a LEFT OUTER JOIN.
*/
WITH cs_agg AS (
    SELECT
        cs.cs_bill_addr_sk,
        SUM(cs.cs_net_profit) AS total_net_profit,
        AVG(cs.cs_net_profit) AS avg_net_profit
    FROM catalog_sales cs
    WHERE cs.cs_quantity > 1
      AND cs.cs_net_profit > 0
    GROUP BY cs.cs_bill_addr_sk
)
SELECT
    s.s_store_id,
    s.s_store_name,
    r.r_reason_desc,
    ca.ca_city,
    SUM(sr.sr_net_loss) AS store_return_loss,
    cs_agg.total_net_profit,
    RANK() OVER (ORDER BY SUM(sr.sr_net_loss) DESC) AS loss_rank,
    CASE
        WHEN SUM(sr.sr_net_loss) > 10000 THEN 'High'
        ELSE 'Normal'
    END AS loss_category
FROM store_returns sr
JOIN store s
    ON sr.sr_store_sk = s.s_store_sk
JOIN reason r
    ON sr.sr_reason_sk = r.r_reason_sk
JOIN customer_address ca
    ON sr.sr_addr_sk = ca.ca_address_sk
LEFT JOIN cs_agg
    ON cs_agg.cs_bill_addr_sk = ca.ca_address_sk
WHERE s.s_country = 'United States'
  AND s.s_gmt_offset = -5.00
  AND s.s_rec_end_date >= DATE '2000-01-01'
  AND r.r_reason_desc LIKE '%job%'
  AND ca.ca_street_type IN ('Rd', 'Ct.', 'Boulevard')
  AND (cs_agg.total_net_profit IS NULL OR cs_agg.total_net_profit > 500)
  AND NOT EXISTS (
        SELECT 1
        FROM catalog_sales cs2
        WHERE cs2.cs_order_number = sr.sr_ticket_number
      )
GROUP BY
    s.s_store_id,
    s.s_store_name,
    r.r_reason_desc,
    ca.ca_city,
    cs_agg.total_net_profit
ORDER BY loss_rank
LIMIT 100
