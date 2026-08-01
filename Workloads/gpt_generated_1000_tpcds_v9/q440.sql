WITH avg_sales AS (
    SELECT avg(cs2.cs_net_paid) AS avg_net_paid
    FROM catalog_sales cs2
)
SELECT
    ca.ca_state,
    ib.ib_lower_bound,
    r.r_reason_desc,
    COUNT(DISTINCT cs.cs_order_number) AS order_cnt,
    SUM(cs.cs_net_profit) AS total_net_profit,
    SUM(cs.cs_quantity) AS total_quantity,
    CASE
        WHEN SUM(cs.cs_net_paid) > (SELECT avg_net_paid FROM avg_sales) THEN 'Above Avg'
        ELSE 'Below Avg'
    END AS net_paid_category,
    RANK() OVER (PARTITION BY ca.ca_state ORDER BY SUM(cs.cs_net_profit) DESC) AS profit_rank
FROM catalog_sales cs
JOIN customer c
    ON cs.cs_bill_customer_sk = c.c_customer_sk
JOIN customer_address ca
    ON cs.cs_bill_addr_sk = ca.ca_address_sk
JOIN household_demographics hd
    ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib
    ON hd.hd_income_band_sk = ib.ib_income_band_sk
LEFT JOIN catalog_returns cr
    ON cr.cr_order_number = cs.cs_order_number
   AND cr.cr_item_sk = cs.cs_item_sk
LEFT JOIN reason r
    ON cr.cr_reason_sk = r.r_reason_sk
LEFT JOIN store_returns sr
    ON sr.sr_customer_sk = c.c_customer_sk
LEFT JOIN web_sales ws
    ON ws.ws_bill_customer_sk = c.c_customer_sk
LEFT JOIN web_returns wr
    ON wr.wr_order_number = ws.ws_order_number
   AND wr.wr_item_sk = ws.ws_item_sk
WHERE
    ca.ca_state = 'CA'
    AND hd.hd_vehicle_count >= 1
    AND ib.ib_upper_bound > 50000
GROUP BY ROLLUP (ca.ca_state, ib.ib_lower_bound, r.r_reason_desc)
ORDER BY total_net_profit DESC
LIMIT 100
