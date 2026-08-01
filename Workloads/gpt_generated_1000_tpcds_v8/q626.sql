WITH
  /* Sales part */
  sales AS (
    SELECT
      cs.cs_sold_date_sk               AS date_sk,
      cs.cs_bill_customer_sk           AS customer_sk,
      cs.cs_bill_cdemo_sk              AS cust_demo_sk,
      cs.cs_bill_hdemo_sk              AS hh_demo_sk,
      cs.cs_item_sk                    AS item_sk,
      cs.cs_quantity                   AS quantity,
      cs.cs_net_profit                 AS net_profit,
      cs.cs_promo_sk                   AS promo_sk,
      cs.cs_order_number               AS order_number,
      cs.cs_ship_mode_sk               AS ship_mode_sk,
      cs.cs_catalog_page_sk            AS catalog_page_sk,
      CAST(NULL AS INTEGER)            AS reason_sk
    FROM catalog_sales cs
    JOIN date_dim d_sold               ON cs.cs_sold_date_sk = d_sold.d_date_sk
    JOIN customer c_b                  ON cs.cs_bill_customer_sk = c_b.c_customer_sk
    JOIN customer_demographics cd_b    ON cs.cs_bill_cdemo_sk = cd_b.cd_demo_sk
    JOIN household_demographics hd_b   ON cs.cs_bill_hdemo_sk = hd_b.hd_demo_sk
    JOIN promotion p                   ON cs.cs_promo_sk = p.p_promo_sk
    JOIN ship_mode sm                 ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN catalog_page cp               ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
  ),
  /* Returns part */
  returns AS (
    SELECT
      cr.cr_returned_date_sk           AS date_sk,
      cr.cr_refunded_customer_sk       AS customer_sk,
      cr.cr_refunded_cdemo_sk          AS cust_demo_sk,
      cr.cr_refunded_hdemo_sk          AS hh_demo_sk,
      cr.cr_item_sk                    AS item_sk,
      cr.cr_return_quantity            AS quantity,
      -cr.cr_net_loss                  AS net_profit,
      CAST(NULL AS INTEGER)            AS promo_sk,
      cr.cr_order_number               AS order_number,
      cr.cr_ship_mode_sk               AS ship_mode_sk,
      cr.cr_catalog_page_sk            AS catalog_page_sk,
      cr.cr_reason_sk                  AS reason_sk
    FROM catalog_returns cr
    JOIN date_dim d_ret               ON cr.cr_returned_date_sk = d_ret.d_date_sk
    JOIN customer c_r                  ON cr.cr_refunded_customer_sk = c_r.c_customer_sk
    JOIN customer_demographics cd_r    ON cr.cr_refunded_cdemo_sk = cd_r.cd_demo_sk
    JOIN household_demographics hd_r   ON cr.cr_refunded_hdemo_sk = hd_r.hd_demo_sk
    JOIN ship_mode sm                 ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN catalog_page cp               ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    LEFT OUTER JOIN reason r          ON cr.cr_reason_sk = r.r_reason_sk
  ),
  /* Union of sales and returns */
  sales_returns AS (
    SELECT * FROM sales
    UNION ALL
    SELECT * FROM returns
  ),
  /* Web sales data – brings in web_sales, web_site and store */
  web_data AS (
    SELECT
      ws.ws_sold_date_sk               AS date_sk,
      ws.ws_bill_customer_sk           AS customer_sk,
      ws.ws_bill_cdemo_sk              AS cust_demo_sk,
      ws.ws_bill_hdemo_sk              AS hh_demo_sk,
      ws.ws_item_sk                    AS item_sk,
      ws.ws_quantity                   AS quantity,
      ws.ws_net_paid - ws.ws_net_profit AS net_profit,
      ws.ws_promo_sk                   AS promo_sk,
      ws.ws_order_number               AS order_number,
      ws.ws_ship_mode_sk               AS ship_mode_sk,
      CAST(NULL AS INTEGER)            AS catalog_page_sk,
      CAST(NULL AS INTEGER)            AS reason_sk
    FROM web_sales ws
    JOIN date_dim d_ws                ON ws.ws_sold_date_sk = d_ws.d_date_sk
    JOIN customer c_ws                ON ws.ws_bill_customer_sk = c_ws.c_customer_sk
    JOIN customer_demographics cd_ws  ON ws.ws_bill_cdemo_sk = cd_ws.cd_demo_sk
    JOIN household_demographics hd_ws ON ws.ws_bill_hdemo_sk = hd_ws.hd_demo_sk
    JOIN ship_mode sm_ws              ON ws.ws_ship_mode_sk = sm_ws.sm_ship_mode_sk
    LEFT OUTER JOIN promotion p_ws    ON ws.ws_promo_sk = p_ws.p_promo_sk
    LEFT OUTER JOIN web_site wsite    ON ws.ws_web_site_sk = wsite.web_site_sk
    LEFT OUTER JOIN store s           ON d_ws.d_date_sk = s.s_closed_date_sk
  ),
  /* Union of the two major streams */
  unified AS (
    SELECT * FROM sales_returns
    UNION DISTINCT
    SELECT * FROM web_data
  ),
  /* Enrich rows with dimensions, income band and inventory (LATERAL) */
  enriched AS (
    SELECT
      u.*,
      c.c_customer_id,
      concat(c.c_first_name, ' ', c.c_last_name) AS customer_name,
      d.d_year,
      p.p_promo_name,
      hd.hd_income_band_sk,
      ib.ib_lower_bound,
      ib.ib_upper_bound,
      inv_qty.inv_quantity_on_hand
    FROM unified u
    JOIN customer c                ON u.customer_sk = c.c_customer_sk
    JOIN date_dim d                ON u.date_sk = d.d_date_sk
    LEFT OUTER JOIN promotion p   ON u.promo_sk = p.p_promo_sk
    LEFT OUTER JOIN household_demographics hd ON u.hh_demo_sk = hd.hd_demo_sk
    LEFT OUTER JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    CROSS JOIN LATERAL (
      SELECT inv_quantity_on_hand
      FROM inventory inv
      WHERE inv.inv_date_sk = u.date_sk
        AND inv.inv_item_sk = u.item_sk
      ORDER BY inv.inv_quantity_on_hand DESC
      LIMIT 1
    ) AS inv_qty
  ),
  /* Aggregate with GROUPING SETS */
  agg AS (
    SELECT
      c_customer_id        AS customer_id,
      p_promo_name         AS promo_name,
      d_year,
      SUM(net_profit)      AS total_profit,
      SUM(quantity)        AS total_quantity,
      SUM(inv_quantity_on_hand) AS total_inventory_qty
    FROM enriched
    GROUP BY GROUPING SETS (
      (c_customer_id, d_year),
      (p_promo_name, d_year)
    )
  )
/* Final projection with a window function and pagination */
SELECT
  customer_id,
  promo_name,
  d_year,
  total_profit,
  total_quantity,
  total_inventory_qty,
  ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY total_profit DESC) AS profit_rank
FROM agg
ORDER BY total_profit DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY
