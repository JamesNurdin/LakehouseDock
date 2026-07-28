WITH sales_per_ticket AS (
    SELECT
        ss.ss_ticket_number,
        SUM(ss.ss_ext_sales_price) AS total_sales_price,
        SUM(ss.ss_net_profit) AS total_net_profit
    FROM store_sales ss
    GROUP BY ss.ss_ticket_number
)
SELECT
    s.s_manager,
    CONCAT(s.s_city, ', ', s.s_state) AS store_location,
    r.r_reason_desc,
    sr.sr_return_amt,
    sp.total_sales_price,
    sp.total_net_profit,
    CASE WHEN sr.sr_return_amt > 100 THEN 'High' ELSE 'Low' END AS return_category,
    (
        SELECT AVG(ib.ib_lower_bound)
        FROM household_demographics hd
        JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
        WHERE hd.hd_demo_sk = c.c_current_hdemo_sk
    ) AS avg_income_lower_bound,
    ROW_NUMBER() OVER (PARTITION BY s.s_manager ORDER BY sr.sr_return_amt DESC) AS rn
FROM store_returns sr
JOIN store s ON sr.sr_store_sk = s.s_store_sk
JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
LEFT JOIN sales_per_ticket sp ON sr.sr_ticket_number = sp.ss_ticket_number
WHERE regexp_like(r.r_reason_desc, '(?i)damaged|defective')
  AND s.s_manager LIKE 'Scott%'
  AND substr(c.c_email_address, 1, 5) = 'john@'
  AND CAST(s.s_store_id AS varchar) LIKE 'S_%'
ORDER BY return_category DESC, sp.total_sales_price DESC
LIMIT 100
