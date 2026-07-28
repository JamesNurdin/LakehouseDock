/*
Goal: Analyze yearly net paid revenue by state, brand, department and income band, while accounting for high‑quantity catalog returns and warehouse offsets. The query joins all 13 selected TPC‑DS tables using only the permitted join keys, applies realistic filter predicates, aggregates key metrics, and demonstrates a CASE WHEN expression.
*/
SELECT
    d.d_year,
    s.s_state,
    i.i_brand,
    cp.cp_department,
    ib.ib_income_band_sk,
    COUNT(DISTINCT c.c_customer_id)               AS num_customers,
    SUM(cs.cs_net_paid)                           AS total_net_paid,
    AVG(ss.ss_ext_sales_price)                    AS avg_store_sales,
    SUM(CASE WHEN cr.cr_return_quantity > 5 THEN cr.cr_return_amount ELSE 0 END) AS high_return_amount,
    MIN(w.w_gmt_offset)                           AS min_warehouse_offset
FROM
    date_dim d
    JOIN catalog_sales cs
        ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN catalog_returns cr
        ON cr.cr_order_number = cs.cs_order_number
    JOIN customer c
        ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN household_demographics hd
        ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    JOIN inventory inv
        ON inv.inv_item_sk = i.i_item_sk
        AND inv.inv_date_sk = d.d_date_sk
    JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN store_sales ss
        ON ss.ss_sold_date_sk = d.d_date_sk
        AND ss.ss_item_sk = i.i_item_sk
        AND ss.ss_customer_sk = c.c_customer_sk
        AND ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    JOIN web_returns wr
        ON wr.wr_item_sk = i.i_item_sk
        AND wr.wr_returned_date_sk = d.d_date_sk
        AND wr.wr_refunded_customer_sk = c.c_customer_sk
        AND wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
WHERE
    d.d_year = 2002
    AND i.i_brand = 'Brand#12'
    AND w.w_city = 'Chicago'
    AND s.s_state = 'CA'
    AND c.c_preferred_cust_flag = 'Y'
GROUP BY
    d.d_year,
    s.s_state,
    i.i_brand,
    cp.cp_department,
    ib.ib_income_band_sk
ORDER BY
    total_net_paid DESC
LIMIT 100
