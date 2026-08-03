WITH
  sales_agg AS (
    SELECT
      cs.cs_item_sk,
      cs.cs_sold_date_sk,
      cs.cs_bill_customer_sk,
      cs.cs_bill_addr_sk,
      cs.cs_bill_cdemo_sk,
      cs.cs_bill_hdemo_sk,
      cs.cs_call_center_sk,
      cs.cs_catalog_page_sk,
      cs.cs_ship_mode_sk,
      cs.cs_warehouse_sk,
      cs.cs_promo_sk,
      SUM(cs.cs_net_paid)        AS total_sales,
      SUM(cs.cs_quantity)        AS total_quantity,
      SUM(cs.cs_net_profit)      AS total_profit
    FROM catalog_sales cs
    WHERE cs.cs_sold_date_sk IN (
            SELECT d_date_sk FROM date_dim WHERE d_year = 2001
          )
      AND cs.cs_item_sk IN (
            SELECT i_item_sk FROM item WHERE i_category = 'Sports'
          )
      AND cs.cs_ship_mode_sk IN (
            SELECT sm_ship_mode_sk FROM ship_mode WHERE sm_type = 'EXPRESS'
          )
      AND cs.cs_promo_sk IN (
            SELECT p_promo_sk FROM promotion WHERE p_discount_active = 'Y'
          )
      AND cs.cs_call_center_sk IN (
            SELECT cc_call_center_sk FROM call_center WHERE cc_state = 'CA'
          )
    GROUP BY
      cs.cs_item_sk,
      cs.cs_sold_date_sk,
      cs.cs_bill_customer_sk,
      cs.cs_bill_addr_sk,
      cs.cs_bill_cdemo_sk,
      cs.cs_bill_hdemo_sk,
      cs.cs_call_center_sk,
      cs.cs_catalog_page_sk,
      cs.cs_ship_mode_sk,
      cs.cs_warehouse_sk,
      cs.cs_promo_sk
  ),
  returns_agg AS (
    SELECT
      cr.cr_item_sk,
      cr.cr_returned_date_sk,
      SUM(cr.cr_return_amount) AS total_return_amount,
      SUM(cr.cr_return_quantity) AS total_return_qty,
      cr.cr_reason_sk,
      cr.cr_ship_mode_sk,
      cr.cr_warehouse_sk,
      cr.cr_call_center_sk,
      cr.cr_catalog_page_sk
    FROM catalog_returns cr
    WHERE cr.cr_returned_date_sk IN (
            SELECT d_date_sk FROM date_dim WHERE d_year = 2001
          )
      AND cr.cr_item_sk IN (
            SELECT i_item_sk FROM item WHERE i_category = 'Sports'
          )
      AND cr.cr_ship_mode_sk IN (
            SELECT sm_ship_mode_sk FROM ship_mode WHERE sm_type = 'EXPRESS'
          )
    GROUP BY
      cr.cr_item_sk,
      cr.cr_returned_date_sk,
      cr.cr_reason_sk,
      cr.cr_ship_mode_sk,
      cr.cr_warehouse_sk,
      cr.cr_call_center_sk,
      cr.cr_catalog_page_sk
  ),
  combined AS (
    SELECT
      s.cs_sold_date_sk        AS date_sk,
      s.cs_item_sk             AS item_sk,
      s.total_sales,
      s.total_quantity,
      s.total_profit,
      s.cs_call_center_sk,
      s.cs_catalog_page_sk,
      s.cs_ship_mode_sk,
      s.cs_warehouse_sk,
      s.cs_promo_sk,
      s.cs_bill_customer_sk,
      s.cs_bill_addr_sk,
      s.cs_bill_cdemo_sk,
      s.cs_bill_hdemo_sk,
      r.total_return_amount,
      r.total_return_qty,
      r.cr_reason_sk,
      r.cr_ship_mode_sk        AS return_ship_mode_sk,
      r.cr_warehouse_sk        AS return_warehouse_sk,
      r.cr_call_center_sk      AS return_call_center_sk,
      r.cr_catalog_page_sk     AS return_catalog_page_sk
    FROM sales_agg s
    LEFT JOIN returns_agg r
      ON s.cs_item_sk = r.cr_item_sk
     AND s.cs_sold_date_sk = r.cr_returned_date_sk
  ),
  first_set AS (
    SELECT
      d.d_date                                         AS sale_date,
      i.i_item_id,
      i.i_product_name,
      cc.cc_name                                        AS call_center,
      cp.cp_department,
      sm.sm_type                                        AS ship_mode_type,
      w.w_warehouse_name,
      p.p_promo_name,
      st.s_store_name                                   AS store_name,
      ws.web_name,
      c.c_first_name                                   AS customer_first_name,
      ca.ca_city,
      cd.cd_gender,
      hd.hd_income_band_sk,
      ca_total.total_sales,
      ca_total.total_quantity,
      ca_total.total_return_amount,
      ca_total.total_return_qty,
      CASE
        WHEN ca_total.total_profit > 10000 THEN 'HIGH'
        WHEN ca_total.total_profit BETWEEN 5000 AND 10000 THEN 'MEDIUM'
        ELSE 'LOW'
      END                                            AS profit_category,
      RANK() OVER (PARTITION BY d.d_year ORDER BY ca_total.total_sales DESC) AS sales_rank_year
    FROM combined ca_total
    JOIN date_dim d               ON ca_total.date_sk = d.d_date_sk
    JOIN item i                   ON ca_total.item_sk = i.i_item_sk
    JOIN call_center cc           ON ca_total.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp          ON ca_total.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm             ON ca_total.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w              ON ca_total.cs_warehouse_sk = w.w_warehouse_sk
    JOIN promotion p              ON ca_total.cs_promo_sk = p.p_promo_sk
    JOIN store st                 ON d.d_date_sk = st.s_closed_date_sk
    JOIN web_site ws              ON d.d_date_sk = ws.web_open_date_sk
    JOIN customer c               ON ca_total.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca      ON ca_total.cs_bill_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON ca_total.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON ca_total.cs_bill_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN reason r            ON ca_total.cr_reason_sk = r.r_reason_sk
    WHERE i.i_brand = 'Brand#12'
      AND cc.cc_gmt_offset BETWEEN -5.00 AND 0.00
      AND w.w_city = 'Seattle'
      AND p.p_discount_active = 'Y'
      AND st.s_state = 'CA'
  ),
  second_set AS (
    SELECT
      d.d_date                                         AS sale_date,
      i.i_item_id,
      i.i_product_name,
      cc.cc_name                                        AS call_center,
      cp.cp_department,
      sm.sm_type                                        AS ship_mode_type,
      w.w_warehouse_name,
      p.p_promo_name,
      st.s_store_name                                   AS store_name,
      ws.web_name,
      c.c_first_name                                   AS customer_first_name,
      ca.ca_city,
      cd.cd_gender,
      hd.hd_income_band_sk,
      s.total_sales,
      s.total_quantity,
      CAST(NULL AS decimal(7,2))                       AS total_return_amount,
      CAST(NULL AS integer)                            AS total_return_qty,
      CASE
        WHEN s.total_profit > 10000 THEN 'HIGH'
        WHEN s.total_profit BETWEEN 5000 AND 10000 THEN 'MEDIUM'
        ELSE 'LOW'
      END                                            AS profit_category,
      RANK() OVER (PARTITION BY d.d_year ORDER BY s.total_sales DESC) AS sales_rank_year
    FROM sales_agg s
    JOIN date_dim d               ON s.cs_sold_date_sk = d.d_date_sk
    JOIN item i                   ON s.cs_item_sk = i.i_item_sk
    JOIN call_center cc           ON s.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp          ON s.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm             ON s.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w              ON s.cs_warehouse_sk = w.w_warehouse_sk
    JOIN promotion p              ON s.cs_promo_sk = p.p_promo_sk
    JOIN store st                 ON d.d_date_sk = st.s_closed_date_sk
    JOIN web_site ws              ON d.d_date_sk = ws.web_open_date_sk
    JOIN customer c               ON s.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca      ON s.cs_bill_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON s.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON s.cs_bill_hdemo_sk = hd.hd_demo_sk
    WHERE i.i_brand = 'Brand#12'
      AND cc.cc_gmt_offset BETWEEN -5.00 AND 0.00
      AND w.w_city = 'Seattle'
      AND p.p_discount_active = 'Y'
      AND st.s_state = 'CA'
  )
SELECT DISTINCT *
FROM (
  SELECT * FROM first_set
  UNION DISTINCT
  SELECT * FROM second_set
) final_result
ORDER BY sales_rank_year, sale_date
LIMIT 100
