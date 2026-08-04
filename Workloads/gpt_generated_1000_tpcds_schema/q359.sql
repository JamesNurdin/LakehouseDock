WITH
  sales_base AS (
    SELECT
      cs.cs_order_number,
      cs.cs_net_paid,
      cs.cs_sold_time_sk,
      cc.cc_name,
      sm.sm_type,
      w.w_warehouse_name,
      i.i_item_sk,
      i.i_category,
      p.p_promo_id,
      c.c_customer_id,
      cd.cd_marital_status,
      hd.hd_income_band_sk,
      ib.ib_lower_bound,
      ib.ib_upper_bound,
      ca.ca_location_type,
      sr.sr_return_amt_inc_tax,
      sr.sr_store_sk,
      r.r_reason_desc,
      cr.cr_return_amount
    FROM catalog_sales cs
    JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    LEFT JOIN catalog_returns cr ON cr.cr_item_sk = i.i_item_sk
                              AND cr.cr_order_number = cs.cs_order_number
    LEFT JOIN store_returns sr ON sr.sr_item_sk = i.i_item_sk
    LEFT JOIN store s ON sr.sr_store_sk = s.s_store_sk
    LEFT JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    WHERE c.c_birth_country = 'SWITZERLAND'
      AND cd.cd_marital_status = 'S'
      AND s.s_number_employees >= 260
      AND ib.ib_upper_bound <= 80000
      AND td.t_hour BETWEEN 9 AND 12
  ),
  orders_without_returns AS (
    SELECT cs_order_number FROM catalog_sales
    EXCEPT
    SELECT cr_order_number FROM catalog_returns
  ),
  filtered_sales AS (
    SELECT sb.*
    FROM sales_base sb
    JOIN orders_without_returns owr ON sb.cs_order_number = owr.cs_order_number
  ),
  ranked AS (
    SELECT
      s.s_store_name,
      i.i_category,
      SUM(fs.cs_net_paid) AS total_sales,
      SUM(COALESCE(fs.sr_return_amt_inc_tax, 0)) AS total_return_amount,
      SUM(COALESCE(fs.cr_return_amount, 0)) AS total_catalog_return_amount,
      COUNT(DISTINCT fs.c_customer_id) AS unique_customers,
      ROW_NUMBER() OVER (PARTITION BY s.s_store_name ORDER BY SUM(fs.cs_net_paid) DESC) AS rn
    FROM filtered_sales fs
    JOIN store s ON fs.sr_store_sk = s.s_store_sk
    JOIN item i ON fs.i_item_sk = i.i_item_sk
    GROUP BY s.s_store_name, i.i_category
    HAVING SUM(fs.cs_net_paid) > 1000
  )
SELECT *
FROM ranked
WHERE rn <= 3
ORDER BY total_sales DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY
