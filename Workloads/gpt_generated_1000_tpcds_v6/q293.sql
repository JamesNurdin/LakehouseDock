WITH joined_data AS (
   SELECT
      ss.ss_ticket_number,
      ss.ss_sold_date_sk,
      ss.ss_sold_time_sk,
      ss.ss_item_sk,
      ss.ss_cdemo_sk,
      ss.ss_hdemo_sk,
      ss.ss_quantity,
      ss.ss_ext_sales_price,
      ss.ss_coupon_amt,
      ss.ss_net_paid,
      ss.ss_net_profit,
      sr.sr_return_quantity,
      sr.sr_return_amt,
      sr.sr_net_loss AS store_return_loss,
      i.i_category,
      i.i_brand,
      cd.cd_gender,
      cd.cd_marital_status,
      cd.cd_purchase_estimate,
      hd.hd_income_band_sk,
      td.t_time,
      td.t_sub_shift,
      ws.ws_ext_sales_price AS ws_ext_sales_price,
      ws.ws_net_profit AS ws_net_profit,
      cr.cr_net_loss,
      cc.cc_name
   FROM store_sales ss
   JOIN time_dim td
     ON ss.ss_sold_time_sk = td.t_time_sk
   JOIN item i
     ON ss.ss_item_sk = i.i_item_sk
   JOIN customer_demographics cd
     ON ss.ss_cdemo_sk = cd.cd_demo_sk
   JOIN household_demographics hd
     ON ss.ss_hdemo_sk = hd.hd_demo_sk
   JOIN store_returns sr
     ON sr.sr_ticket_number = ss.ss_ticket_number
    AND sr.sr_item_sk = ss.ss_item_sk
   JOIN web_sales ws
     ON ws.ws_item_sk = i.i_item_sk
    AND ws.ws_sold_time_sk = td.t_time_sk
   JOIN web_returns wr
     ON wr.wr_order_number = ws.ws_order_number
    AND wr.wr_item_sk = i.i_item_sk
   JOIN catalog_returns cr
     ON cr.cr_item_sk = i.i_item_sk
    AND cr.cr_returned_time_sk = td.t_time_sk
   JOIN call_center cc
     ON cr.cr_call_center_sk = cc.cc_call_center_sk
   WHERE cd.cd_purchase_estimate BETWEEN 3000 AND 10000
     AND cd.cd_marital_status = 'M'
     AND td.t_sub_shift = 'morning'
     AND td.t_time >= 6
     AND ss.ss_coupon_amt > 1000
     AND i.i_brand = 'BrandX'
),
union_sales AS (
   SELECT i_category,
          SUM(ss_ext_sales_price) AS sales,
          'store' AS channel
   FROM joined_data
   GROUP BY i_category
   UNION ALL
   SELECT i_category,
          SUM(ws_ext_sales_price) AS sales,
          'web' AS channel
   FROM joined_data
   GROUP BY i_category
)
SELECT
   us.i_category,
   us.channel,
   us.sales,
   ROW_NUMBER() OVER (PARTITION BY us.channel ORDER BY us.sales DESC) AS rank_in_channel,
   (SELECT AVG(cd3.cd_purchase_estimate) FROM customer_demographics cd3) AS overall_avg_purchase_estimate,
   (SELECT MAX(jd.store_return_loss) FROM joined_data jd WHERE jd.i_category = us.i_category) AS max_store_return_loss,
   (SELECT MIN(jd.ws_net_profit) FROM joined_data jd WHERE jd.i_category = us.i_category) AS min_web_profit
FROM union_sales us
ORDER BY us.sales DESC
LIMIT 100
