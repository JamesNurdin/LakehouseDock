WITH sr_agg AS (
   SELECT
       sr_item_sk,
       sr_returned_date_sk,
       SUM(sr_return_amt) AS total_return_amt,
       COUNT(*) AS cnt_returns
   FROM store_returns
   WHERE sr_return_quantity > 0
     AND sr_returned_date_sk IS NOT NULL
   GROUP BY sr_item_sk, sr_returned_date_sk
),
union_data AS (
   SELECT
       d.d_year,
       i.i_category,
       sm.sm_carrier AS ship_mode_carrier,
       sr_agg.total_return_amt,
       cr.cr_return_amount,
       ws.ws_net_paid,
       wr.wr_return_amt
   FROM sr_agg
   JOIN item i ON sr_agg.sr_item_sk = i.i_item_sk
   JOIN date_dim d ON sr_agg.sr_returned_date_sk = d.d_date_sk
   LEFT JOIN catalog_returns cr ON cr.cr_item_sk = i.i_item_sk
                                 AND cr.cr_returned_date_sk = d.d_date_sk
   LEFT JOIN ship_mode sm ON sm.sm_ship_mode_sk = cr.cr_ship_mode_sk
   LEFT JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
                           AND ws.ws_sold_date_sk = d.d_date_sk
   LEFT JOIN web_returns wr ON wr.wr_item_sk = i.i_item_sk
                             AND wr.wr_returned_date_sk = d.d_date_sk
                             AND wr.wr_order_number = ws.ws_order_number
   LEFT JOIN web_site wsite ON wsite.web_site_sk = ws.ws_web_site_sk
   LEFT JOIN customer_demographics cd ON cd.cd_demo_sk = cr.cr_refunded_cdemo_sk
   WHERE d.d_year = 2000
     AND i.i_brand_id = 10
     AND sm.sm_carrier = 'DHL'
),
union_data2 AS (
   SELECT
       d.d_year,
       i.i_category,
       sm.sm_carrier AS ship_mode_carrier,
       sr_agg.total_return_amt,
       cr.cr_return_amount,
       ws.ws_net_paid,
       wr.wr_return_amt
   FROM sr_agg
   JOIN item i ON sr_agg.sr_item_sk = i.i_item_sk
   JOIN date_dim d ON sr_agg.sr_returned_date_sk = d.d_date_sk
   LEFT JOIN catalog_returns cr ON cr.cr_item_sk = i.i_item_sk
                                 AND cr.cr_returned_date_sk = d.d_date_sk
   LEFT JOIN ship_mode sm ON sm.sm_ship_mode_sk = cr.cr_ship_mode_sk
   LEFT JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
                           AND ws.ws_sold_date_sk = d.d_date_sk
   LEFT JOIN web_returns wr ON wr.wr_item_sk = i.i_item_sk
                             AND wr.wr_returned_date_sk = d.d_date_sk
                             AND wr.wr_order_number = ws.ws_order_number
   LEFT JOIN web_site wsite ON wsite.web_site_sk = ws.ws_web_site_sk
   LEFT JOIN customer_demographics cd ON cd.cd_demo_sk = cr.cr_refunded_cdemo_sk
   WHERE d.d_year = 2001
     AND i.i_brand_id = 20
     AND sm.sm_carrier = 'ZOUROS'
)
SELECT
   final.d_year,
   final.i_category,
   final.ship_mode_carrier,
   SUM(final.total_return_amt) AS sum_total_return_amt,
   SUM(final.cr_return_amount) AS sum_cr_return_amount,
   SUM(final.ws_net_paid) AS sum_ws_net_paid,
   SUM(final.wr_return_amt) AS sum_wr_return_amt,
   ROW_NUMBER() OVER (ORDER BY SUM(final.total_return_amt) DESC) AS rn
FROM (
   SELECT * FROM union_data
   UNION
   SELECT * FROM union_data2
) AS final
GROUP BY final.d_year, final.i_category, final.ship_mode_carrier
ORDER BY sum_total_return_amt DESC
LIMIT 100
