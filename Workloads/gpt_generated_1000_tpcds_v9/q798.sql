WITH sales_base AS (
  SELECT
    s.s_store_sk,
    s.s_store_name,
    s.s_state,
    cp.cp_department,
    d_sold.d_year,
    d_sold.d_month_seq,
    ss.ss_net_profit AS store_net_profit,
    cs.cs_net_profit AS catalog_net_profit,
    cr.cr_net_loss AS return_loss,
    inv.inv_quantity_on_hand,
    p.p_discount_active,
    r.r_reason_desc,
    wp.wp_type,
    cs.cs_item_sk,
    cs.cs_sales_price,
    (
      SELECT MAX(cs2.cs_sales_price)
      FROM catalog_sales cs2
      WHERE cs2.cs_item_sk = cs.cs_item_sk
        AND cs2.cs_sold_date_sk = d_sold.d_date_sk
    ) AS max_item_sales_price,
    inv_l.total_inventory_30d
  FROM store s
  JOIN store_sales ss
    ON ss.ss_store_sk = s.s_store_sk
  JOIN date_dim d_sold
    ON ss.ss_sold_date_sk = d_sold.d_date_sk
  JOIN customer c
    ON ss.ss_customer_sk = c.c_customer_sk
  JOIN customer_demographics cd
    ON ss.ss_cdemo_sk = cd.cd_demo_sk
  JOIN customer_address ca
    ON ss.ss_addr_sk = ca.ca_address_sk
  JOIN promotion p
    ON ss.ss_promo_sk = p.p_promo_sk
  JOIN catalog_sales cs
    ON cs.cs_sold_date_sk = d_sold.d_date_sk
       AND cs.cs_bill_customer_sk = c.c_customer_sk
       AND cs.cs_bill_cdemo_sk = cd.cd_demo_sk
       AND cs.cs_bill_addr_sk = ca.ca_address_sk
  JOIN catalog_page cp
    ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
  LEFT JOIN catalog_returns cr
    ON cr.cr_order_number = cs.cs_order_number
       AND cr.cr_item_sk = cs.cs_item_sk
       AND cr.cr_returned_date_sk = d_sold.d_date_sk
  LEFT JOIN reason r
    ON cr.cr_reason_sk = r.r_reason_sk
  LEFT JOIN inventory inv
    ON inv.inv_date_sk = d_sold.d_date_sk
  LEFT JOIN web_page wp
    ON wp.wp_customer_sk = c.c_customer_sk
       AND wp.wp_creation_date_sk = d_sold.d_date_sk
  CROSS JOIN LATERAL (
    SELECT SUM(inv2.inv_quantity_on_hand) AS total_inventory_30d
    FROM inventory inv2
    WHERE inv2.inv_date_sk = d_sold.d_date_sk - 30
  ) AS inv_l
  LEFT JOIN date_dim d_cp_start
    ON cp.cp_start_date_sk = d_cp_start.d_date_sk
  LEFT JOIN date_dim d_cp_end
    ON cp.cp_end_date_sk = d_cp_end.d_date_sk
  LEFT JOIN date_dim d_store_closed
    ON s.s_closed_date_sk = d_store_closed.d_date_sk
  LEFT JOIN date_dim d_promo_start
    ON p.p_start_date_sk = d_promo_start.d_date_sk
  LEFT JOIN date_dim d_promo_end
    ON p.p_end_date_sk = d_promo_end.d_date_sk
  LEFT JOIN date_dim d_web_access
    ON wp.wp_access_date_sk = d_web_access.d_date_sk
  WHERE d_sold.d_year = 2020
    AND cp.cp_department = 'Books'
    AND p.p_discount_active = 'Y'
    AND s.s_state = 'CA'
    AND cs.cs_quantity > 5
    AND inv.inv_quantity_on_hand > 0
),
aggregated AS (
  SELECT
    s_store_name,
    cp_department,
    d_year,
    d_month_seq,
    SUM(store_net_profit) AS total_store_profit,
    SUM(catalog_net_profit) AS total_catalog_profit,
    SUM(return_loss) AS total_return_loss,
    SUM(inv_quantity_on_hand) AS total_inventory,
    SUM(total_inventory_30d) AS total_inventory_last_month,
    MAX(max_item_sales_price) AS max_price_per_item
  FROM sales_base
  GROUP BY s_store_name, cp_department, d_year, d_month_seq
)
SELECT
  s_store_name,
  cp_department,
  d_year,
  d_month_seq,
  total_store_profit,
  total_catalog_profit,
  total_return_loss,
  total_inventory,
  total_inventory_last_month,
  max_price_per_item,
  RANK() OVER (PARTITION BY cp_department ORDER BY (total_store_profit + total_catalog_profit - total_return_loss) DESC) AS dept_store_rank,
  SUM(total_store_profit + total_catalog_profit - total_return_loss) OVER (PARTITION BY cp_department ORDER BY d_month_seq ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS three_month_moving_profit
FROM aggregated
ORDER BY cp_department, dept_store_rank
