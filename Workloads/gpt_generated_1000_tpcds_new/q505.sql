WITH base AS (
  SELECT
    cs.cs_order_number,
    cs.cs_quantity,
    cs.cs_net_paid,
    cs.cs_net_profit,
    cs.cs_ext_sales_price,
    cp.cp_department,
    cp.cp_type,
    i.i_category,
    i.i_brand,
    p.p_promo_name,
    d_sold.d_year AS sold_year,
    d_ship.d_year AS ship_year,
    cust.c_first_name,
    cust.c_last_name,
    cust.c_birth_month,
    ca.ca_state,
    cd.cd_gender,
    hd.hd_income_band_sk,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    inv.inv_quantity_on_hand,
    store.s_store_name,
    store.s_county,
    r.r_reason_desc,
    ws.web_name
  FROM catalog_sales cs
  JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
  JOIN item i ON cs.cs_item_sk = i.i_item_sk
  JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
  LEFT JOIN date_dim d_sold ON cs.cs_sold_date_sk = d_sold.d_date_sk
  LEFT JOIN date_dim d_ship ON cs.cs_ship_date_sk = d_ship.d_date_sk
  JOIN customer cust ON cs.cs_bill_customer_sk = cust.c_customer_sk
  JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
  JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
  JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
  JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
  LEFT JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk AND inv.inv_date_sk = cs.cs_sold_date_sk
  LEFT JOIN store ON store.s_closed_date_sk = cs.cs_ship_date_sk
  LEFT JOIN web_returns wr ON wr.wr_order_number = cs.cs_order_number
  LEFT JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
  LEFT JOIN web_site ws ON ws.web_open_date_sk = cs.cs_sold_date_sk
  WHERE d_sold.d_year = 1902
    AND ca.ca_state = 'CA'
    AND i.i_category = 'Women'
    AND p.p_discount_active = 'Y'
)
SELECT
  b.cs_order_number,
  b.c_first_name,
  b.c_last_name,
  b.i_category,
  b.cs_quantity,
  b.cs_net_paid,
  b.cs_net_profit,
  b.s_store_name,
  b.s_county,
  b.r_reason_desc,
  b.web_name,
  ROW_NUMBER() OVER (PARTITION BY b.c_first_name, b.c_last_name ORDER BY b.cs_net_paid DESC) AS rn_profit,
  DENSE_RANK() OVER (ORDER BY b.cs_net_profit DESC) AS dr_profit,
  qty,
  price
FROM base b
CROSS JOIN UNNEST(ARRAY[b.cs_quantity, CAST(b.cs_quantity AS double)]) AS t1(qty)
CROSS JOIN UNNEST(ARRAY[b.cs_ext_sales_price, b.cs_net_paid]) AS t2(price)
WHERE b.cs_order_number NOT IN (
        SELECT wr2.wr_order_number
        FROM web_returns wr2
        WHERE wr2.wr_return_quantity > 0
      )
  AND b.cs_order_number IN (
        SELECT cs2.cs_order_number FROM catalog_sales cs2 WHERE cs2.cs_net_paid > 1000
        INTERSECT
        SELECT cs3.cs_order_number FROM catalog_sales cs3 WHERE cs3.cs_quantity >= 5
      )
ORDER BY b.cs_net_profit DESC
LIMIT 100
