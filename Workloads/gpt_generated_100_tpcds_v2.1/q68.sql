WITH ss AS (
    SELECT *
    FROM store_sales
)
SELECT
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    d_sales.d_date AS sale_date,
    ss.ss_net_paid,
    ss.ss_net_profit,
    CASE WHEN ss.ss_net_profit > 100 THEN 'High' ELSE 'Low' END AS profit_category,
    p_ss.p_promo_name AS store_promo_name,
    p_ws.p_promo_name AS web_promo_name,
    sm.sm_type,
    r.r_reason_desc,
    sr.sr_return_amt,
    ws.ws_net_paid AS web_net_paid,
    ROW_NUMBER() OVER (PARTITION BY c.c_customer_id ORDER BY ss.ss_net_profit DESC) AS profit_rank,
    SUM(ss.ss_net_profit) OVER (PARTITION BY c.c_customer_id ORDER BY d_sales.d_date ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS rolling_3day_profit,
    (SELECT AVG(ss2.ss_net_profit) FROM store_sales ss2 WHERE ss2.ss_customer_sk = c.c_customer_sk) AS avg_customer_net_profit
FROM store_sales ss
JOIN date_dim d_sales ON ss.ss_sold_date_sk = d_sales.d_date_sk
JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
JOIN promotion p_ss ON ss.ss_promo_sk = p_ss.p_promo_sk
JOIN store_returns sr ON sr.sr_item_sk = ss.ss_item_sk
    AND sr.sr_ticket_number = ss.ss_ticket_number
    AND sr.sr_customer_sk = c.c_customer_sk
    AND sr.sr_cdemo_sk = cd.cd_demo_sk
JOIN date_dim d_return ON sr.sr_returned_date_sk = d_return.d_date_sk
JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
JOIN web_sales ws ON ws.ws_bill_customer_sk = c.c_customer_sk
    AND ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    AND ws.ws_ship_customer_sk = c.c_customer_sk
    AND ws.ws_ship_cdemo_sk = cd.cd_demo_sk
JOIN date_dim d_ws_sold ON ws.ws_sold_date_sk = d_ws_sold.d_date_sk
JOIN date_dim d_ws_ship ON ws.ws_ship_date_sk = d_ws_ship.d_date_sk
JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
JOIN promotion p_ws ON ws.ws_promo_sk = p_ws.p_promo_sk
WHERE c.c_birth_year BETWEEN 1960 AND 1990
  AND c.c_birth_country IN ('MEXICO', 'CHILE')
  AND cd.cd_education_status = '4 yr Degree'
  AND cd.cd_credit_rating = 'Good'
  AND d_sales.d_year = 2002
  AND sm.sm_type = 'OVERNIGHT'
  AND ws.ws_quantity > 5
ORDER BY profit_rank, d_sales.d_date DESC
LIMIT 100
