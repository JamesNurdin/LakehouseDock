WITH intersect_items AS (
        SELECT cr_item_sk FROM catalog_returns WHERE cr_return_amount > 0
        INTERSECT
        SELECT wr_item_sk FROM web_returns WHERE wr_return_amt > 0
    ),
    web_base AS (
        SELECT ws.ws_order_number,
               ws.ws_sold_time_sk,
               ws.ws_item_sk,
               ws.ws_quantity,
               ws.ws_sales_price,
               ws.ws_net_paid,
               i.i_category,
               i.i_brand,
               t.t_hour,
               ca.ca_state,
               cd.cd_gender,
               hd.hd_income_band_sk,
               ib.ib_lower_bound,
               sm.sm_carrier,
               wp.wp_type,
               web.web_name,
               web.web_country
        FROM web_sales ws
        JOIN item i               ON ws.ws_item_sk       = i.i_item_sk
        JOIN time_dim t           ON ws.ws_sold_time_sk = t.t_time_sk
        JOIN customer_address ca  ON ws.ws_bill_addr_sk = ca.ca_address_sk
        JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
        JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
        JOIN income_band ib       ON hd.hd_income_band_sk = ib.ib_income_band_sk
        JOIN ship_mode sm         ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
        JOIN web_page wp          ON ws.ws_web_page_sk  = wp.wp_web_page_sk
        JOIN web_site web         ON ws.ws_web_site_sk  = web.web_site_sk
        WHERE ws.ws_item_sk IN (SELECT cr_item_sk FROM intersect_items)
    ),
    web_agg AS (
        SELECT i_category,
               i_brand,
               t_hour,
               SUM(ws_net_paid) AS total_net_paid,
               COUNT(*)          AS cnt_sales,
               AVG(ws_sales_price) AS avg_price
        FROM web_base
        WHERE t_hour BETWEEN 8 AND 17                 -- predicate 1
          AND ca_state = 'CA'                         -- predicate 2
          AND ib_lower_bound >= 50000                 -- predicate 3
          AND sm_carrier = 'United Parcel Service'    -- predicate 4
          AND web_country = 'United States'           -- predicate 5
        GROUP BY i_category, i_brand, t_hour
    )
SELECT wa.i_category,
       wa.i_brand,
       wa.t_hour,
       wa.total_net_paid,
       wa.cnt_sales,
       wa.avg_price,
       LAG(wa.total_net_paid) OVER (PARTITION BY wa.i_category ORDER BY wa.total_net_paid DESC) AS lag_total_net_paid,
       (SELECT AVG(total_net_paid) FROM web_agg) AS overall_avg_net,
       (
           SELECT SUM(ss.ss_net_paid)
           FROM store_sales ss
           JOIN time_dim t2            ON ss.ss_sold_time_sk = t2.t_time_sk
           JOIN item i2                ON ss.ss_item_sk      = i2.i_item_sk
           JOIN customer_address ca2   ON ss.ss_addr_sk      = ca2.ca_address_sk
           JOIN customer_demographics cd2 ON ss.ss_cdemo_sk = cd2.cd_demo_sk
           JOIN household_demographics hd2 ON ss.ss_hdemo_sk = hd2.hd_demo_sk
           JOIN income_band ib2        ON hd2.hd_income_band_sk = ib2.ib_income_band_sk
           WHERE t2.t_hour BETWEEN 8 AND 17
             AND ca2.ca_state = 'CA'
             AND ib2.ib_lower_bound >= 50000
       ) AS store_total_net_paid
FROM web_agg wa
ORDER BY wa.total_net_paid DESC
LIMIT 100
