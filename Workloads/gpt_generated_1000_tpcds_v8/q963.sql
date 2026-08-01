/*
Goal: Identify top 5 customers by net paid amount for catalog sales per store in Texas during business hours, filtered by income band and web page type, while excluding tickets that had a net loss return. The query joins all 11 TPC‑DS tables, samples store sales, uses a window function, performs an anti‑semi‑join, cross‑joins a small values table, and pages the result.
*/
WITH sampled_store_sales AS (
    SELECT *
    FROM store_sales
    TABLESAMPLE BERNOULLI (10)  -- 10% random sample of store_sales
)
SELECT
    jd.s_store_id,
    jd.c_customer_id,
    jd.ca_city,
    jd.t_hour,
    jd.t_meal_time,
    jd.ib_lower_bound,
    jd.ib_upper_bound,
    jd.wp_type,
    jd.cs_net_paid,
    jd.cs_net_profit,
    jd.ws_net_paid,
    jd.ws_net_profit,
    jd.rn,
    t.grp
FROM (
    SELECT
        s.s_store_id,
        c.c_customer_id,
        ca.ca_city,
        td.t_hour,
        td.t_meal_time,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        wp.wp_type,
        cs.cs_net_paid,
        cs.cs_net_profit,
        ws.ws_net_paid,
        ws.ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY s.s_store_id ORDER BY cs.cs_net_paid DESC) AS rn
    FROM sampled_store_sales ss
    JOIN time_dim td
        ON ss.ss_sold_time_sk = td.t_time_sk
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    JOIN customer c
        ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_address ca
        ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    LEFT JOIN store_returns sr
        ON sr.sr_ticket_number = ss.ss_ticket_number
        AND sr.sr_store_sk = s.s_store_sk
    LEFT JOIN catalog_sales cs
        ON cs.cs_sold_time_sk = td.t_time_sk
        AND cs.cs_bill_customer_sk = c.c_customer_sk
        AND cs.cs_bill_hdemo_sk = hd.hd_demo_sk
        AND cs.cs_bill_addr_sk = ca.ca_address_sk
    LEFT JOIN web_sales ws
        ON ws.ws_sold_time_sk = td.t_time_sk
        AND ws.ws_bill_customer_sk = c.c_customer_sk
        AND ws.ws_bill_hdemo_sk = hd.hd_demo_sk
        AND ws.ws_bill_addr_sk = ca.ca_address_sk
    LEFT JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE s.s_state = 'TX'
      AND ib.ib_lower_bound >= 30000
      AND td.t_hour BETWEEN 9 AND 17
      AND wp.wp_type = 'Home'
      AND ss.ss_ticket_number NOT IN (
          SELECT sr2.sr_ticket_number
          FROM store_returns sr2
          WHERE sr2.sr_net_loss > 0
      )
) jd
CROSS JOIN (VALUES (1), (2)) AS t(grp)
WHERE jd.rn <= 5
ORDER BY jd.cs_net_paid DESC
OFFSET 0 LIMIT 100
