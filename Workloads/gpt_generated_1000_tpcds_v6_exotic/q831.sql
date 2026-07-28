WITH distinct_customers AS (
    SELECT DISTINCT
        c.c_customer_sk,
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name
    FROM customer c
    WHERE c.c_birth_day BETWEEN 1 AND 15
)
SELECT
    dc.c_customer_id,
    dc.c_first_name,
    dc.c_last_name,
    hd.hd_buy_potential,
    r.r_reason_desc,
    cr.cr_return_amount,
    cr.cr_net_loss,
    CASE WHEN cr.cr_return_amount > 200 THEN 'High' ELSE 'Low' END AS return_level,
    ROW_NUMBER() OVER (PARTITION BY dc.c_customer_id ORDER BY cr.cr_return_amount DESC) AS rn,
    wsit.web_name,
    ws.ws_net_profit
FROM catalog_returns cr
JOIN distinct_customers dc
    ON cr.cr_refunded_customer_sk = dc.c_customer_sk
JOIN household_demographics hd
    ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
JOIN reason r
    ON cr.cr_reason_sk = r.r_reason_sk
JOIN web_returns wr
    ON wr.wr_refunded_customer_sk = dc.c_customer_sk
JOIN web_sales ws
    ON wr.wr_order_number = ws.ws_order_number
JOIN web_site wsit
    ON ws.ws_web_site_sk = wsit.web_site_sk
WHERE cr.cr_return_amount > 100.00
  AND hd.hd_buy_potential = '1001-5000'
  AND r.r_reason_desc LIKE '%defect%'
  AND ws.ws_net_profit > 0
  AND wsit.web_country = 'United States'
ORDER BY rn ASC, cr.cr_return_amount DESC
LIMIT 100
