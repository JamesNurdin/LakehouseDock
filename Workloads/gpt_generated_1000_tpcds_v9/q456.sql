WITH joined AS (
  SELECT
    cs.cs_net_paid,
    cs.cs_net_profit,
    cs.cs_ext_discount_amt,
    cs.cs_sales_price,
    i.i_category,
    i.i_class,
    i.i_brand,
    i.i_item_id,
    i.i_color,
    cp.cp_department,
    p.p_promo_name,
    p.p_discount_active,
    w.w_warehouse_name,
    d_sold.d_year,
    t_sold.t_hour,
    ca.ca_state,
    cd.cd_education_status,
    cr.cr_return_amount,
    sr.sr_return_amt,
    wr.wr_return_amt,
    inv.inv_quantity_on_hand,
    r.r_reason_desc
  FROM catalog_sales cs
  JOIN date_dim d_sold
    ON cs.cs_sold_date_sk = d_sold.d_date_sk
  JOIN time_dim t_sold
    ON cs.cs_sold_time_sk = t_sold.t_time_sk
  JOIN item i
    ON cs.cs_item_sk = i.i_item_sk
  JOIN catalog_page cp
    ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
  JOIN promotion p
    ON cs.cs_promo_sk = p.p_promo_sk
  JOIN warehouse w
    ON cs.cs_warehouse_sk = w.w_warehouse_sk
  JOIN customer c
    ON cs.cs_bill_customer_sk = c.c_customer_sk
  JOIN customer_demographics cd
    ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
  JOIN customer_address ca
    ON cs.cs_bill_addr_sk = ca.ca_address_sk
  LEFT JOIN catalog_returns cr
    ON cs.cs_order_number = cr.cr_order_number
   AND cr.cr_item_sk = i.i_item_sk
  LEFT JOIN store_returns sr
    ON i.i_item_sk = sr.sr_item_sk
  LEFT JOIN web_returns wr
    ON i.i_item_sk = wr.wr_item_sk
  LEFT JOIN inventory inv
    ON i.i_item_sk = inv.inv_item_sk
   AND cs.cs_sold_date_sk = inv.inv_date_sk
   AND w.w_warehouse_sk = inv.inv_warehouse_sk
  LEFT JOIN reason r
    ON cr.cr_reason_sk = r.r_reason_sk
  WHERE d_sold.d_year = 2001
    AND i.i_brand = 'Brand#12'
    AND p.p_discount_active = 'Y'
    AND cd.cd_education_status = 'College'
    AND ca.ca_state = 'CA'
    AND t_sold.t_hour BETWEEN 9 AND 17
),
aggregated AS (
  SELECT
    i_category,
    i_class,
    w_warehouse_name,
    d_year,
    p_promo_name,
    SUM(cs_net_paid) AS total_sales,
    SUM(cs_net_profit) AS total_profit,
    SUM(COALESCE(cr_return_amount, 0) + COALESCE(sr_return_amt, 0) + COALESCE(wr_return_amt, 0)) AS total_returns_amount,
    AVG(cs_ext_discount_amt) AS avg_discount,
    MIN(cs_sales_price) AS min_sales_price,
    MAX(cs_sales_price) AS max_sales_price,
    MAX(inv_quantity_on_hand) AS max_inventory_qty
  FROM joined
  GROUP BY
    i_category,
    i_class,
    w_warehouse_name,
    d_year,
    p_promo_name
)
SELECT
  i_category,
  i_class,
  w_warehouse_name,
  d_year,
  p_promo_name,
  total_sales,
  total_profit,
  total_returns_amount,
  avg_discount,
  min_sales_price,
  max_sales_price,
  max_inventory_qty,
  ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY total_profit DESC) AS profit_rank
FROM aggregated
ORDER BY total_profit DESC
LIMIT 100
