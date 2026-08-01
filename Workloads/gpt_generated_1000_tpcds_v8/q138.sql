WITH sales_base AS (
   SELECT
       ss.ss_sold_date_sk,
       ss.ss_sold_time_sk,
       ss.ss_item_sk,
       ss.ss_customer_sk,
       ss.ss_cdemo_sk,
       ss.ss_hdemo_sk,
       ss.ss_addr_sk,
       ss.ss_store_sk,
       ss.ss_promo_sk,
       ss.ss_quantity,
       ss.ss_sales_price,
       ss.ss_ext_discount_amt,
       ss.ss_net_paid_inc_tax
   FROM store_sales ss
   WHERE ss.ss_quantity > 1
     AND ss.ss_net_paid_inc_tax > 1000
)
SELECT
    DISTINCT s.s_store_name,
    i.i_item_id,
    i.i_brand,
    d_sales.d_date,
    ssb.ss_quantity,
    ssb.ss_sales_price,
    CASE WHEN ssb.ss_ext_discount_amt > 500 THEN 'High' ELSE 'Low' END AS discount_level,
    RANK() OVER (PARTITION BY s.s_store_id ORDER BY ssb.ss_net_paid_inc_tax DESC) AS store_sales_rank,
    inv_l.total_on_hand,
    (SELECT avg(ss2.ss_sales_price)
       FROM store_sales ss2
       WHERE ss2.ss_item_sk = i.i_item_sk) AS avg_item_price,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    cd.cd_credit_rating,
    cc.cc_name,
    cp.cp_catalog_number
FROM sales_base ssb
JOIN date_dim d_sales
  ON ssb.ss_sold_date_sk = d_sales.d_date_sk
JOIN time_dim t_sales
  ON ssb.ss_sold_time_sk = t_sales.t_time_sk
JOIN item i
  ON ssb.ss_item_sk = i.i_item_sk
JOIN customer c
  ON ssb.ss_customer_sk = c.c_customer_sk
JOIN customer_address ca
  ON ssb.ss_addr_sk = ca.ca_address_sk
JOIN customer_demographics cd
  ON ssb.ss_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd
  ON ssb.ss_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib
  ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN promotion p
  ON ssb.ss_promo_sk = p.p_promo_sk
JOIN store s
  ON ssb.ss_store_sk = s.s_store_sk
JOIN call_center cc
  ON cc.cc_closed_date_sk = d_sales.d_date_sk
JOIN catalog_page cp
  ON cp.cp_end_date_sk = d_sales.d_date_sk
CROSS JOIN LATERAL (
    SELECT sum(inv_quantity_on_hand) AS total_on_hand
    FROM inventory inv
    WHERE inv.inv_date_sk = d_sales.d_date_sk
      AND inv.inv_item_sk = i.i_item_sk
) inv_l
WHERE ib.ib_upper_bound <= 150000
  AND hd.hd_vehicle_count >= 1
  AND i.i_brand = 'Brand#45'
  AND s.s_state = 'CA'
  AND EXISTS (
        SELECT 1
        FROM web_sales ws
        WHERE ws.ws_item_sk = ssb.ss_item_sk
          AND ws.ws_sold_date_sk = ssb.ss_sold_date_sk
          AND ws.ws_net_paid_inc_tax > 2000
      )
ORDER BY s.s_store_name, store_sales_rank
LIMIT 100
