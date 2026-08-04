WITH full_promo AS (
  SELECT
    ws.ws_sold_date_sk,
    ws.ws_order_number,
    ws.ws_ext_sales_price,
    ws.ws_ext_ship_cost,
    ws.ws_bill_hdemo_sk,
    ws.ws_web_page_sk,
    ws.ws_promo_sk,
    p.p_promo_name,
    p.p_channel_event,
    p.p_channel_press,
    p.p_channel_demo
  FROM web_sales ws
  FULL OUTER JOIN promotion p
    ON ws.ws_promo_sk = p.p_promo_sk
),
filtered AS (
  SELECT
    fp.ws_sold_date_sk,
    fp.ws_order_number,
    fp.ws_ext_sales_price,
    fp.ws_ext_ship_cost,
    fp.ws_bill_hdemo_sk,
    fp.ws_web_page_sk,
    fp.ws_promo_sk,
    fp.p_promo_name,
    fp.p_channel_event,
    hd.hd_buy_potential,
    hd.hd_dep_count,
    wp.wp_type,
    wp.wp_autogen_flag,
    ROW_NUMBER() OVER (PARTITION BY fp.p_promo_name ORDER BY fp.ws_ext_sales_price DESC) AS rn_sales_price,
    SUM(fp.ws_ext_sales_price) OVER (PARTITION BY fp.p_promo_name ORDER BY fp.ws_ext_sales_price DESC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cum_sales_price
  FROM full_promo fp
  JOIN household_demographics hd
    ON fp.ws_bill_hdemo_sk = hd.hd_demo_sk
  JOIN web_page wp
    ON fp.ws_web_page_sk = wp.wp_web_page_sk
  WHERE
    hd.hd_buy_potential IN ('1001-5000', '>10000')
    AND fp.p_channel_event = 'N'
    AND wp.wp_autogen_flag = 'N'
    AND fp.ws_ext_ship_cost > 500
)
SELECT
  f.ws_order_number,
  f.p_promo_name,
  f.hd_buy_potential,
  f.wp_type,
  f.ws_ext_sales_price,
  f.cum_sales_price,
  f.rn_sales_price
FROM filtered f
WHERE f.rn_sales_price <= 5
EXCEPT
SELECT
  ws_order_number,
  p_promo_name,
  hd_buy_potential,
  wp_type,
  ws_ext_sales_price,
  cum_sales_price,
  rn_sales_price
FROM filtered
WHERE hd_dep_count = 1
LIMIT 100
