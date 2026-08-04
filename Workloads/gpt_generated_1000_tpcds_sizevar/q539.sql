WITH sampled_store_sales AS (
    SELECT *
    FROM store_sales
    TABLESAMPLE BERNOULLI (10)
    WHERE ss_sold_date_sk BETWEEN 2450360 AND 2450895
),
radio_only_promos AS (
    SELECT p_promo_id
    FROM promotion
    WHERE p_channel_radio = 'Y'
    EXCEPT
    SELECT p_promo_id
    FROM promotion
    WHERE p_channel_press = 'Y'
),
max_ship_qty AS (
    SELECT MAX(ws_quantity) AS max_qty
    FROM web_sales
    WHERE ws_ship_mode_sk = (
        SELECT sm_ship_mode_sk
        FROM ship_mode
        WHERE sm_type = 'AIR'
        LIMIT 1
    )
)
SELECT
    s.s_store_name,
    p.p_promo_name,
    COUNT(DISTINCT ss.ss_ticket_number)                AS num_transactions,
    SUM(ss.ss_ext_sales_price)                        AS total_sales,
    AVG(ss.ss_quantity)                               AS avg_quantity,
    MIN(ss.ss_sales_price)                            AS min_price,
    MAX(ss.ss_sales_price)                            AS max_price
FROM sampled_store_sales ss
JOIN store s
  ON ss.ss_store_sk = s.s_store_sk
JOIN promotion p
  ON ss.ss_promo_sk = p.p_promo_sk
JOIN customer c
  ON ss.ss_customer_sk = c.c_customer_sk
JOIN customer_address ca
  ON ss.ss_addr_sk = ca.ca_address_sk
JOIN customer_demographics cd
  ON ss.ss_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd
  ON ss.ss_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib
  ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN web_sales ws
  ON ws.ws_bill_customer_sk = c.c_customer_sk
JOIN ship_mode sm
  ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
JOIN web_page wp
  ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN web_site wsite
  ON ws.ws_web_site_sk = wsite.web_site_sk
WHERE cd.cd_marital_status = 'M'
  AND ib.ib_upper_bound <= 50000
  AND ca.ca_country = 'United States'
  AND wsite.web_state = 'CA'
  AND p.p_promo_id IN (SELECT p_promo_id FROM radio_only_promos)
  AND ss.ss_quantity > (SELECT max_qty FROM max_ship_qty)
  AND EXISTS (
        SELECT 1
        FROM web_page wp2
        WHERE wp2.wp_customer_sk = c.c_customer_sk
          AND wp2.wp_type = 'HOME'
    )
GROUP BY s.s_store_name, p.p_promo_name
ORDER BY total_sales DESC
LIMIT 100
