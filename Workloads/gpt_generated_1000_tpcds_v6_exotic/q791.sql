WITH filtered_sales AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_item_sk,
        ss.ss_hdemo_sk,
        ss.ss_promo_sk,
        ss.ss_ticket_number,
        ss.ss_quantity,
        ss.ss_ext_sales_price,
        ss.ss_net_profit,
        ss.ss_store_sk
    FROM store_sales ss
    WHERE ss.ss_quantity > 2
      AND ss.ss_ext_sales_price > 10
)
SELECT
    d.d_year,
    i.i_brand,
    i.i_category,
    hd.hd_buy_potential,
    ib.ib_lower_bound,
    p.p_discount_active,
    ws.ws_quantity,
    ws.ws_net_paid,
    web_site.web_mkt_id,
    sm.sm_type,
    SUM(ss.ss_ext_sales_price) AS total_sales,
    AVG(ss.ss_net_profit) AS avg_profit,
    COUNT(DISTINCT ss.ss_ticket_number) AS num_transactions,
    MIN(ss.ss_ext_sales_price) AS min_sale,
    MAX(ss.ss_ext_sales_price) AS max_sale
FROM filtered_sales ss
JOIN date_dim d
    ON ss.ss_sold_date_sk = d.d_date_sk
JOIN item i
    ON ss.ss_item_sk = i.i_item_sk
JOIN household_demographics hd
    ON ss.ss_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib
    ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN promotion p
    ON ss.ss_promo_sk = p.p_promo_sk
LEFT JOIN web_sales ws
    ON ws.ws_sold_date_sk = d.d_date_sk
LEFT JOIN web_site
    ON ws.ws_web_site_sk = web_site.web_site_sk
       AND web_site.web_mkt_id = 3
LEFT JOIN ship_mode sm
    ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
LEFT JOIN warehouse w
    ON ws.ws_warehouse_sk = w.w_warehouse_sk
WHERE d.d_year = 2002
  AND i.i_brand = 'Brand#23'
  AND hd.hd_buy_potential = '500-'
  AND ib.ib_lower_bound >= 30000
  AND p.p_discount_active = 'Y'
  AND ws.ws_quantity > 3
  AND sm.sm_type = 'AIR'
  AND NOT EXISTS (
        SELECT 1
        FROM store_returns sr
        WHERE sr.sr_ticket_number = ss.ss_ticket_number
      )
GROUP BY
    d.d_year,
    i.i_brand,
    i.i_category,
    hd.hd_buy_potential,
    ib.ib_lower_bound,
    p.p_discount_active,
    ws.ws_quantity,
    ws.ws_net_paid,
    web_site.web_mkt_id,
    sm.sm_type
LIMIT 100
