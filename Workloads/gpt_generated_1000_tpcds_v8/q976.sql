WITH
  /* Full outer join between customers and web pages */
  customer_web AS (
    SELECT
      c.c_customer_sk,
      c.c_customer_id,
      wp.wp_web_page_sk,
      wp.wp_url
    FROM customer c
    FULL OUTER JOIN web_page wp
      ON wp.wp_customer_sk = c.c_customer_sk
  ),

  /* Base sales data sampled from catalog_sales */
  sales_base AS (
    SELECT
      cs.cs_order_number,
      cs.cs_sold_date_sk,
      cs.cs_sold_time_sk,
      cs.cs_item_sk,
      cs.cs_bill_customer_sk,
      cs.cs_ship_customer_sk,
      cs.cs_catalog_page_sk,
      cs.cs_warehouse_sk,
      cs.cs_net_paid,
      cs.cs_net_profit,
      i.i_category,
      d.d_year,
      CASE WHEN cs.cs_net_profit > 1000 THEN 'High' ELSE 'Low' END AS profit_category,
      (
        SELECT AVG(cs2.cs_net_paid)
        FROM catalog_sales cs2
        WHERE cs2.cs_item_sk = cs.cs_item_sk
      ) AS avg_item_paid,
      inv.inv_quantity_on_hand,
      ib.ib_lower_bound,
      ib.ib_upper_bound,
      cr.cr_return_quantity,
      r.r_reason_desc
    FROM catalog_sales cs
    TABLESAMPLE BERNOULLI (10)
    JOIN date_dim d               ON cs.cs_sold_date_sk   = d.d_date_sk
    JOIN time_dim t               ON cs.cs_sold_time_sk   = t.t_time_sk
    JOIN item i                   ON cs.cs_item_sk        = i.i_item_sk
    JOIN catalog_page cp          ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN warehouse w              ON cs.cs_warehouse_sk   = w.w_warehouse_sk
    LEFT JOIN inventory inv       ON inv.inv_item_sk   = cs.cs_item_sk
                               AND inv.inv_date_sk   = cs.cs_sold_date_sk
                               AND inv.inv_warehouse_sk = cs.cs_warehouse_sk
    LEFT JOIN household_demographics hd_bill ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
    LEFT JOIN income_band ib                 ON hd_bill.hd_income_band_sk = ib.ib_income_band_sk
    LEFT JOIN customer cust_bill            ON cs.cs_bill_customer_sk = cust_bill.c_customer_sk
    LEFT JOIN customer_demographics cd_bill ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
    LEFT JOIN household_demographics hd_ship ON cs.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
    LEFT JOIN customer cust_ship            ON cs.cs_ship_customer_sk = cust_ship.c_customer_sk
    LEFT JOIN customer_demographics cd_ship ON cs.cs_ship_cdemo_sk = cd_ship.cd_demo_sk
    LEFT JOIN catalog_returns cr            ON cr.cr_order_number = cs.cs_order_number
    LEFT JOIN reason r                      ON cr.cr_reason_sk = r.r_reason_sk
    WHERE NOT EXISTS (
          SELECT 1 FROM catalog_returns cr2
          WHERE cr2.cr_order_number = cs.cs_order_number
        )
  ),

  /* Store sales joined to its dimensions */
  store_join AS (
    SELECT
      ss.ss_ticket_number,
      ss.ss_sold_date_sk,
      ss.ss_item_sk,
      ss.ss_store_sk,
      ss.ss_net_paid AS store_net_paid,
      s.s_store_name,
      d2.d_year AS store_year
    FROM store_sales ss
    JOIN date_dim d2   ON ss.ss_sold_date_sk = d2.d_date_sk
    JOIN store s       ON ss.ss_store_sk    = s.s_store_sk
    JOIN item i2       ON ss.ss_item_sk    = i2.i_item_sk
  ),

  /* Aggregate the sales data */
  agg_sales AS (
    SELECT
      sb.i_category,
      sb.d_year,
      sb.profit_category,
      sb.r_reason_desc,
      cw.c_customer_id,
      cw.wp_url,
      COUNT(DISTINCT sb.cs_order_number)                     AS orders,
      SUM(sb.cs_net_paid)                                   AS total_net_paid,
      AVG(sb.avg_item_paid)                                 AS avg_item_paid,
      SUM(sb.inv_quantity_on_hand)                          AS total_qty_on_hand,
      COALESCE(SUM(sb.cr_return_quantity),0)                AS total_return_qty
    FROM sales_base sb
    LEFT JOIN customer_web cw
      ON cw.c_customer_sk = sb.cs_bill_customer_sk
    LEFT JOIN store_join sj
      ON sj.ss_ticket_number = sb.cs_order_number
    GROUP BY
      sb.i_category,
      sb.d_year,
      sb.profit_category,
      sb.r_reason_desc,
      cw.c_customer_id,
      cw.wp_url
  )

SELECT
  a.i_category,
  a.d_year,
  a.profit_category,
  a.r_reason_desc,
  a.c_customer_id,
  a.wp_url,
  a.orders,
  a.total_net_paid,
  a.avg_item_paid,
  a.total_qty_on_hand,
  a.total_return_qty,
  /* Running total of net paid per category ordered by year */
  SUM(a.total_net_paid) OVER (
    PARTITION BY a.i_category
    ORDER BY a.d_year
    ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
  ) AS running_total_net_paid,
  /* Previous year's net paid for the same category */
  LAG(a.total_net_paid) OVER (
    PARTITION BY a.i_category
    ORDER BY a.d_year
  ) AS prev_year_net_paid
FROM agg_sales a
ORDER BY a.i_category, a.d_year DESC
LIMIT 100
