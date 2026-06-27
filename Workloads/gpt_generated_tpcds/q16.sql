SELECT
    d.d_year,
    d.d_moy,
    i.i_category,
    cd.cd_gender,
    p.p_promo_name,
    sm.sm_type,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    SUM(ws.ws_ext_discount_amt) AS total_discount,
    SUM(ws.ws_net_profit) AS total_profit,
    (SUM(ws.ws_ext_discount_amt) / NULLIF(SUM(ws.ws_ext_sales_price), 0)) * 100 AS discount_pct
FROM web_sales ws
JOIN date_dim d
  ON ws.ws_sold_date_sk = d.d_date_sk
JOIN item i
  ON ws.ws_item_sk = i.i_item_sk
JOIN promotion p
  ON ws.ws_promo_sk = p.p_promo_sk
JOIN ship_mode sm
  ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
JOIN customer_demographics cd
  ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
WHERE d.d_date BETWEEN DATE '2020-01-01' AND DATE '2020-12-31'
GROUP BY
    d.d_year,
    d.d_moy,
    i.i_category,
    cd.cd_gender,
    p.p_promo_name,
    sm.sm_type
HAVING SUM(ws.ws_ext_sales_price) > 0
ORDER BY
    d.d_year,
    d.d_moy,
    i.i_category,
    total_sales DESC
