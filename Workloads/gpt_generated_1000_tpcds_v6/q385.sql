WITH joined_data AS (
   SELECT
       td.t_hour,
       s.s_state,
       cd.cd_gender,
       hd.hd_buy_potential,
       c.c_customer_sk,
       ss.ss_net_paid,
       ss.ss_net_profit,
       ss.ss_quantity,
       cs.cs_net_paid,
       cs.cs_net_profit,
       ws.ws_net_paid,
       ws.ws_net_profit,
       cr.cr_net_loss,
       cr.cr_return_quantity,
       wr.wr_net_loss,
       wr.wr_return_quantity
   FROM time_dim td
   JOIN store_sales ss ON ss.ss_sold_time_sk = td.t_time_sk
   JOIN store s ON s.s_store_sk = ss.ss_store_sk
   JOIN customer c ON c.c_customer_sk = ss.ss_customer_sk
   JOIN customer_demographics cd ON cd.cd_demo_sk = ss.ss_cdemo_sk
   JOIN household_demographics hd ON hd.hd_demo_sk = ss.ss_hdemo_sk
   JOIN customer_address ca ON ca.ca_address_sk = ss.ss_addr_sk
   JOIN catalog_sales cs ON cs.cs_sold_time_sk = td.t_time_sk
   JOIN catalog_returns cr ON cr.cr_returned_time_sk = td.t_time_sk
       AND cr.cr_item_sk = cs.cs_item_sk
   JOIN web_sales ws ON ws.ws_sold_time_sk = td.t_time_sk
   JOIN web_returns wr ON wr.wr_returned_time_sk = td.t_time_sk
       AND wr.wr_item_sk = ws.ws_item_sk
   JOIN income_band ib ON ib.ib_income_band_sk = hd.hd_income_band_sk
   WHERE td.t_hour BETWEEN 9 AND 17
     AND s.s_state = 'CA'
     AND cd.cd_gender = 'M'
     AND ib.ib_upper_bound >= 60000
     AND hd.hd_buy_potential = '1001-5000'
)
SELECT
    t_hour,
    s_state,
    cd_gender,
    hd_buy_potential,
    COUNT(DISTINCT c_customer_sk) AS unique_customers,
    SUM(ss_net_paid) AS total_store_sales,
    SUM(cs_net_paid) AS total_catalog_sales,
    SUM(ws_net_paid) AS total_web_sales,
    SUM(cr_net_loss) AS total_catalog_returns_loss,
    SUM(wr_net_loss) AS total_web_returns_loss,
    SUM(CASE WHEN cr_net_loss > 0 THEN cr_net_loss ELSE 0 END) AS catalog_positive_loss,
    AVG(ss_quantity) AS avg_store_quantity,
    COUNT(*) AS total_records
FROM joined_data
GROUP BY
    t_hour,
    s_state,
    cd_gender,
    hd_buy_potential
ORDER BY total_store_sales DESC
LIMIT 100
