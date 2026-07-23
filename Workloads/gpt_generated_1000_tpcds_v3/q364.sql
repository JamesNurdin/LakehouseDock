WITH joined_data AS (
    SELECT
      cs.cs_order_number,
      cs.cs_sold_date_sk,
      cs.cs_net_paid,
      cs.cs_net_profit,
      cs.cs_bill_customer_sk,
      cs.cs_item_sk,
      cs.cs_promo_sk,
      cs.cs_call_center_sk,
      cs.cs_ship_mode_sk,
      cs.cs_bill_cdemo_sk,
      cr.cr_return_amount,
      cr.cr_net_loss,
      cr.cr_reason_sk,
      cr.cr_call_center_sk,
      cr.cr_ship_mode_sk,
      c.c_customer_sk,
      c.c_customer_id,
      c.c_first_name,
      c.c_last_name,
      c.c_birth_month,
      cd.cd_demo_sk,
      cd.cd_gender,
      d.d_date_sk,
      d.d_year,
      d.d_date,
      i.i_item_sk,
      i.i_category,
      i.i_current_price,
      p.p_promo_sk,
      p.p_discount_active,
      cc.cc_call_center_sk,
      sm.sm_ship_mode_sk,
      sm.sm_type,
      r.r_reason_sk,
      inv.inv_quantity_on_hand,
      wp.wp_web_page_sk,
      wp.wp_customer_sk,
      wr.wr_return_amt,
      wr.wr_reason_sk AS wr_reason_sk,
      ws.web_site_sk
    FROM catalog_sales cs
    JOIN catalog_returns cr
      ON cs.cs_order_number = cr.cr_order_number
     AND cs.cs_item_sk = cr.cr_item_sk
    JOIN customer c
      ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd
      ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN date_dim d
      ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i
      ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p
      ON cs.cs_promo_sk = p.p_promo_sk
    JOIN call_center cc
      ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN ship_mode sm
      ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN reason r
      ON cr.cr_reason_sk = r.r_reason_sk
    JOIN inventory inv
      ON inv.inv_item_sk = i.i_item_sk
     AND inv.inv_date_sk = d.d_date_sk
    JOIN web_page wp
      ON wp.wp_customer_sk = c.c_customer_sk
    JOIN web_returns wr
      ON wr.wr_item_sk = i.i_item_sk
     AND wr.wr_web_page_sk = wp.wp_web_page_sk
    JOIN reason r_wr
      ON wr.wr_reason_sk = r_wr.r_reason_sk
    JOIN web_site ws
      ON ws.web_open_date_sk = d.d_date_sk
    WHERE c.c_birth_month = 10
      AND cd.cd_gender = 'F'
      AND d.d_year BETWEEN 2001 AND 2003
      AND i.i_current_price > 100
      AND p.p_discount_active = 'Y'
      AND sm.sm_type = 'AIR'
      AND cr.cr_net_loss > 0
      AND EXISTS (
          SELECT 1 FROM promotion p2
          WHERE p2.p_item_sk = i.i_item_sk
            AND p2.p_discount_active = 'Y'
      )
),
agg_data AS (
    SELECT
      c_customer_id,
      c_first_name,
      c_last_name,
      d_year,
      i_category,
      SUM(cs_net_paid) AS total_net_paid,
      SUM(cs_net_profit) AS total_net_profit,
      SUM(cr_return_amount) AS total_return_amount,
      SUM(cr_net_loss) AS total_return_loss,
      SUM(inv_quantity_on_hand) AS total_inventory_on_hand
    FROM joined_data
    GROUP BY c_customer_id, c_first_name, c_last_name, d_year, i_category
)
SELECT
  c_customer_id,
  c_first_name,
  c_last_name,
  d_year,
  i_category,
  total_net_paid,
  total_net_profit,
  total_return_amount,
  total_return_loss,
  total_inventory_on_hand,
  RANK() OVER (PARTITION BY d_year ORDER BY total_net_profit DESC) AS profit_rank_year,
  ROW_NUMBER() OVER (PARTITION BY c_customer_id ORDER BY d_year) AS year_seq,
  (
      SELECT AVG(a2.total_net_profit)
      FROM agg_data a2
      WHERE a2.c_customer_id = agg_data.c_customer_id
        AND a2.d_year < agg_data.d_year
  ) AS avg_profit_prior_years
FROM agg_data
ORDER BY d_year, profit_rank_year
