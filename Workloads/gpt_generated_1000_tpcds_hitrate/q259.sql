WITH ss_agg AS (
    SELECT
        ss_item_sk,
        ss_store_sk,
        ss_sold_date_sk,
        SUM(ss_net_paid)        AS total_store_sales,
        SUM(ss_quantity)        AS total_store_qty
    FROM store_sales
    WHERE ss_sold_date_sk IN (
            SELECT d_date_sk
            FROM date_dim
            WHERE d_year = 2001
        )
      AND ss_quantity > 0
    GROUP BY ss_item_sk, ss_store_sk, ss_sold_date_sk
)
SELECT
    s.s_store_name,
    d.d_date,
    i.i_category,
    SUM(ssa.total_store_sales)                     AS store_sales_amount,
    SUM(cs.cs_ext_sales_price)                     AS catalog_sales_amount,
    SUM(sr.sr_return_amt)                          AS store_return_amount,
    SUM(cr.cr_return_amount)                       AS catalog_return_amount,
    AVG(inv.inv_quantity_on_hand)                  AS avg_inventory_qty,
    COUNT(DISTINCT s.s_store_id)                   AS distinct_store_cnt
FROM ss_agg ssa
JOIN store_sales ss
    ON ss.ss_item_sk = ssa.ss_item_sk
   AND ss.ss_store_sk = ssa.ss_store_sk
   AND ss.ss_sold_date_sk = ssa.ss_sold_date_sk
JOIN store s
    ON ssa.ss_store_sk = s.s_store_sk
JOIN date_dim d
    ON ssa.ss_sold_date_sk = d.d_date_sk
JOIN item i
    ON ssa.ss_item_sk = i.i_item_sk
JOIN customer_demographics cd
    ON ss.ss_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd
    ON ss.ss_hdemo_sk = hd.hd_demo_sk
JOIN promotion p
    ON ss.ss_promo_sk = p.p_promo_sk
JOIN catalog_sales cs
    ON cs.cs_item_sk = i.i_item_sk
   AND cs.cs_sold_date_sk = d.d_date_sk
JOIN catalog_returns cr
    ON cr.cr_order_number = cs.cs_order_number
   AND cr.cr_item_sk = i.i_item_sk
JOIN store_returns sr
    ON sr.sr_ticket_number = ss.ss_ticket_number
   AND sr.sr_item_sk = i.i_item_sk
JOIN inventory inv
    ON inv.inv_item_sk = i.i_item_sk
   AND inv.inv_date_sk = d.d_date_sk
JOIN call_center cc
    ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN ship_mode sm
    ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
WHERE s.s_manager = 'John Mccoy'
  AND cc.cc_class = 'large'
  AND i.i_category = 'Sports'
  AND d.d_holiday = 'N'
  AND hd.hd_vehicle_count = 1
  AND p.p_discount_active = 'Y'
GROUP BY s.s_store_name, d.d_date, i.i_category
LIMIT 100
