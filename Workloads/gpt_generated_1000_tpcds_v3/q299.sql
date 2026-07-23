WITH base AS (
  SELECT
    cs.cs_order_number,
    cs.cs_ext_sales_price,
    cs.cs_ext_discount_amt,
    cs.cs_ext_tax,
    cs.cs_net_paid,
    cs.cs_net_profit,
    cs.cs_quantity,
    cs.cs_sold_date_sk,
    cs.cs_ship_date_sk,
    cs.cs_item_sk,
    cs.cs_ship_mode_sk,
    cs.cs_warehouse_sk,
    cs.cs_bill_customer_sk,
    cs.cs_ship_customer_sk,
    cs.cs_bill_addr_sk,
    cs.cs_ship_addr_sk,
    cs.cs_bill_cdemo_sk,
    cs.cs_ship_cdemo_sk,
    cs.cs_bill_hdemo_sk,
    cs.cs_ship_hdemo_sk,
    d_sold.d_year,
    d_sold.d_month_seq,
    d_sold.d_day_name,
    d_sold.d_weekend,
    t_sold.t_hour,
    t_sold.t_minute,
    it.i_item_id,
    it.i_current_price,
    it.i_wholesale_cost,
    it.i_brand,
    it.i_category,
    it.i_manufact_id,
    it.i_manager_id,
    sm.sm_carrier,
    w.w_state,
    c_bill.c_first_name,
    c_bill.c_last_name,
    cd_bill.cd_gender,
    hd_bill.hd_income_band_sk,
    ca_bill.ca_state,
    s.s_store_name,
    sr.sr_return_quantity,
    sr.sr_return_amt,
    r.r_reason_desc,
    i.inv_quantity_on_hand,
    wbs.web_mkt_class
  FROM catalog_sales cs
  JOIN date_dim d_sold ON cs.cs_sold_date_sk = d_sold.d_date_sk
  JOIN time_dim t_sold ON cs.cs_sold_time_sk = t_sold.t_time_sk
  JOIN date_dim d_ship ON cs.cs_ship_date_sk = d_ship.d_date_sk
  JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
  JOIN item it ON cs.cs_item_sk = it.i_item_sk
  JOIN customer c_bill ON cs.cs_bill_customer_sk = c_bill.c_customer_sk
  JOIN customer_address ca_bill ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
  JOIN customer_demographics cd_bill ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
  JOIN household_demographics hd_bill ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
  JOIN customer c_ship ON cs.cs_ship_customer_sk = c_ship.c_customer_sk
  JOIN customer_address ca_ship ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
  JOIN customer_demographics cd_ship ON cs.cs_ship_cdemo_sk = cd_ship.cd_demo_sk
  JOIN household_demographics hd_ship ON cs.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
  -- store_sales
  JOIN store_sales ss ON ss.ss_item_sk = cs.cs_item_sk
                     AND ss.ss_sold_date_sk = d_sold.d_date_sk
                     AND ss.ss_sold_time_sk = t_sold.t_time_sk
                     AND ss.ss_customer_sk = c_bill.c_customer_sk
                     AND ss.ss_cdemo_sk = cd_bill.cd_demo_sk
                     AND ss.ss_hdemo_sk = hd_bill.hd_demo_sk
                     AND ss.ss_addr_sk = ca_bill.ca_address_sk
  JOIN store s ON ss.ss_store_sk = s.s_store_sk
  LEFT JOIN date_dim d_store_close ON s.s_closed_date_sk = d_store_close.d_date_sk
  -- store_returns
  LEFT JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
                             AND sr.sr_item_sk = cs.cs_item_sk
                             AND sr.sr_customer_sk = c_bill.c_customer_sk
                             AND sr.sr_cdemo_sk = cd_bill.cd_demo_sk
                             AND sr.sr_hdemo_sk = hd_bill.hd_demo_sk
                             AND sr.sr_addr_sk = ca_bill.ca_address_sk
                             AND sr.sr_store_sk = s.s_store_sk
  LEFT JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
  LEFT JOIN date_dim d_sr ON sr.sr_returned_date_sk = d_sr.d_date_sk
  LEFT JOIN time_dim t_sr ON sr.sr_return_time_sk = t_sr.t_time_sk
  -- inventory
  LEFT JOIN inventory i ON i.inv_item_sk = cs.cs_item_sk
                        AND i.inv_warehouse_sk = w.w_warehouse_sk
                        AND i.inv_date_sk = d_sold.d_date_sk
  LEFT JOIN date_dim d_inv ON i.inv_date_sk = d_inv.d_date_sk
  -- web_site
  LEFT JOIN web_site wbs ON wbs.web_open_date_sk = d_sold.d_date_sk
  LEFT JOIN date_dim d_web_open ON wbs.web_open_date_sk = d_web_open.d_date_sk
  LEFT JOIN date_dim d_web_close ON wbs.web_close_date_sk = d_web_close.d_date_sk
  WHERE
    d_sold.d_year = 2001
    AND d_sold.d_weekend = 'N'
    AND it.i_wholesale_cost > 10.00
    AND w.w_state = 'CA'
    AND sm.sm_carrier = 'UPS'
    AND wbs.web_mkt_class LIKE '%services%'
),
agg_item AS (
  SELECT
    i_item_id,
    d_year,
    SUM(cs_ext_sales_price) AS total_sales,
    SUM(cs_ext_discount_amt) AS total_discount,
    SUM(COALESCE(sr_return_amt, 0)) AS total_returns,
    COUNT(DISTINCT cs_order_number) AS order_cnt,
    AVG(cs_net_profit) AS avg_profit
  FROM base
  GROUP BY i_item_id, d_year
),
final AS (
  SELECT
    i_item_id,
    d_year,
    total_sales,
    total_discount,
    total_returns,
    order_cnt,
    avg_profit,
    RANK() OVER (PARTITION BY d_year ORDER BY total_sales DESC) AS sales_rank,
    (SELECT AVG(total_sales) FROM agg_item) AS overall_avg_sales
  FROM agg_item
  WHERE total_sales > (SELECT AVG(total_sales) FROM agg_item)
    AND total_returns < total_sales * 0.2
    AND avg_profit > 0
    AND order_cnt >= 10
    AND total_discount / NULLIF(total_sales, 0) < 0.05
)
SELECT
  i_item_id,
  d_year,
  total_sales,
  total_discount,
  total_returns,
  order_cnt,
  avg_profit,
  sales_rank,
  overall_avg_sales
FROM final
WHERE sales_rank <= 10
ORDER BY d_year, sales_rank
LIMIT 100
