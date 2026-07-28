/*
Goal: Analyze catalog sales combined with returns and inventory for the year 2001, focusing on specific manufacturers, warehouses in CA, a particular call center, and air shipping. The query aggregates sales, profit, returns and inventory per product category and manufacturer, then ranks categories by total sales.
*/
WITH sales_agg AS (
    SELECT
        d_sold.d_year,
        i.i_category,
        i.i_manufact_id,
        w.w_warehouse_name,
        cc.cc_name,
        sm.sm_type,
        s.s_store_name,
        SUM(cs.cs_ext_sales_price)                     AS total_sales,
        SUM(cs.cs_net_profit)                         AS total_profit,
        SUM(COALESCE(sr.sr_return_amt, 0))            AS total_returns,
        SUM(COALESCE(inv.inv_quantity_on_hand, 0))    AS total_inventory,
        COUNT(DISTINCT cs.cs_order_number)            AS order_cnt
    FROM catalog_sales cs
    JOIN date_dim d_sold
      ON cs.cs_sold_date_sk = d_sold.d_date_sk
    JOIN time_dim t_sold
      ON cs.cs_sold_time_sk = t_sold.t_time_sk
    JOIN call_center cc
      ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN ship_mode sm
      ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w
      ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN item i
      ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p
      ON cs.cs_promo_sk = p.p_promo_sk
    JOIN customer c
      ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd
      ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca
      ON cs.cs_bill_addr_sk = ca.ca_address_sk
    LEFT JOIN store_returns sr
      ON sr.sr_item_sk = i.i_item_sk
     AND sr.sr_customer_sk = c.c_customer_sk
     AND sr.sr_returned_date_sk = d_sold.d_date_sk
    LEFT JOIN reason r
      ON sr.sr_reason_sk = r.r_reason_sk
    LEFT JOIN store s
      ON sr.sr_store_sk = s.s_store_sk
    LEFT JOIN inventory inv
      ON inv.inv_item_sk = i.i_item_sk
     AND inv.inv_date_sk = d_sold.d_date_sk
    WHERE d_sold.d_year = 2001
      AND i.i_manufact_id IN (264, 995)
      AND w.w_state = 'CA'
      AND cc.cc_name = 'Call Center 1'
      AND sm.sm_type = 'AIR'
      AND s.s_city = 'Seattle'
      AND p.p_discount_active = 'Y'
    GROUP BY
        d_sold.d_year,
        i.i_category,
        i.i_manufact_id,
        w.w_warehouse_name,
        cc.cc_name,
        sm.sm_type,
        s.s_store_name
)
SELECT
    d_year,
    i_category,
    i_manufact_id,
    w_warehouse_name,
    total_sales,
    total_profit,
    total_returns,
    total_inventory,
    order_cnt,
    total_profit / NULLIF(total_sales, 0) AS profit_margin,
    RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
FROM sales_agg
WHERE total_sales > 1000000
  AND total_profit > 100000
ORDER BY total_sales DESC
LIMIT 100
