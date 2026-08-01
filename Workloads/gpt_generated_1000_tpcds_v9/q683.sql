WITH store_return_agg AS (
    SELECT
        sr.sr_store_sk,
        SUM(sr.sr_return_quantity) AS total_return_qty,
        SUM(sr.sr_net_loss) AS total_net_loss
    FROM store_returns sr
    WHERE sr.sr_return_quantity > 0
      AND sr.sr_returned_date_sk BETWEEN 2450000 AND 2455000
    GROUP BY sr.sr_store_sk
),
web_sales_agg AS (
    SELECT
        ws.ws_bill_customer_sk AS c_customer_sk,
        ws.ws_web_page_sk,
        SUM(ws.ws_ext_sales_price) AS total_ext_sales_price,
        SUM(ws.ws_quantity) AS total_quantity
    FROM web_sales ws
    WHERE ws.ws_ext_sales_price > 0
      AND ws.ws_sold_date_sk BETWEEN 2450000 AND 2455000
    GROUP BY ws.ws_bill_customer_sk, ws.ws_web_page_sk
),
web_sales_customers AS (
    SELECT DISTINCT ws.ws_bill_customer_sk AS c_customer_sk
    FROM web_sales ws
    WHERE ws.ws_net_profit < 0
),
catalog_return_customers AS (
    SELECT DISTINCT cr.cr_refunded_customer_sk AS c_customer_sk
    FROM catalog_returns cr
    WHERE cr.cr_return_quantity > 0
)
SELECT
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    s.s_store_name,
    s.s_state,
    cd.cd_gender,
    hd.hd_buy_potential,
    ib.ib_lower_bound,
    sr_agg.total_return_qty,
    sr_agg.total_net_loss,
    wsa.total_ext_sales_price,
    wp.wp_link_count,
    (SELECT AVG(total_net_loss) FROM store_return_agg) AS avg_store_net_loss
FROM store_return_agg sr_agg
JOIN store s
    ON sr_agg.sr_store_sk = s.s_store_sk
JOIN store_returns sr
    ON sr.sr_store_sk = s.s_store_sk
JOIN customer c
    ON sr.sr_customer_sk = c.c_customer_sk
JOIN catalog_returns cr
    ON cr.cr_refunded_customer_sk = c.c_customer_sk
JOIN customer_demographics cd
    ON sr.sr_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd
    ON sr.sr_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib
    ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN web_sales_agg wsa
    ON wsa.c_customer_sk = c.c_customer_sk
JOIN web_page wp
    ON wsa.ws_web_page_sk = wp.wp_web_page_sk
    AND wp.wp_customer_sk = c.c_customer_sk
WHERE s.s_state = 'CA'
  AND wp.wp_link_count > 10
  AND ib.ib_lower_bound >= 50000
  AND c.c_birth_year BETWEEN 1970 AND 1990
  AND wsa.total_ext_sales_price > 1000
  AND cr.cr_return_amount > 0
  AND EXISTS (
      SELECT 1
      FROM catalog_returns cr2
      WHERE cr2.cr_refunded_customer_sk = c.c_customer_sk
        AND cr2.cr_return_quantity > 0
  )
  AND c.c_customer_sk IN (
      SELECT c_customer_sk FROM web_sales_customers
      EXCEPT
      SELECT c_customer_sk FROM catalog_return_customers
  )
GROUP BY
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    s.s_store_name,
    s.s_state,
    cd.cd_gender,
    hd.hd_buy_potential,
    ib.ib_lower_bound,
    sr_agg.total_return_qty,
    sr_agg.total_net_loss,
    wsa.total_ext_sales_price,
    wp.wp_link_count
ORDER BY sr_agg.total_net_loss DESC
LIMIT 100
