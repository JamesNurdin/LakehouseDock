WITH full_join AS (
   SELECT
       ss.ss_sold_date_sk,
       ss.ss_quantity               AS ss_quantity,
       ss.ss_net_paid               AS ss_net_paid,
       srs.sr_return_quantity,
       srs.sr_net_loss             AS sr_net_loss,
       cs.cs_quantity               AS cs_quantity,
       cs.cs_net_paid               AS cs_net_paid,
       cr.cr_return_quantity,
       cr.cr_net_loss               AS cr_net_loss,
       ws.ws_quantity               AS ws_quantity,
       ws.ws_net_paid               AS ws_net_paid,
       wr.wr_return_quantity,
       wr.wr_net_loss               AS wr_net_loss,
       i.i_brand,
       i.i_category,
       i.i_class,
       c.c_birth_country,
       cd.cd_gender,
       hd.hd_buy_potential,
       ib.ib_upper_bound,
       sm.sm_carrier,
       wsite.web_name
   FROM store_sales ss
   JOIN item i
     ON ss.ss_item_sk = i.i_item_sk
   JOIN customer c
     ON ss.ss_customer_sk = c.c_customer_sk
   JOIN customer_demographics cd
     ON ss.ss_cdemo_sk = cd.cd_demo_sk
   JOIN household_demographics hd
     ON ss.ss_hdemo_sk = hd.hd_demo_sk
   JOIN income_band ib
     ON hd.hd_income_band_sk = ib.ib_income_band_sk
   JOIN customer_address ca
     ON ss.ss_addr_sk = ca.ca_address_sk
   LEFT JOIN store_returns srs
     ON srs.sr_ticket_number = ss.ss_ticket_number
   LEFT JOIN catalog_sales cs
     ON cs.cs_item_sk = i.i_item_sk
   LEFT JOIN ship_mode sm
     ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
   LEFT JOIN catalog_returns cr
     ON cr.cr_order_number = cs.cs_order_number
   LEFT JOIN web_sales ws
     ON ws.ws_item_sk = i.i_item_sk
   LEFT JOIN web_site wsite
     ON ws.ws_web_site_sk = wsite.web_site_sk
   LEFT JOIN web_returns wr
     ON wr.wr_order_number = ws.ws_order_number
)
SELECT
    brand,
    country,
    gender,
    buy_potential,
    carrier,
    SUM(sales_amount)  AS total_sales,
    SUM(return_amount) AS total_returns,
    COUNT(*)           AS trans_cnt
FROM (
    SELECT
        i_brand        AS brand,
        c_birth_country AS country,
        cd_gender       AS gender,
        hd_buy_potential AS buy_potential,
        sm_carrier      AS carrier,
        (ss_net_paid + cs_net_paid + ws_net_paid) AS sales_amount,
        (COALESCE(sr_net_loss, 0) + COALESCE(cr_net_loss, 0) + COALESCE(wr_net_loss, 0)) AS return_amount
    FROM full_join
    WHERE ss_quantity > 5
      AND cd_gender = 'M'
      AND c_birth_country = 'SWITZERLAND'
      AND i_brand = 'Brand#12'
      AND ib_upper_bound > 50000
      AND sm_carrier = 'UPS'

    UNION ALL

    SELECT
        i_brand,
        c_birth_country,
        cd_gender,
        hd_buy_potential,
        sm_carrier,
        ss_net_paid AS sales_amount,
        (COALESCE(sr_net_loss, 0) + COALESCE(cr_net_loss, 0) + COALESCE(wr_net_loss, 0)) AS return_amount
    FROM full_join
    WHERE ws_quantity > 10
      AND hd_buy_potential = '5000-10000'
      AND ib_upper_bound BETWEEN 30000 AND 70000
      AND c_birth_country = 'KOREA'
      AND cd_gender = 'F'
      AND sm_carrier = 'FEDEX'
) agg
GROUP BY brand, country, gender, buy_potential, carrier
HAVING SUM(sales_amount) > 1000
ORDER BY total_sales DESC
LIMIT 100
