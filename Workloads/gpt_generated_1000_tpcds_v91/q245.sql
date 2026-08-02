WITH item_attrs AS (
    SELECT
        i.i_item_sk,
        i.i_item_id,
        i.i_product_name,
        i.i_brand,
        i.i_color,
        i.i_size,
        ARRAY[ i.i_brand, i.i_color, i.i_size ] AS attributes
    FROM item i
)
SELECT
    cs.cs_order_number,
    cs.cs_sold_date_sk,
    d_sales.d_date,
    d_sales.d_year,
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    cd.cd_gender,
    cd.cd_marital_status,
    i_attrs.i_item_id,
    i_attrs.i_product_name,
    p.p_promo_name,
    p.p_discount_active,
    sr.sr_return_amt,
    sr.sr_return_tax,
    r.r_reason_desc,
    inv.inv_quantity_on_hand,
    wp.wp_url,
    wp.wp_type,
    attribute,
    cs.cs_net_profit,
    RANK() OVER (PARTITION BY d_sales.d_year ORDER BY cs.cs_net_profit DESC) AS profit_rank_year,
    (
        SELECT SUM(cs_sub.cs_net_paid)
        FROM catalog_sales cs_sub
        WHERE cs_sub.cs_bill_customer_sk = c.c_customer_sk
          AND cs_sub.cs_sold_date_sk = d_sales.d_date_sk
    ) AS total_customer_paid_on_day
FROM catalog_sales cs
JOIN date_dim d_sales
  ON cs.cs_sold_date_sk = d_sales.d_date_sk
JOIN date_dim d_ship
  ON cs.cs_ship_date_sk = d_ship.d_date_sk
JOIN customer c
  ON cs.cs_bill_customer_sk = c.c_customer_sk
JOIN customer_demographics cd
  ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
JOIN item_attrs i_attrs
  ON cs.cs_item_sk = i_attrs.i_item_sk
CROSS JOIN UNNEST(i_attrs.attributes) AS t (attribute)
JOIN promotion p
  ON cs.cs_promo_sk = p.p_promo_sk
JOIN store_returns sr
  ON sr.sr_item_sk = i_attrs.i_item_sk
JOIN date_dim d_return
  ON sr.sr_returned_date_sk = d_return.d_date_sk
JOIN reason r
  ON sr.sr_reason_sk = r.r_reason_sk
JOIN inventory inv
  ON inv.inv_item_sk = i_attrs.i_item_sk
JOIN date_dim d_inv
  ON inv.inv_date_sk = d_inv.d_date_sk
JOIN web_page wp
  ON wp.wp_customer_sk = c.c_customer_sk
JOIN date_dim d_wp_create
  ON wp.wp_creation_date_sk = d_wp_create.d_date_sk
JOIN date_dim d_wp_access
  ON wp.wp_access_date_sk = d_wp_access.d_date_sk
WHERE
    cs.cs_quantity > 5
    AND cs.cs_sales_price > 20
    AND cd.cd_gender = 'M'
    AND sr.sr_return_tax > 3.00
    AND d_sales.d_date BETWEEN DATE '2001-01-01' AND DATE '2002-12-31'
    AND EXISTS (
        SELECT 1
        FROM promotion p2
        WHERE p2.p_item_sk = i_attrs.i_item_sk
          AND p2.p_discount_active = 'Y'
          AND p2.p_start_date_sk = d_sales.d_date_sk
    )
ORDER BY profit_rank_year, cs.cs_net_profit DESC
LIMIT 100
