WITH
  agg_store_returns AS (
    SELECT
      sr_customer_sk,
      SUM(sr_net_loss) AS total_store_loss,
      COUNT(*) AS store_return_cnt
    FROM store_returns
    GROUP BY sr_customer_sk
  ),
  agg_web_sales AS (
    SELECT
      ws_bill_customer_sk,
      SUM(ws_net_profit) AS total_web_profit,
      COUNT(*) AS web_sales_cnt
    FROM web_sales
    GROUP BY ws_bill_customer_sk
  ),
  first_part AS (
    SELECT
      c.c_customer_id,
      cd.cd_gender,
      hd.hd_income_band_sk,
      cp.cp_department,
      SUM(cs.cs_ext_sales_price) AS catalog_sales_amount,
      agg_sr.total_store_loss,
      agg_ws.total_web_profit,
      COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
      MIN(cs.cs_sold_date_sk) AS first_sale_date_sk,
      MAX(cs.cs_sold_date_sk) AS last_sale_date_sk,
      lr.avg_return_amount
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    JOIN catalog_sales cs ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN agg_store_returns agg_sr ON agg_sr.sr_customer_sk = c.c_customer_sk
    JOIN agg_web_sales agg_ws ON agg_ws.ws_bill_customer_sk = c.c_customer_sk
    LEFT JOIN LATERAL (
      SELECT AVG(cr2.cr_return_amount) AS avg_return_amount
      FROM catalog_returns cr2
      WHERE cr2.cr_item_sk = cs.cs_item_sk
    ) lr ON TRUE
    WHERE cp.cp_start_date_sk BETWEEN 2451145 AND 2451271
      AND cd.cd_purchase_estimate > 5000
      AND sm.sm_type = 'AIR'
      AND cp.cp_catalog_page_id NOT IN (
        SELECT cp2.cp_catalog_page_id
        FROM catalog_page cp2
        WHERE cp2.cp_catalog_page_number = 99
      )
      AND EXISTS (
        SELECT 1
        FROM web_returns wr
        WHERE wr.wr_order_number = cs.cs_order_number
          AND wr.wr_fee > 100
      )
    GROUP BY
      c.c_customer_id,
      cd.cd_gender,
      hd.hd_income_band_sk,
      cp.cp_department,
      agg_sr.total_store_loss,
      agg_ws.total_web_profit,
      lr.avg_return_amount
  ),
  second_part AS (
    SELECT
      c.c_customer_id,
      cd.cd_gender,
      hd.hd_income_band_sk,
      we.web_name AS cp_department,
      SUM(ws.ws_ext_sales_price) AS catalog_sales_amount,
      agg_sr.total_store_loss,
      agg_ws.total_web_profit,
      COUNT(DISTINCT ws.ws_order_number) AS distinct_orders,
      MIN(ws.ws_sold_date_sk) AS first_sale_date_sk,
      MAX(ws.ws_sold_date_sk) AS last_sale_date_sk,
      CAST(NULL AS decimal(7,2)) AS avg_return_amount
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    JOIN web_sales ws ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN web_site we ON ws.ws_web_site_sk = we.web_site_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN agg_store_returns agg_sr ON agg_sr.sr_customer_sk = c.c_customer_sk
    JOIN agg_web_sales agg_ws ON agg_ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE we.web_state = 'CA'
      AND wp.wp_type = 'CONTENT'
      AND cd.cd_gender = 'M'
      AND cd.cd_purchase_estimate > 5000
    GROUP BY
      c.c_customer_id,
      cd.cd_gender,
      hd.hd_income_band_sk,
      we.web_name,
      agg_sr.total_store_loss,
      agg_ws.total_web_profit
  ),
  union_all AS (
    SELECT * FROM first_part
    UNION DISTINCT
    SELECT * FROM second_part
  ),
  final AS (
    SELECT
      c_customer_id,
      cd_gender,
      hd_income_band_sk,
      cp_department,
      SUM(catalog_sales_amount) AS total_sales_amount,
      SUM(total_store_loss) AS total_store_loss,
      SUM(total_web_profit) AS total_web_profit,
      SUM(distinct_orders) AS total_distinct_orders,
      MIN(first_sale_date_sk) AS overall_first_sale_date_sk,
      MAX(last_sale_date_sk) AS overall_last_sale_date_sk,
      AVG(avg_return_amount) AS avg_return_amount_across_union
    FROM union_all
    GROUP BY
      c_customer_id,
      cd_gender,
      hd_income_band_sk,
      cp_department
  )
SELECT *
FROM final
ORDER BY total_sales_amount DESC
LIMIT 100
