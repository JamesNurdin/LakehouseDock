WITH cs_agg AS (
       SELECT
           cs_call_center_sk,
           cs_bill_hdemo_sk,
           cs_ship_hdemo_sk,
           cs_bill_addr_sk,
           cs_ship_addr_sk,
           SUM(cs_ext_sales_price) AS total_sales,
           SUM(cs_net_profit)       AS total_profit,
           COUNT(*)                AS sales_cnt
       FROM catalog_sales
       GROUP BY cs_call_center_sk, cs_bill_hdemo_sk, cs_ship_hdemo_sk,
                cs_bill_addr_sk, cs_ship_addr_sk
   ),
   sampled_web_sales AS (
       SELECT *
       FROM web_sales TABLESAMPLE BERNOULLI (10)
   )
SELECT
    cc.cc_name,
    cc.cc_class,
    ca_bill.ca_state          AS bill_state,
    ca_ship.ca_state          AS ship_state,
    hd_bill.hd_income_band_sk AS bill_income_band,
    hd_ship.hd_income_band_sk AS ship_income_band,
    cs_agg.total_sales,
    cs_agg.total_profit,
    ws.ws_ext_sales_price    AS web_sales_price,
    r.r_reason_desc,
    lp.page_cnt,
    (
        SELECT MAX(ws2.ws_ext_sales_price)
        FROM web_sales ws2
        WHERE ws2.ws_bill_customer_sk = cs_agg.cs_call_center_sk
    )                         AS max_web_sales_for_center
FROM call_center cc
JOIN cs_agg
  ON cc.cc_call_center_sk = cs_agg.cs_call_center_sk
-- bill household demographics
JOIN household_demographics hd_bill
  ON cs_agg.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
-- ship household demographics
JOIN household_demographics hd_ship
  ON cs_agg.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
-- bill address
JOIN customer_address ca_bill
  ON cs_agg.cs_bill_addr_sk = ca_bill.ca_address_sk
-- ship address
JOIN customer_address ca_ship
  ON cs_agg.cs_ship_addr_sk = ca_ship.ca_address_sk
-- web sales (sampled) linked to the same bill and ship households
JOIN sampled_web_sales ws
  ON ws.ws_bill_hdemo_sk = hd_bill.hd_demo_sk
 AND ws.ws_ship_hdemo_sk = hd_ship.hd_demo_sk
-- web page used for the web sale
JOIN web_page wp
  ON ws.ws_web_page_sk = wp.wp_web_page_sk
-- lateral sub‑query to count distinct pages for the current page key
CROSS JOIN LATERAL (
    SELECT COUNT(DISTINCT wp2.wp_web_page_id) AS page_cnt
    FROM web_page wp2
    WHERE wp2.wp_web_page_sk = wp.wp_web_page_sk
) AS lp
-- store returns linked to the bill household
JOIN store_returns sr
  ON sr.sr_hdemo_sk = hd_bill.hd_demo_sk
JOIN reason r
  ON sr.sr_reason_sk = r.r_reason_sk
WHERE NOT EXISTS (
        SELECT 1
        FROM store_returns sr2
        WHERE sr2.sr_hdemo_sk = hd_ship.hd_demo_sk
          AND sr2.sr_return_amt > 500
      )
  AND cc.cc_class = 'medium'
ORDER BY cs_agg.total_sales DESC
OFFSET 0 LIMIT 100
