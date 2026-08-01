WITH base_data AS (
    SELECT
        d.d_date,
        d.d_year,
        d.d_month_seq,
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        hd.hd_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_ext_sales_price,
        ws.ws_ext_discount_amt,
        ws.ws_ext_tax,
        ws.ws_net_paid,
        ws.ws_net_paid_inc_tax,
        ws.ws_net_profit,
        sr.sr_return_quantity,
        sr.sr_return_amt,
        sr.sr_refunded_cash,
        wr.wr_return_quantity,
        wr.wr_return_amt,
        wr.wr_net_loss,
        wp.wp_web_page_id,
        wp.wp_type,
        cp.cp_catalog_number,
        cp.cp_type AS cp_type,
        inv.inv_quantity_on_hand
    FROM date_dim d
    INNER JOIN store_returns sr
        ON sr.sr_returned_date_sk = d.d_date_sk
    INNER JOIN customer c
        ON sr.sr_customer_sk = c.c_customer_sk
    INNER JOIN household_demographics hd
        ON sr.sr_hdemo_sk = hd.hd_demo_sk
    INNER JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    LEFT JOIN inventory inv
        ON inv.inv_date_sk = d.d_date_sk
    INNER JOIN web_sales ws
        ON ws.ws_sold_date_sk = d.d_date_sk
        AND ws.ws_bill_customer_sk = c.c_customer_sk
        AND ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    INNER JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
        AND wp.wp_creation_date_sk = d.d_date_sk
        AND wp.wp_customer_sk = c.c_customer_sk
    LEFT JOIN web_returns wr
        ON wr.wr_order_number = ws.ws_order_number
        AND wr.wr_item_sk = ws.ws_item_sk
        AND wr.wr_returned_date_sk = d.d_date_sk
    LEFT JOIN catalog_page cp
        ON cp.cp_start_date_sk = d.d_date_sk
    WHERE d.d_year = 2000
      AND hd.hd_income_band_sk = 9
      AND wp.wp_type = 'product'
)
SELECT
    bd.d_year,
    bd.d_month_seq,
    bd.c_customer_id,
    bd.c_first_name,
    bd.c_last_name,
    bd.wp_type,
    bd.cp_catalog_number,
    COUNT(DISTINCT bd.ws_order_number) AS orders_cnt,
    SUM(bd.ws_ext_sales_price) AS total_sales,
    SUM(bd.ws_net_profit) AS total_net_profit,
    SUM(COALESCE(bd.sr_return_amt, 0)) AS total_store_return_amt,
    SUM(COALESCE(bd.wr_return_amt, 0)) AS total_web_return_amt,
    AVG(CASE WHEN bd.ws_quantity > 5 THEN bd.ws_ext_sales_price / bd.ws_quantity ELSE bd.ws_ext_sales_price END) AS avg_price_per_item,
    CASE WHEN SUM(bd.ws_net_profit) > 100000 THEN 'High' ELSE 'Low' END AS profit_category
FROM base_data bd
GROUP BY
    bd.d_year,
    bd.d_month_seq,
    bd.c_customer_id,
    bd.c_first_name,
    bd.c_last_name,
    bd.wp_type,
    bd.cp_catalog_number
ORDER BY total_net_profit DESC
LIMIT 100
