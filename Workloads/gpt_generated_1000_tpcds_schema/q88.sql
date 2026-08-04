WITH base AS (
    SELECT
        d.d_date,
        d.d_year,
        cp.cp_department,
        i.i_category,
        i.i_brand,
        p.p_promo_id,
        p.p_purpose,
        sm.sm_type,
        w.w_warehouse_name,
        cs.cs_ext_sales_price AS catalog_sales_price,
        cs.cs_ext_discount_amt AS catalog_discount,
        cs.cs_net_paid AS catalog_net_paid,
        ss.ss_ext_sales_price AS store_sales_price,
        ss.ss_ext_discount_amt AS store_discount,
        ss.ss_net_paid AS store_net_paid,
        sr.sr_return_amt AS store_return_amt,
        wr.wr_return_amt AS web_return_amt,
        cs.cs_order_number AS order_number
    FROM date_dim d
    JOIN catalog_page cp ON cp.cp_start_date_sk = d.d_date_sk
    JOIN catalog_sales cs ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN store_sales ss ON ss.ss_sold_date_sk = d.d_date_sk
        AND ss.ss_item_sk = i.i_item_sk
        AND ss.ss_hdemo_sk = hd.hd_demo_sk
        AND ss.ss_promo_sk = p.p_promo_sk
    LEFT JOIN store_returns sr ON sr.sr_returned_date_sk = d.d_date_sk
        AND sr.sr_item_sk = i.i_item_sk
        AND sr.sr_hdemo_sk = hd.hd_demo_sk
        AND sr.sr_ticket_number = ss.ss_ticket_number
    LEFT JOIN web_returns wr ON wr.wr_returned_date_sk = d.d_date_sk
        AND wr.wr_item_sk = i.i_item_sk
        AND wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
    WHERE d.d_year = 2001
      AND p.p_channel_event = 'N'
      AND sm.sm_type = 'EXPRESS'
      AND w.w_country = 'United States'
      AND i.i_category = 'Electronics'
)
SELECT
    d_year,
    cp_department,
    i_category,
    p_promo_id,
    sm_type,
    COUNT(DISTINCT order_number) AS distinct_orders,
    SUM(catalog_sales_price) AS sum_catalog_sales,
    SUM(store_sales_price) AS sum_store_sales,
    SUM(store_return_amt) AS sum_store_returns,
    SUM(web_return_amt) AS sum_web_returns,
    (SUM(catalog_sales_price) + SUM(store_sales_price) - SUM(store_return_amt) - SUM(web_return_amt)) AS net_revenue
FROM base
GROUP BY d_year, cp_department, i_category, p_promo_id, sm_type
ORDER BY net_revenue DESC
LIMIT 100
