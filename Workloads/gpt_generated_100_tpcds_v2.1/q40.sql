WITH distinct_customers AS (
    SELECT DISTINCT
        c.c_customer_sk,
        c.c_customer_id,
        cd.cd_demo_sk,
        cd.cd_gender,
        hd.hd_demo_sk,
        hd.hd_buy_potential
    FROM customer c
    JOIN customer_demographics cd
        ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd
        ON c.c_current_hdemo_sk = hd.hd_demo_sk
    WHERE cd.cd_gender = 'F'
      AND hd.hd_buy_potential = 'HIGH'
)
SELECT
    ws.ws_web_site_sk,
    wsite.web_name,
    wsite.web_tax_percentage,
    cd.cd_gender,
    hd.hd_buy_potential,
    COUNT(DISTINCT dc.c_customer_id) AS distinct_customers,
    COUNT(DISTINCT ws.ws_order_number) AS distinct_orders,
    SUM(ss.ss_quantity) AS total_store_quantity,
    SUM(ws.ws_quantity) AS total_web_quantity,
    SUM(ss.ss_net_paid) AS total_store_net_paid,
    SUM(ws.ws_net_paid) AS total_web_net_paid,
    SUM(wr.wr_return_amt) AS total_return_amount,
    AVG(ss.ss_quantity) AS avg_store_quantity,
    MIN(ws.ws_net_profit) AS min_web_net_profit,
    MAX(ws.ws_net_profit) AS max_web_net_profit
FROM distinct_customers dc
JOIN store_sales ss
    ON ss.ss_customer_sk = dc.c_customer_sk
JOIN customer_demographics cd
    ON ss.ss_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd
    ON ss.ss_hdemo_sk = hd.hd_demo_sk
JOIN web_sales ws
    ON ws.ws_bill_customer_sk = dc.c_customer_sk
JOIN web_site wsite
    ON ws.ws_web_site_sk = wsite.web_site_sk
JOIN web_returns wr
    ON wr.wr_order_number = ws.ws_order_number
    AND wr.wr_item_sk = ws.ws_item_sk
WHERE wsite.web_name = 'site_5'
  AND wsite.web_tax_percentage >= 0.06
  AND ss.ss_sold_date_sk BETWEEN 2451200 AND 2451500
  AND wr.wr_return_amt > 200
GROUP BY
    ws.ws_web_site_sk,
    wsite.web_name,
    wsite.web_tax_percentage,
    cd.cd_gender,
    hd.hd_buy_potential
ORDER BY total_store_net_paid DESC
LIMIT 100
