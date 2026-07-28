WITH filtered_item AS (
    SELECT *
    FROM item
    WHERE i_rec_start_date >= DATE '2000-01-01'
      AND i_size = 'large'
),
inventory_filtered AS (
    SELECT inv_item_sk, inv_quantity_on_hand
    FROM inventory
    WHERE inv_quantity_on_hand > 100
),
joined AS (
    SELECT
        cs.cs_order_number,
        cs.cs_ext_sales_price,
        cs.cs_net_paid,
        cs.cs_ship_mode_sk,
        cs.cs_item_sk,
        cs.cs_bill_customer_sk,
        cs.cs_sold_time_sk,
        ss.ss_sold_time_sk AS ss_time_sk,
        ss.ss_ext_sales_price AS ss_sales_price,
        ss.ss_net_paid AS ss_net_paid,
        sr.sr_return_amt,
        sr.sr_net_loss,
        i.i_category,
        i.i_brand,
        i.i_manager_id,
        sm.sm_type,
        hd.hd_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        ca.ca_state,
        c.c_preferred_cust_flag,
        t1.t_hour AS sale_hour,
        t2.t_hour AS return_hour,
        r.r_reason_desc
    FROM catalog_sales cs
    JOIN filtered_item i                     ON cs.cs_item_sk = i.i_item_sk
    JOIN ship_mode sm                         ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN customer c                           ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca                  ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN household_demographics hd            ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib                       ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN time_dim t1                          ON cs.cs_sold_time_sk = t1.t_time_sk
    JOIN store_sales ss                       ON cs.cs_order_number = ss.ss_ticket_number
    JOIN time_dim t2                          ON ss.ss_sold_time_sk = t2.t_time_sk
    JOIN store_returns sr                     ON ss.ss_ticket_number = sr.sr_ticket_number
    JOIN time_dim t3                          ON sr.sr_return_time_sk = t3.t_time_sk
    JOIN reason r                             ON sr.sr_reason_sk = r.r_reason_sk
    WHERE sm.sm_type = 'AIR'
      AND t1.t_hour BETWEEN 9 AND 17
      AND ib.ib_lower_bound >= 50000
      AND EXISTS (
          SELECT 1
          FROM inventory_filtered invf
          WHERE invf.inv_item_sk = i.i_item_sk
      )
),
agg AS (
    SELECT
        i_category,
        i_brand,
        sm_type,
        ib_lower_bound,
        COUNT(DISTINCT cs_order_number) AS orders_cnt,
        SUM(cs_ext_sales_price) AS total_sales,
        AVG(cs_net_paid) AS avg_net_paid,
        MAX(cs_ext_sales_price) AS max_sale,
        MIN(cs_ext_sales_price) AS min_sale
    FROM joined
    GROUP BY i_category, i_brand, sm_type, ib_lower_bound
)
SELECT
    i_category,
    i_brand,
    sm_type,
    ib_lower_bound,
    orders_cnt,
    total_sales,
    avg_net_paid,
    max_sale,
    min_sale,
    ROW_NUMBER() OVER (PARTITION BY i_category ORDER BY total_sales DESC) AS category_rank
FROM agg
ORDER BY total_sales DESC
LIMIT 100
