WITH store_sales_agg AS (
    SELECT
        ss_customer_sk,
        ss_sold_date_sk,
        ss_cdemo_sk,
        ss_hdemo_sk,
        SUM(ss_net_paid) AS store_net_paid,
        SUM(ss_quantity) AS store_quantity
    FROM tpcds.store_sales
    WHERE ss_quantity > 0
    GROUP BY ss_customer_sk, ss_sold_date_sk, ss_cdemo_sk, ss_hdemo_sk
),
web_sales_agg AS (
    SELECT
        ws_sold_date_sk,
        ws_ship_mode_sk,
        ws_web_page_sk,
        ws_web_site_sk,
        SUM(ws_net_paid) AS web_net_paid,
        SUM(ws_quantity) AS web_quantity
    FROM tpcds.web_sales
    WHERE ws_quantity > 0
    GROUP BY ws_sold_date_sk, ws_ship_mode_sk, ws_web_page_sk, ws_web_site_sk
)
SELECT
    d.d_year,
    c.c_customer_id,
    cd.cd_gender,
    hd.hd_buy_potential,
    cc.cc_name,
    sm.sm_code,
    wp.wp_type,
    ws_site.web_name,
    SUM(ss_agg.store_net_paid) AS total_store_net_paid,
    SUM(ws_agg.web_net_paid) AS total_web_net_paid,
    (SUM(ss_agg.store_net_paid) + SUM(ws_agg.web_net_paid)) AS total_net_paid
FROM store_sales_agg ss_agg
JOIN tpcds.date_dim d
  ON ss_agg.ss_sold_date_sk = d.d_date_sk
JOIN tpcds.customer c
  ON ss_agg.ss_customer_sk = c.c_customer_sk
JOIN tpcds.customer_demographics cd
  ON ss_agg.ss_cdemo_sk = cd.cd_demo_sk
JOIN tpcds.household_demographics hd
  ON ss_agg.ss_hdemo_sk = hd.hd_demo_sk
JOIN tpcds.call_center cc
  ON cc.cc_open_date_sk = d.d_date_sk
JOIN web_sales_agg ws_agg
  ON ws_agg.ws_sold_date_sk = d.d_date_sk
JOIN tpcds.ship_mode sm
  ON ws_agg.ws_ship_mode_sk = sm.sm_ship_mode_sk
JOIN tpcds.web_page wp
  ON ws_agg.ws_web_page_sk = wp.wp_web_page_sk
JOIN tpcds.web_site ws_site
  ON ws_agg.ws_web_site_sk = ws_site.web_site_sk
WHERE
    d.d_year = 2001
    AND cc.cc_state = 'TX'
    AND c.c_birth_year BETWEEN 1950 AND 1970
    AND cd.cd_gender = 'M'
    AND sm.sm_code IN ('AIR', 'SEA')
    AND hd.hd_income_band_sk > 3
    AND wp.wp_type = 'Home'
    AND ws_site.web_country = 'United States'
    AND EXISTS (
        SELECT 1
        FROM tpcds.web_sales ws2
        WHERE ws2.ws_bill_customer_sk = c.c_customer_sk
          AND ws2.ws_sold_date_sk = d.d_date_sk
    )
GROUP BY
    d.d_year,
    c.c_customer_id,
    cd.cd_gender,
    hd.hd_buy_potential,
    cc.cc_name,
    sm.sm_code,
    wp.wp_type,
    ws_site.web_name
HAVING
    (SUM(ss_agg.store_net_paid) + SUM(ws_agg.web_net_paid)) > 20000
ORDER BY total_net_paid DESC
LIMIT 100
