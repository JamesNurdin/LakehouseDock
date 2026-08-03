WITH store_base AS (
   SELECT
      ss.ss_sold_date_sk,
      ss.ss_sold_time_sk,
      ss.ss_item_sk,
      ss.ss_customer_sk,
      ss.ss_cdemo_sk,
      ss.ss_hdemo_sk,
      ss.ss_net_profit,
      ss.ss_net_paid,
      d.d_year,
      i.i_category
   FROM store_sales ss
   JOIN date_dim d        ON ss.ss_sold_date_sk = d.d_date_sk
   JOIN time_dim t        ON ss.ss_sold_time_sk = t.t_time_sk
   JOIN item i            ON ss.ss_item_sk = i.i_item_sk
   JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
   JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
   WHERE d.d_year = 1998
)
SELECT
   sb.d_year,
   sb.i_category,
   COUNT(DISTINCT sb.ss_customer_sk)          AS distinct_store_customers,
   SUM(sb.ss_net_profit)                     AS total_store_profit,
   COUNT(DISTINCT ws.ws_bill_customer_sk)    AS distinct_web_customers,
   SUM(ws.ws_net_profit)                     AS total_web_profit,
   SUM(cr.cr_net_loss)                       AS total_return_loss,
   COUNT(DISTINCT cr.cr_refunded_customer_sk) AS distinct_return_customers
FROM store_base sb
LEFT JOIN catalog_returns cr          ON sb.ss_item_sk = cr.cr_item_sk
                                      AND sb.ss_sold_date_sk = cr.cr_returned_date_sk
LEFT JOIN date_dim d_ret              ON cr.cr_returned_date_sk = d_ret.d_date_sk
LEFT JOIN time_dim t_ret              ON cr.cr_returned_time_sk = t_ret.t_time_sk
LEFT JOIN ship_mode sm_ret           ON cr.cr_ship_mode_sk = sm_ret.sm_ship_mode_sk
LEFT JOIN reason r_ret                ON cr.cr_reason_sk = r_ret.r_reason_sk
LEFT JOIN web_sales ws                ON sb.ss_item_sk = ws.ws_item_sk
                                      AND sb.ss_sold_date_sk = ws.ws_sold_date_sk
LEFT JOIN date_dim d_web               ON ws.ws_sold_date_sk = d_web.d_date_sk
LEFT JOIN time_dim t_web               ON ws.ws_sold_time_sk = t_web.t_time_sk
LEFT JOIN ship_mode sm_web             ON ws.ws_ship_mode_sk = sm_web.sm_ship_mode_sk
GROUP BY sb.d_year, sb.i_category
ORDER BY total_store_profit DESC
LIMIT 100
