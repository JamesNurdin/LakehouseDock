WITH
  -- Base fact from store_sales with related dimensions and a left join to store_returns
  store_sales_cte AS (
    SELECT
      ss.ss_ticket_number                                 AS order_number,
      d.d_year                                           AS d_year,
      c.c_customer_id                                   AS c_customer_id,
      cd.cd_gender                                      AS cd_gender,
      hd.hd_buy_potential                               AS hd_buy_potential,
      ib.ib_lower_bound                                 AS ib_lower_bound,
      ib.ib_upper_bound                                 AS ib_upper_bound,
      p.p_promo_name                                    AS p_promo_name,
      CAST(NULL AS varchar)                             AS ship_mode_type,
      CAST(NULL AS varchar)                             AS warehouse_name,
      CAST(NULL AS varchar)                             AS web_site_name,
      ss.ss_net_profit                                  AS net_profit,
      ss.ss_quantity                                    AS sale_qty,
      sr.sr_return_quantity                             AS return_qty,
      CAST(NULL AS integer)                             AS inventory_qty
    FROM store_sales ss
    JOIN date_dim d                     ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN customer c                     ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd       ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd      ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN promotion p                    ON ss.ss_promo_sk = p.p_promo_sk
    JOIN income_band ib                 ON hd.hd_income_band_sk = ib.ib_income_band_sk
    LEFT JOIN store_returns sr         ON sr.sr_ticket_number = ss.ss_ticket_number
                                         AND sr.sr_item_sk = ss.ss_item_sk
  ),

  -- Base fact from web_sales with all possible dimension joins, plus inventory via warehouse+date
  web_sales_cte AS (
    SELECT
      ws.ws_order_number                                 AS order_number,
      d_sold.d_year                                      AS d_year,
      c.c_customer_id                                   AS c_customer_id,
      cd.cd_gender                                      AS cd_gender,
      hd.hd_buy_potential                               AS hd_buy_potential,
      ib.ib_lower_bound                                 AS ib_lower_bound,
      ib.ib_upper_bound                                 AS ib_upper_bound,
      p.p_promo_name                                    AS p_promo_name,
      sm.sm_type                                        AS ship_mode_type,
      w.w_warehouse_name                                AS warehouse_name,
      wsit.web_name                                      AS web_site_name,
      ws.ws_net_profit                                  AS net_profit,
      ws.ws_quantity                                    AS sale_qty,
      CAST(NULL AS integer)                             AS return_qty,
      inv.inv_quantity_on_hand                          AS inventory_qty
    FROM web_sales ws
    JOIN date_dim d_sold                 ON ws.ws_sold_date_sk = d_sold.d_date_sk
    JOIN customer c                      ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd        ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd       ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN promotion p                     ON ws.ws_promo_sk = p.p_promo_sk
    JOIN ship_mode sm                    ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w                     ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN web_site wsit                   ON ws.ws_web_site_sk = wsit.web_site_sk
    JOIN income_band ib                 ON hd.hd_income_band_sk = ib.ib_income_band_sk
    LEFT JOIN inventory inv             ON inv.inv_warehouse_sk = w.w_warehouse_sk
                                         AND inv.inv_date_sk = d_sold.d_date_sk
  ),

  -- Union of the two fact branches (distinct rows)
  combined_cte AS (
    SELECT * FROM store_sales_cte
    UNION DISTINCT
    SELECT * FROM web_sales_cte
  ),

  -- Keep only order numbers that are NOT present in catalog_returns (EXCEPT operation)
  filtered_orders AS (
    SELECT order_number FROM combined_cte
    EXCEPT
    SELECT cr_order_number FROM catalog_returns
  )

SELECT
  cte.d_year,
  cte.c_customer_id,
  cte.cd_gender,
  cte.hd_buy_potential,
  cte.ib_lower_bound,
  cte.ib_upper_bound,
  cte.p_promo_name,
  cte.ship_mode_type,
  cte.warehouse_name,
  cte.web_site_name,
  cte.net_profit,
  cte.sale_qty,
  cte.return_qty,
  cte.inventory_qty,
  ROW_NUMBER() OVER (PARTITION BY cte.c_customer_id ORDER BY cte.net_profit DESC) AS rn,
  profit_val,
  (SELECT avg(net_profit) FROM combined_cte) AS avg_net_profit
FROM (
  SELECT *
  FROM combined_cte
  WHERE order_number IN (SELECT order_number FROM filtered_orders)
) cte
CROSS JOIN LATERAL (
  SELECT ARRAY[cte.net_profit] AS profit_arr
) AS l
CROSS JOIN UNNEST(l.profit_arr) AS u(profit_val)
ORDER BY cte.net_profit DESC
OFFSET 0 ROWS
LIMIT 100
