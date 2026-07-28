WITH base AS (
   SELECT
       ws.ws_item_sk,
       i.i_brand,
       i.i_category,
       d.d_year,
       ws.ws_quantity,
       ws.ws_ext_sales_price,
       ws.ws_net_profit,
       p.p_discount_active,
       CASE WHEN ws.ws_ext_discount_amt > 0 THEN 'Discounted' ELSE 'FullPrice' END AS sale_type,
       cc.cc_company,
       cp.cp_department,
       hd.hd_vehicle_count,
       ib.ib_lower_bound,
       r.r_reason_desc,
       sm.sm_type,
       t.t_hour,
       wp.wp_url,
       cd.cd_gender,
       cust.c_first_name,
       sr.sr_return_quantity,
       wr.wr_return_quantity
   FROM web_sales ws
   JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
   JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
   JOIN item i ON ws.ws_item_sk = i.i_item_sk
   JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
   JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
   JOIN customer cust ON ws.ws_bill_customer_sk = cust.c_customer_sk
   LEFT JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
   LEFT JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
   LEFT JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
   LEFT JOIN call_center cc ON cc.cc_closed_date_sk = d.d_date_sk
   LEFT JOIN catalog_page cp ON cp.cp_start_date_sk = d.d_date_sk
   LEFT JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
   LEFT JOIN store_returns sr ON sr.sr_item_sk = i.i_item_sk AND sr.sr_returned_date_sk = d.d_date_sk
   LEFT JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number AND wr.wr_item_sk = i.i_item_sk
   LEFT JOIN reason r ON r.r_reason_sk = COALESCE(sr.sr_reason_sk, wr.wr_reason_sk)
   WHERE d.d_year = 2002
     AND i.i_brand = 'Brand#23'
     AND p.p_discount_active = 'Y'
     AND hd.hd_vehicle_count >= 0
     AND cc.cc_company = 3
),
agg1 AS (
   SELECT
       i_brand,
       i_category,
       sale_type,
       COUNT(*) AS sales_cnt,
       SUM(ws_ext_sales_price) AS sales_amount,
       SUM(ws_net_profit) AS profit_sum
   FROM base
   GROUP BY i_brand, i_category, sale_type
)
SELECT
   i_brand,
   i_category,
   SUM(sales_cnt) AS total_transactions,
   SUM(sales_amount) AS total_sales_amount,
   AVG(profit_sum / sales_cnt) AS avg_profit_per_tx,
   CASE WHEN AVG(profit_sum / sales_cnt) > (
            SELECT AVG(ws2.ws_net_profit)
            FROM web_sales ws2
            JOIN date_dim d2 ON ws2.ws_sold_date_sk = d2.d_date_sk
            WHERE d2.d_year = 2002
        )
        THEN 'Above Avg' ELSE 'Below Avg' END AS profit_vs_overall
FROM agg1
WHERE sales_amount > 10000
GROUP BY i_brand, i_category
HAVING SUM(sales_cnt) > 200
ORDER BY total_sales_amount DESC
LIMIT 10
