WITH detailed AS (
    SELECT 
        ss.ss_sold_date_sk,
        ss.ss_ext_sales_price,
        ss.ss_sold_time_sk,
        ss.ss_item_sk,
        ss.ss_customer_sk,
        ss.ss_hdemo_sk,
        ss.ss_store_sk,
        s.s_store_id,
        s.s_state,
        i.i_item_id,
        i.i_product_name,
        i.i_current_price,
        inv.inv_quantity_on_hand,
        hd.hd_vehicle_count,
        ib.ib_upper_bound,
        td.t_hour,
        c.c_customer_sk
    FROM store_sales ss
    JOIN item i
        ON ss.ss_item_sk = i.i_item_sk
    JOIN inventory inv
        ON i.i_item_sk = inv.inv_item_sk
    JOIN time_dim td
        ON ss.ss_sold_time_sk = td.t_time_sk
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    JOIN customer c
        ON ss.ss_customer_sk = c.c_customer_sk
    JOIN household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
        AND c.c_current_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE i.i_current_price > 50.00
      AND s.s_state = 'CA'
      AND td.t_hour BETWEEN 9 AND 17
      AND inv.inv_quantity_on_hand > 200
      AND ss.ss_ext_sales_price > (
          SELECT AVG(ss2.ss_ext_sales_price)
          FROM store_sales ss2
          WHERE ss2.ss_store_sk = ss.ss_store_sk
      )
),
aggregated AS (
    SELECT ss_store_sk,
           SUM(ss_ext_sales_price) AS store_total_sales
    FROM store_sales ss
    GROUP BY ss_store_sk
)
SELECT 
    d.ss_sold_date_sk,
    d.s_store_id,
    d.s_state,
    d.i_item_id,
    d.i_product_name,
    d.i_current_price,
    d.inv_quantity_on_hand,
    d.hd_vehicle_count,
    CASE 
        WHEN d.ib_upper_bound > 150000 THEN 'High Income'
        WHEN d.ib_upper_bound > 100000 THEN 'Upper Middle Income'
        ELSE 'Low Income'
    END AS income_category,
    d.ss_ext_sales_price,
    a.store_total_sales,
    DENSE_RANK() OVER (ORDER BY a.store_total_sales DESC) AS store_sales_rank,
    ROW_NUMBER() OVER (PARTITION BY d.s_state ORDER BY d.ss_ext_sales_price DESC) AS rn_state_sales,
    (
        SELECT COUNT(*)
        FROM store_sales ss_sub
        WHERE ss_sub.ss_customer_sk = d.ss_customer_sk
          AND ss_sub.ss_sold_date_sk = d.ss_sold_date_sk
    ) AS cust_daily_txn_count
FROM detailed d
JOIN aggregated a ON d.ss_store_sk = a.ss_store_sk
ORDER BY a.store_total_sales DESC, rn_state_sales
LIMIT 100
