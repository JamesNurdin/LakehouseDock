WITH filtered_sites AS (
    SELECT DISTINCT
        web_site_sk,
        web_name,
        web_gmt_offset,
        web_street_name
    FROM web_site
    WHERE web_gmt_offset = -5.00
      AND web_street_name LIKE '%Ridge%'
),
agg_sales AS (
    SELECT
        ws_bill_hdemo_sk,
        ws_web_site_sk,
        SUM(ws_net_paid) AS total_net_paid,
        AVG(ws_ext_discount_amt) AS avg_discount,
        COUNT(DISTINCT ws_order_number) AS order_cnt
    FROM web_sales
    WHERE ws_ship_date_sk IN (2451482, 2452638)
      AND ws_coupon_amt > 500.00
      AND ws_wholesale_cost BETWEEN 30.00 AND 80.00
    GROUP BY ws_bill_hdemo_sk, ws_web_site_sk
)
SELECT
    hd.hd_buy_potential,
    ws.web_name,
    SUM(a.total_net_paid) AS sum_net_paid,
    AVG(a.avg_discount) AS avg_discount_across,
    COUNT(DISTINCT hd.hd_demo_sk) AS household_cnt,
    MIN(ib.ib_lower_bound) AS min_income,
    MAX(ib.ib_upper_bound) AS max_income
FROM agg_sales a
JOIN household_demographics hd
  ON a.ws_bill_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib
  ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN filtered_sites ws
  ON a.ws_web_site_sk = ws.web_site_sk
WHERE hd.hd_dep_count <= 2
GROUP BY hd.hd_buy_potential, ws.web_name
ORDER BY sum_net_paid DESC
LIMIT 100
