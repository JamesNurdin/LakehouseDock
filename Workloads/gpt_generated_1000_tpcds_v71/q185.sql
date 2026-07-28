/*
Goal:  Compute total net paid, net profit and return losses by call center and month, showing whether the overall profit is positive or negative. The query joins all 14 selected TPC‑DS tables, uses multiple aliases for the date_dim and household_demographics dimensions, includes a LEFT OUTER JOIN to web_site, and contains a CASE expression.
*/
WITH
  -- Aliases for the date dimension used in different roles
  d_cs_sold AS (SELECT * FROM tpcds.date_dim),
  d_sr_ret  AS (SELECT * FROM tpcds.date_dim),
  d_cr_ret  AS (SELECT * FROM tpcds.date_dim),
  d_wr_ret  AS (SELECT * FROM tpcds.date_dim),
  d_inv_dt  AS (SELECT * FROM tpcds.date_dim),
  -- Aliases for the household demographics dimension used in different roles
  hd_bill   AS (SELECT * FROM tpcds.household_demographics),
  hd_ship   AS (SELECT * FROM tpcds.household_demographics),
  hd_sr     AS (SELECT * FROM tpcds.household_demographics),
  hd_cr_ref AS (SELECT * FROM tpcds.household_demographics),
  hd_cr_ret AS (SELECT * FROM tpcds.household_demographics),
  hd_wr_ref AS (SELECT * FROM tpcds.household_demographics),
  hd_wr_ret AS (SELECT * FROM tpcds.household_demographics)
SELECT
  cc.cc_name                                      AS call_center_name,
  d_cs_sold.d_year                                AS year,
  d_cs_sold.d_month_seq                           AS month,
  SUM(cs.cs_net_paid)                            AS total_net_paid,
  SUM(cs.cs_net_profit)                          AS total_net_profit,
  SUM(sr.sr_net_loss)                            AS total_store_return_loss,
  SUM(cr.cr_net_loss)                            AS total_catalog_return_loss,
  SUM(wr.wr_net_loss)                            AS total_web_return_loss,
  CASE WHEN SUM(cs.cs_net_profit) > 0
       THEN 'PROFIT'
       ELSE 'LOSS'
  END                                            AS profit_indicator
FROM
  tpcds.catalog_sales        cs
  JOIN d_cs_sold            ON cs.cs_sold_date_sk = d_cs_sold.d_date_sk
  JOIN tpcds.time_dim       t_cs_sold ON cs.cs_sold_time_sk = t_cs_sold.t_time_sk
  JOIN tpcds.item           i        ON cs.cs_item_sk = i.i_item_sk
  JOIN tpcds.call_center    cc       ON cs.cs_call_center_sk = cc.cc_call_center_sk
  JOIN tpcds.ship_mode      sm       ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN tpcds.promotion      p        ON cs.cs_promo_sk = p.p_promo_sk
  JOIN hd_bill               ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
  JOIN hd_ship               ON cs.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
  -- Store Returns (inner join via the item dimension)
  JOIN tpcds.store_returns  sr        ON sr.sr_item_sk = i.i_item_sk
  JOIN d_sr_ret             ON sr.sr_returned_date_sk = d_sr_ret.d_date_sk
  JOIN tpcds.time_dim       t_sr_ret  ON sr.sr_return_time_sk = t_sr_ret.t_time_sk
  JOIN hd_sr                 ON sr.sr_hdemo_sk = hd_sr.hd_demo_sk
  JOIN tpcds.reason         r_sr      ON sr.sr_reason_sk = r_sr.r_reason_sk
  -- Catalog Returns (inner join via order number and item)
  JOIN tpcds.catalog_returns cr       ON cr.cr_order_number = cs.cs_order_number
                                    AND cr.cr_item_sk = i.i_item_sk
  JOIN d_cr_ret               ON cr.cr_returned_date_sk = d_cr_ret.d_date_sk
  JOIN tpcds.time_dim       t_cr_ret  ON cr.cr_returned_time_sk = t_cr_ret.t_time_sk
  JOIN hd_cr_ref              ON cr.cr_refunded_hdemo_sk = hd_cr_ref.hd_demo_sk
  JOIN hd_cr_ret              ON cr.cr_returning_hdemo_sk = hd_cr_ret.hd_demo_sk
  JOIN tpcds.reason         r_cr      ON cr.cr_reason_sk = r_cr.r_reason_sk
  -- Web Returns (inner join via the item dimension)
  JOIN tpcds.web_returns   wr        ON wr.wr_item_sk = i.i_item_sk
  JOIN d_wr_ret               ON wr.wr_returned_date_sk = d_wr_ret.d_date_sk
  JOIN tpcds.time_dim       t_wr_ret  ON wr.wr_returned_time_sk = t_wr_ret.t_time_sk
  JOIN hd_wr_ref              ON wr.wr_refunded_hdemo_sk = hd_wr_ref.hd_demo_sk
  JOIN hd_wr_ret              ON wr.wr_returning_hdemo_sk = hd_wr_ret.hd_demo_sk
  JOIN tpcds.reason         r_wr      ON wr.wr_reason_sk = r_wr.r_reason_sk
  -- Inventory (inner join via item and date)
  JOIN tpcds.inventory      inv       ON inv.inv_item_sk = i.i_item_sk
  JOIN d_inv_dt               ON inv.inv_date_sk = d_inv_dt.d_date_sk
  -- Left outer join to web_site (some sites may have no matching open‑date record)
  LEFT JOIN tpcds.web_site   ws        ON ws.web_open_date_sk = d_cs_sold.d_date_sk
GROUP BY
  cc.cc_name,
  d_cs_sold.d_year,
  d_cs_sold.d_month_seq
ORDER BY
  total_net_paid DESC
LIMIT 100
