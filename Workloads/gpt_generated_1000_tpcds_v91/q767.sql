/* Goal: Summarize web‑sales performance by year and store, adding promotion, warehouse, call‑center and other dimension details, applying realistic filters, and showing subtotal rows. */
WITH sampled_sales AS (
    SELECT
        ws_sold_date_sk,
        ws_item_sk,
        ws_order_number,
        ws_quantity,
        ws_sales_price,
        ws_ext_sales_price,
        ws_net_profit,
        ws_bill_hdemo_sk,
        ws_warehouse_sk,
        ws_promo_sk
    FROM tpcds.web_sales
    TABLESAMPLE BERNOULLI (10)
)
SELECT
    d_sold.d_year,
    st.s_store_name,
    COUNT(DISTINCT s.ws_order_number)                       AS order_cnt,
    SUM(s.ws_ext_sales_price)                               AS total_sales,
    SUM(s.ws_net_profit)                                    AS total_profit,
    AVG(s.ws_sales_price)                                   AS avg_sales_price,
    CASE WHEN SUM(s.ws_ext_sales_price) > 50000 THEN 'High Sales' ELSE 'Low Sales' END AS sales_level,
    (SELECT AVG(ws_ext_sales_price) FROM tpcds.web_sales)  AS overall_avg_sales_price,
    MAX(cc.cc_name)                                         AS call_center_name,
    MAX(p.p_promo_name)                                     AS promo_name,
    MAX(r.r_reason_desc)                                    AS return_reason,
    MAX(cp.cp_type)                                         AS catalog_page_type,
    MAX(w.w_warehouse_name)                                 AS warehouse_name,
    CASE WHEN SUM(s.ws_quantity) > 1000 THEN 'Large Qty' ELSE 'Small Qty' END AS quantity_category
FROM sampled_sales s
JOIN tpcds.date_dim d_sold      ON s.ws_sold_date_sk   = d_sold.d_date_sk
JOIN tpcds.warehouse w          ON s.ws_warehouse_sk   = w.w_warehouse_sk
JOIN tpcds.promotion p          ON s.ws_promo_sk       = p.p_promo_sk
JOIN tpcds.household_demographics hd ON s.ws_bill_hdemo_sk = hd.hd_demo_sk
JOIN tpcds.web_returns wr      ON s.ws_order_number   = wr.wr_order_number
                                 AND s.ws_item_sk      = wr.wr_item_sk
JOIN tpcds.reason r            ON wr.wr_reason_sk    = r.r_reason_sk
JOIN tpcds.date_dim d_return   ON wr.wr_returned_date_sk = d_return.d_date_sk
JOIN tpcds.store st            ON st.s_closed_date_sk = d_sold.d_date_sk
JOIN tpcds.call_center cc      ON cc.cc_closed_date_sk = d_sold.d_date_sk
JOIN tpcds.catalog_page cp     ON cp.cp_start_date_sk = d_sold.d_date_sk
JOIN tpcds.date_dim d_promo    ON p.p_start_date_sk   = d_promo.d_date_sk
WHERE d_sold.d_year = 2001
  AND d_sold.d_date >= DATE '2001-01-01' AND d_sold.d_date < DATE '2002-01-01'
  AND hd.hd_income_band_sk IN (5, 9, 17)
  AND p.p_channel_email = 'N'
  AND cc.cc_state = 'CA'
  AND st.s_state = 'TX'
  AND cp.cp_type = 'monthly'
  AND s.ws_sales_price > 100
GROUP BY ROLLUP(d_sold.d_year, st.s_store_name)
ORDER BY d_sold.d_year ASC, st.s_store_name ASC
LIMIT 100
