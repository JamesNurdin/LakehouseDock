WITH
  base_sales AS (
    SELECT
      ss.ss_sold_date_sk,
      ss.ss_sold_time_sk,
      ss.ss_item_sk,
      ss.ss_customer_sk,
      ss.ss_cdemo_sk,
      ss.ss_hdemo_sk,
      ss.ss_addr_sk,
      ss.ss_ticket_number,
      ss.ss_quantity,
      ss.ss_net_paid,
      ss.ss_net_profit,
      cs.cs_ext_sales_price,
      cs.cs_net_paid AS cs_net_paid,
      cs.cs_net_profit AS cs_net_profit,
      i.i_brand,
      i.i_category,
      c.c_first_name,
      c.c_last_name,
      cd.cd_gender,
      hd.hd_income_band_sk,
      ca.ca_state,
      d.d_year,
      w.w_warehouse_name,
      sm.sm_type,
      sr.sr_return_quantity,
      sr.sr_returned_date_sk,
      sr.sr_return_time_sk,
      sr.sr_net_loss
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN store_returns sr
      ON sr.sr_ticket_number = ss.ss_ticket_number
     AND sr.sr_item_sk = ss.ss_item_sk
    LEFT JOIN catalog_sales cs
      ON cs.cs_item_sk = ss.ss_item_sk
     AND cs.cs_sold_date_sk = ss.ss_sold_date_sk
    LEFT JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    LEFT JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    LEFT JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN inventory inv
      ON inv.inv_item_sk = i.i_item_sk
     AND inv.inv_date_sk = ss.ss_sold_date_sk
     AND inv.inv_warehouse_sk = w.w_warehouse_sk
  ),
  aggregated AS (
    SELECT
      bs.ss_sold_date_sk,
      bs.ss_item_sk,
      bs.ss_customer_sk,
      d.d_year,
      i.i_category,
      ca.ca_state,
      d_ret.d_year AS return_year,
      t_ret.t_hour AS return_hour,
      SUM(bs.ss_net_profit) AS total_net_profit,
      AVG(bs.ss_net_paid) AS avg_net_paid,
      COUNT(DISTINCT bs.ss_customer_sk) AS distinct_customers,
      COUNT(DISTINCT bs.ss_item_sk) AS distinct_items,
      CASE WHEN SUM(bs.ss_net_profit) > 0 THEN 'OverallPositive' ELSE 'OverallNonPositive' END AS overall_profit_flag,
      (
        SELECT AVG(cs2.cs_ext_sales_price)
        FROM catalog_sales cs2
        WHERE cs2.cs_sold_date_sk = bs.ss_sold_date_sk
      ) AS avg_sales_price_by_date
    FROM base_sales bs
    JOIN date_dim d ON bs.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON bs.ss_item_sk = i.i_item_sk
    JOIN customer_address ca ON bs.ss_addr_sk = ca.ca_address_sk
    LEFT JOIN store_returns sr ON sr.sr_ticket_number = bs.ss_ticket_number AND sr.sr_item_sk = bs.ss_item_sk
    LEFT JOIN date_dim d_ret ON sr.sr_returned_date_sk = d_ret.d_date_sk
    LEFT JOIN time_dim t_ret ON sr.sr_return_time_sk = t_ret.t_time_sk
    GROUP BY
      bs.ss_sold_date_sk,
      bs.ss_item_sk,
      bs.ss_customer_sk,
      d.d_year,
      i.i_category,
      ca.ca_state,
      d_ret.d_year,
      t_ret.t_hour
  )
SELECT
  a.d_year,
  a.i_category,
  a.ca_state,
  a.return_year,
  a.return_hour,
  a.total_net_profit,
  a.avg_net_paid,
  a.distinct_customers,
  a.distinct_items,
  a.overall_profit_flag,
  a.avg_sales_price_by_date,
  ROW_NUMBER() OVER (PARTITION BY a.ss_customer_sk ORDER BY a.d_year DESC) AS rn
FROM aggregated a
JOIN store_sales ss
  ON a.ss_sold_date_sk = ss.ss_sold_date_sk
 AND a.ss_item_sk = ss.ss_item_sk
 AND a.ss_customer_sk = ss.ss_customer_sk
WHERE a.total_net_profit IS NOT NULL
ORDER BY a.total_net_profit DESC
LIMIT 100
