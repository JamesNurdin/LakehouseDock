WITH cs_joined AS (
       SELECT
           cs.cs_sold_time_sk,
           cs.cs_ship_mode_sk,
           cs.cs_bill_cdemo_sk,
           cs.cs_bill_hdemo_sk,
           cs.cs_ext_sales_price,
           cs.cs_net_profit,
           cs.cs_order_number,
           cs.cs_catalog_page_sk,
           cs.cs_ext_tax,
           cs.cs_coupon_amt
       FROM tpcds.catalog_sales cs
       WHERE cs.cs_ext_tax > 10
         AND cs.cs_coupon_amt < 500
   ),
   cp AS (
       SELECT
           cp.cp_catalog_page_sk,
           cp.cp_department,
           cp.cp_catalog_number,
           cp.cp_type
       FROM tpcds.catalog_page cp
       WHERE cp.cp_catalog_number BETWEEN 10 AND 30
   ),
   time AS (
       SELECT
           t.t_time_sk,
           t.t_hour,
           t.t_meal_time
       FROM tpcds.time_dim t
       WHERE t.t_hour BETWEEN 9 AND 17
   ),
   sm AS (
       SELECT
           sm.sm_ship_mode_sk,
           sm.sm_type,
           sm.sm_carrier
       FROM tpcds.ship_mode sm
       WHERE sm.sm_type = 'AIR'
   ),
   cd AS (
       SELECT
           cd.cd_demo_sk,
           cd.cd_gender,
           cd.cd_credit_rating
       FROM tpcds.customer_demographics cd
       WHERE cd.cd_credit_rating IN ('AA','A')
   ),
   hd AS (
       SELECT
           hd.hd_demo_sk,
           hd.hd_income_band_sk,
           hd.hd_buy_potential
       FROM tpcds.household_demographics hd
       WHERE hd.hd_income_band_sk BETWEEN 5 AND 7
   ),
   ws AS (
       SELECT
           ws.ws_order_number,
           ws.ws_sold_time_sk,
           ws.ws_ship_mode_sk,
           ws.ws_web_site_sk,
           ws.ws_ext_sales_price,
           ws.ws_net_profit,
           ws.ws_quantity
       FROM tpcds.web_sales ws
       WHERE ws.ws_quantity > 2
   ),
   site AS (
       SELECT
           s.web_site_sk,
           s.web_site_id,
           s.web_rec_end_date,
           s.web_company_id,
           s.web_state
       FROM tpcds.web_site s
       WHERE s.web_state = 'CA'
         AND s.web_rec_end_date > DATE '2000-01-01'
   )
SELECT
    cp.cp_department,
    cp.cp_type,
    sm.sm_type,
    sm.sm_carrier,
    cd.cd_gender,
    hd.hd_buy_potential,
    time.t_meal_time,
    cs.cs_ext_sales_price AS catalog_sales_price,
    ws.ws_ext_sales_price AS web_sales_price,
    (cs.cs_ext_sales_price + ws.ws_ext_sales_price) AS total_sales_price,
    CASE
        WHEN cs.cs_net_profit > ws.ws_net_profit THEN 'CatalogHigher'
        WHEN cs.cs_net_profit < ws.ws_net_profit THEN 'WebHigher'
        ELSE 'Equal'
    END AS profit_comparison,
    ROW_NUMBER() OVER (PARTITION BY cp.cp_department ORDER BY (cs.cs_ext_sales_price + ws.ws_ext_sales_price) DESC) AS dept_rank,
    AVG(cs.cs_ext_sales_price) OVER (PARTITION BY sm.sm_type) AS avg_catalog_price_by_ship_type
FROM cs_joined cs
JOIN cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN time ON cs.cs_sold_time_sk = time.t_time_sk
JOIN sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
JOIN hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
JOIN ws ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
JOIN site ON ws.ws_web_site_sk = site.web_site_sk
WHERE EXISTS (
        SELECT 1
        FROM tpcds.catalog_page cp2
        WHERE cp2.cp_type = cp.cp_type
          AND cp2.cp_department = cp.cp_department
    )
  AND site.web_company_id IN (
        SELECT DISTINCT cs2.cs_bill_cdemo_sk
        FROM tpcds.catalog_sales cs2
        WHERE cs2.cs_ext_discount_amt > 0
    )
ORDER BY total_sales_price DESC
LIMIT 100
