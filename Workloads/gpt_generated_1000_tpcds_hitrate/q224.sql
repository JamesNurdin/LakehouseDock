WITH joined AS (
    SELECT
        site.web_site_id,
        site.web_name,
        promo.p_promo_name,
        sm.sm_ship_mode_id,
        cd_bill.cd_gender,
        wp_current.wp_rec_start_date,
        ws.ws_net_profit,
        ws.ws_ext_sales_price,
        ws.ws_ext_discount_amt
    FROM tpcds.web_sales ws
    JOIN tpcds.customer_demographics cd_bill
        ON ws.ws_bill_cdemo_sk = cd_bill.cd_demo_sk
    JOIN tpcds.customer_demographics cd_ship
        ON ws.ws_ship_cdemo_sk = cd_ship.cd_demo_sk
    JOIN tpcds.promotion promo
        ON ws.ws_promo_sk = promo.p_promo_sk
    JOIN tpcds.promotion promo_alt
        ON ws.ws_promo_sk = promo_alt.p_promo_sk
    JOIN tpcds.ship_mode sm
        ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN tpcds.web_site site
        ON ws.ws_web_site_sk = site.web_site_sk
    JOIN tpcds.web_page wp_current
        ON ws.ws_web_page_sk = wp_current.wp_web_page_sk
    JOIN tpcds.web_page wp_prev
        ON ws.ws_web_page_sk = wp_prev.wp_web_page_sk
    JOIN tpcds.store_returns sr
        ON sr.sr_cdemo_sk = cd_bill.cd_demo_sk
    WHERE wp_current.wp_rec_start_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
      AND EXISTS (
          SELECT 1 FROM tpcds.store_returns sr2
          WHERE sr2.sr_return_amt > 100 AND sr2.sr_cdemo_sk = cd_bill.cd_demo_sk
      )
),
aggregated AS (
    SELECT
        web_site_id,
        p_promo_name,
        sm_ship_mode_id,
        cd_gender,
        wp_rec_start_date,
        SUM(ws_net_profit) AS sum_profit,
        SUM(ws_ext_sales_price) AS sum_sales,
        AVG(ws_ext_discount_amt) AS avg_discount
    FROM joined
    GROUP BY
        web_site_id,
        p_promo_name,
        sm_ship_mode_id,
        cd_gender,
        wp_rec_start_date
)
SELECT
    web_site_id,
    p_promo_name,
    sm_ship_mode_id,
    cd_gender,
    wp_rec_start_date,
    sum_profit,
    sum_sales,
    avg_discount,
    LAG(sum_profit) OVER (PARTITION BY web_site_id ORDER BY wp_rec_start_date) AS prior_site_profit,
    (SELECT AVG(p_cost) FROM tpcds.promotion WHERE p_promo_name = aggregated.p_promo_name) AS avg_promo_cost
FROM aggregated
ORDER BY sum_profit DESC
LIMIT 100
