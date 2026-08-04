WITH
    sampled_sales AS (
        SELECT *
        FROM web_sales
        TABLESAMPLE BERNOULLI (10)
    ),
    distinct_promos AS (
        SELECT DISTINCT p_promo_sk, p_promo_name, p_response_target
        FROM promotion
    )
SELECT
    ws.ws_order_number,
    ws.ws_sold_date_sk,
    ws.ws_net_paid_inc_ship,
    ws.ws_quantity,
    cdb_bill.cd_gender,
    hdb_bill.hd_buy_potential,
    inc.ib_lower_bound,
    inc.ib_upper_bound,
    sm.sm_type,
    wh.w_warehouse_name,
    wp.wp_url,
    ws_site.web_site_id,
    dp.p_promo_name,
    ROW_NUMBER() OVER (PARTITION BY ws_site.web_site_id ORDER BY ws.ws_net_paid_inc_ship DESC) AS rn,
    (SELECT SUM(wr_sub.wr_return_amt)
       FROM web_returns wr_sub
      WHERE wr_sub.wr_web_page_sk = wp.wp_web_page_sk) AS total_return_amt_for_page
FROM sampled_sales ws
JOIN time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
JOIN distinct_promos dp ON ws.ws_promo_sk = dp.p_promo_sk
JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse wh ON ws.ws_warehouse_sk = wh.w_warehouse_sk
JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN web_site ws_site ON ws.ws_web_site_sk = ws_site.web_site_sk
JOIN customer_demographics cdb_bill ON ws.ws_bill_cdemo_sk = cdb_bill.cd_demo_sk
JOIN household_demographics hdb_bill ON ws.ws_bill_hdemo_sk = hdb_bill.hd_demo_sk
JOIN customer_demographics cdb_ship ON ws.ws_ship_cdemo_sk = cdb_ship.cd_demo_sk
JOIN household_demographics hdb_ship ON ws.ws_ship_hdemo_sk = hdb_ship.hd_demo_sk
JOIN income_band inc ON hdb_bill.hd_income_band_sk = inc.ib_income_band_sk
WHERE NOT EXISTS (
    SELECT 1
      FROM web_returns wr_no
     WHERE wr_no.wr_order_number = ws.ws_order_number
       AND wr_no.wr_return_quantity > 5
)
GROUP BY
    ws.ws_order_number,
    ws.ws_sold_date_sk,
    ws.ws_net_paid_inc_ship,
    ws.ws_quantity,
    cdb_bill.cd_gender,
    hdb_bill.hd_buy_potential,
    inc.ib_lower_bound,
    inc.ib_upper_bound,
    sm.sm_type,
    wh.w_warehouse_name,
    wp.wp_url,
    ws_site.web_site_id,
    dp.p_promo_name,
    wp.wp_web_page_sk
ORDER BY ws.ws_net_paid_inc_ship DESC
OFFSET 0
LIMIT 100
