WITH
  sales AS (
    SELECT
      cs.cs_order_number,
      cs.cs_sold_date_sk,
      cs.cs_item_sk,
      cs.cs_quantity,
      cs.cs_net_paid,
      cs.cs_net_profit,
      d_sales.d_year,
      cc.cc_name AS call_center_name,
      p.p_promo_name,
      hd_bill.hd_income_band_sk,
      ib.ib_lower_bound,
      ib.ib_upper_bound
    FROM tpcds.catalog_sales cs
    JOIN tpcds.date_dim d_sales
      ON cs.cs_sold_date_sk = d_sales.d_date_sk
    JOIN tpcds.item i_sales
      ON cs.cs_item_sk = i_sales.i_item_sk
    JOIN tpcds.call_center cc
      ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN tpcds.promotion p
      ON cs.cs_promo_sk = p.p_promo_sk
    JOIN tpcds.customer_demographics cd_bill
      ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
    JOIN tpcds.household_demographics hd_bill
      ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
    JOIN tpcds.income_band ib
      ON hd_bill.hd_income_band_sk = ib.ib_income_band_sk
    WHERE d_sales.d_year = 2001
      AND p.p_discount_active = 'Y'
  ),
  agg AS (
    SELECT
      d_ret.d_year,
      i_sales.i_category,
      s.call_center_name,
      SUM(s.cs_net_paid) AS total_sales,
      SUM(sr.sr_return_amt) AS total_returns,
      SUM(s.cs_net_profit) - SUM(sr.sr_net_loss) AS net_profit,
      COUNT(DISTINCT s.cs_order_number) AS order_cnt,
      SUM(inv.inv_quantity_on_hand) AS total_inventory
    FROM sales s
    JOIN tpcds.store_returns sr
      ON sr.sr_item_sk = s.cs_item_sk
    JOIN tpcds.date_dim d_ret
      ON sr.sr_returned_date_sk = d_ret.d_date_sk
    JOIN tpcds.item i_sales
      ON s.cs_item_sk = i_sales.i_item_sk
    JOIN tpcds.store st
      ON sr.sr_store_sk = st.s_store_sk
    JOIN tpcds.customer_address ca_ret
      ON sr.sr_addr_sk = ca_ret.ca_address_sk
    JOIN tpcds.customer_demographics cd_ret
      ON sr.sr_cdemo_sk = cd_ret.cd_demo_sk
    JOIN tpcds.household_demographics hd_ret
      ON sr.sr_hdemo_sk = hd_ret.hd_demo_sk
    JOIN tpcds.inventory inv
      ON inv.inv_item_sk = i_sales.i_item_sk
      AND inv.inv_date_sk = d_ret.d_date_sk
    WHERE st.s_state = 'CA'
      AND ca_ret.ca_gmt_offset = -8.00
    GROUP BY
      d_ret.d_year,
      i_sales.i_category,
      s.call_center_name
  )
SELECT
  a.d_year,
  a.i_category,
  a.call_center_name,
  a.total_sales,
  a.total_returns,
  a.net_profit,
  a.order_cnt,
  a.total_inventory,
  RANK() OVER (PARTITION BY a.d_year ORDER BY a.total_sales DESC) AS sales_rank
FROM agg a
ORDER BY a.total_sales DESC
LIMIT 100
