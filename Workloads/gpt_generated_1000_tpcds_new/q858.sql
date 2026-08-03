WITH base_1998 AS (
    SELECT
        s.s_store_id,
        r.r_reason_desc,
        SUM(cs.cs_net_paid_inc_ship)               AS total_sales,
        SUM(cr.cr_net_loss)                         AS total_returns_loss,
        COUNT(DISTINCT cs.cs_order_number)          AS orders_cnt,
        AVG(cs.cs_ext_discount_amt)                 AS avg_discount
    FROM catalog_sales cs
    JOIN catalog_returns cr
      ON cr.cr_order_number = cs.cs_order_number
     AND cr.cr_item_sk = cs.cs_item_sk
    JOIN catalog_page cp
      ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN date_dim d
      ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN time_dim t
      ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN customer c
      ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca
      ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN household_demographics hd
      ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
      ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN reason r
      ON cr.cr_reason_sk = r.r_reason_sk
    JOIN warehouse w
      ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN store_sales ss
      ON ss.ss_sold_date_sk = d.d_date_sk
     AND ss.ss_sold_time_sk = t.t_time_sk
    JOIN store s
      ON ss.ss_store_sk = s.s_store_sk
    WHERE d.d_year = 1998
      AND s.s_state = 'CA'
      AND w.w_street_number = '69'
      AND ib.ib_lower_bound >= 50000
      AND t.t_hour BETWEEN 9 AND 17
    GROUP BY s.s_store_id, r.r_reason_desc
    HAVING SUM(cs.cs_net_paid_inc_ship) > 10000
),
base_1997 AS (
    SELECT
        s.s_store_id,
        r.r_reason_desc,
        SUM(cs.cs_net_paid_inc_ship)               AS total_sales,
        SUM(cr.cr_net_loss)                         AS total_returns_loss,
        COUNT(DISTINCT cs.cs_order_number)          AS orders_cnt,
        AVG(cs.cs_ext_discount_amt)                 AS avg_discount
    FROM catalog_sales cs
    JOIN catalog_returns cr
      ON cr.cr_order_number = cs.cs_order_number
     AND cr.cr_item_sk = cs.cs_item_sk
    JOIN catalog_page cp
      ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN date_dim d
      ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN time_dim t
      ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN customer c
      ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca
      ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN household_demographics hd
      ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
      ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN reason r
      ON cr.cr_reason_sk = r.r_reason_sk
    JOIN warehouse w
      ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN store_sales ss
      ON ss.ss_sold_date_sk = d.d_date_sk
     AND ss.ss_sold_time_sk = t.t_time_sk
    JOIN store s
      ON ss.ss_store_sk = s.s_store_sk
    WHERE d.d_year = 1997
      AND s.s_state = 'CA'
      AND w.w_street_number = '69'
      AND ib.ib_lower_bound >= 50000
      AND t.t_hour BETWEEN 9 AND 17
    GROUP BY s.s_store_id, r.r_reason_desc
    HAVING SUM(cs.cs_net_paid_inc_ship) > 10000
),
diff AS (
    SELECT s_store_id,
           r_reason_desc,
           total_sales,
           total_returns_loss,
           orders_cnt,
           avg_discount
    FROM base_1998
    EXCEPT
    SELECT s_store_id,
           r_reason_desc,
           total_sales,
           total_returns_loss,
           orders_cnt,
           avg_discount
    FROM base_1997
),
ranked AS (
    SELECT
        s_store_id,
        r_reason_desc,
        total_sales,
        total_returns_loss,
        orders_cnt,
        avg_discount,
        ROW_NUMBER() OVER (PARTITION BY s_store_id ORDER BY total_sales DESC) AS rn
    FROM diff
)
SELECT
    s_store_id,
    r_reason_desc,
    total_sales,
    total_returns_loss,
    orders_cnt,
    avg_discount
FROM ranked
WHERE rn <= 3
ORDER BY s_store_id, total_sales DESC
LIMIT 100
