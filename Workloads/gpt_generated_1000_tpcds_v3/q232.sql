WITH base AS (
    SELECT 
        d.d_year,
        i.i_category,
        i.i_brand,
        w.w_state,
        w.w_city,
        sm.sm_type,
        we.web_name,
        cs.cs_order_number,
        cs.cs_net_paid,
        cs.cs_ext_sales_price,
        cs.cs_quantity,
        ws.ws_order_number,
        ws.ws_net_paid,
        sr.sr_return_amt,
        wr.wr_net_loss,
        c.c_customer_sk
    FROM tpcds.date_dim d
    JOIN tpcds.catalog_sales cs ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN tpcds.item i ON cs.cs_item_sk = i.i_item_sk
    JOIN tpcds.customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN tpcds.customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN tpcds.household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN tpcds.income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN tpcds.ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN tpcds.warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN tpcds.store_returns sr ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN tpcds.web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN tpcds.web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN tpcds.web_site we ON ws.ws_web_site_sk = we.web_site_sk
    JOIN tpcds.web_returns wr ON wr.wr_order_number = ws.ws_order_number
        AND wr.wr_item_sk = i.i_item_sk
        AND wr.wr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND d.d_holiday = 'Y'
      AND i.i_brand = 'Brand#12'
      AND w.w_city = 'Seattle'
      AND sm.sm_type = 'AIR'
      AND cs.cs_quantity > 5
      AND EXISTS (
          SELECT 1 FROM tpcds.store_returns sr2
          WHERE sr2.sr_customer_sk = c.c_customer_sk
            AND sr2.sr_return_quantity > 0
      )
)
SELECT 
    b.d_year,
    b.i_category,
    b.w_state,
    b.sm_type,
    b.web_name,
    SUM(b.cs_net_paid) AS total_catalog_net_paid,
    SUM(b.ws_net_paid) AS total_web_net_paid,
    COUNT(DISTINCT b.cs_order_number) AS catalog_order_cnt,
    COUNT(DISTINCT b.ws_order_number) AS web_order_cnt,
    AVG(b.cs_ext_sales_price) AS avg_catalog_ext_sales_price,
    MAX(b.wr_net_loss) AS max_web_return_loss,
    SUM(b.sr_return_amt) AS total_store_return_amount,
    (SELECT AVG(wr2.wr_return_amt)
     FROM tpcds.web_returns wr2
     JOIN tpcds.date_dim d2 ON wr2.wr_returned_date_sk = d2.d_date_sk
     WHERE d2.d_year = b.d_year) AS avg_return_amt_by_year
FROM base b
GROUP BY b.d_year, b.i_category, b.w_state, b.sm_type, b.web_name
ORDER BY total_catalog_net_paid DESC
LIMIT 100
