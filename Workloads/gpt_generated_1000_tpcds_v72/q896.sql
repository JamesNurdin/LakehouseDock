WITH catalog_part AS (
   SELECT
       cs.cs_order_number,
       cs.cs_sold_time_sk,
       cs.cs_bill_customer_sk,
       cs.cs_net_paid,
       cs.cs_quantity,
       cs.cs_item_sk,
       cs.cs_ship_mode_sk,
       cs.cs_bill_addr_sk,
       CAST(NULL AS INTEGER) AS cs_web_site_sk
   FROM catalog_sales cs
   WHERE cs.cs_quantity > 0
),
web_part AS (
   SELECT
       ws.ws_order_number        AS cs_order_number,
       ws.ws_sold_time_sk        AS cs_sold_time_sk,
       ws.ws_bill_customer_sk    AS cs_bill_customer_sk,
       ws.ws_net_paid            AS cs_net_paid,
       ws.ws_quantity            AS cs_quantity,
       ws.ws_item_sk             AS cs_item_sk,
       ws.ws_ship_mode_sk        AS cs_ship_mode_sk,
       ws.ws_bill_addr_sk        AS cs_bill_addr_sk,
       ws.ws_web_site_sk         AS cs_web_site_sk
   FROM web_sales ws
   WHERE ws.ws_quantity > 0
),
combined_sales AS (
   SELECT * FROM catalog_part
   UNION ALL
   SELECT * FROM web_part
),
filtered_sales AS (
   SELECT
       cs.cs_order_number,
       cs.cs_sold_time_sk,
       cs.cs_bill_customer_sk,
       cs.cs_net_paid,
       cs.cs_quantity,
       cs.cs_item_sk,
       cs.cs_ship_mode_sk,
       cs.cs_bill_addr_sk,
       cs.cs_web_site_sk
   FROM combined_sales cs
   WHERE cs.cs_net_paid > 100.00
)
SELECT
    c.c_customer_id,
    ca.ca_city,
    ib.ib_lower_bound,
    SUM(fs.cs_net_paid)                         AS total_net_paid,
    COUNT(DISTINCT fs.cs_order_number)          AS order_cnt,
    AVG(fs.cs_quantity)                         AS avg_qty,
    MIN(td.t_hour)                              AS earliest_hour,
    CASE
        WHEN ib.ib_lower_bound >= 150000 THEN 'High Income'
        WHEN ib.ib_lower_bound >= 80000  THEN 'Mid Income'
        ELSE 'Low Income'
    END                                         AS income_category
FROM filtered_sales fs
JOIN time_dim td               ON fs.cs_sold_time_sk = td.t_time_sk
JOIN customer c                ON fs.cs_bill_customer_sk = c.c_customer_sk
JOIN customer_address ca       ON fs.cs_bill_addr_sk = ca.ca_address_sk
JOIN customer_demographics cd  ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib            ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN ship_mode sm              ON fs.cs_ship_mode_sk = sm.sm_ship_mode_sk
LEFT JOIN catalog_returns cr   ON cr.cr_order_number = fs.cs_order_number
                               AND cr.cr_item_sk = fs.cs_item_sk
LEFT JOIN reason r             ON cr.cr_reason_sk = r.r_reason_sk
LEFT JOIN store_returns sr     ON sr.sr_customer_sk = c.c_customer_sk
LEFT JOIN store s              ON sr.sr_store_sk = s.s_store_sk
LEFT JOIN reason r2            ON sr.sr_reason_sk = r2.r_reason_sk
LEFT JOIN web_site wsite       ON fs.cs_web_site_sk = wsite.web_site_sk
WHERE
    ca.ca_state = 'CA'
    AND ib.ib_upper_bound <= 200000
    AND td.t_hour BETWEEN 9 AND 17
    AND EXISTS (
        SELECT 1
        FROM store_returns sr2
        WHERE sr2.sr_customer_sk = c.c_customer_sk
          AND sr2.sr_return_quantity > 0
    )
GROUP BY
    c.c_customer_id,
    ca.ca_city,
    ib.ib_lower_bound,
    CASE
        WHEN ib.ib_lower_bound >= 150000 THEN 'High Income'
        WHEN ib.ib_lower_bound >= 80000  THEN 'Mid Income'
        ELSE 'Low Income'
    END
ORDER BY total_net_paid DESC
LIMIT 100
