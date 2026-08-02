WITH sales_summary AS (
    SELECT
        d_sold.d_year AS sales_year,
        s.s_state AS store_state,
        s.s_store_sk AS store_sk,
        i.i_category AS item_category,
        i.i_item_sk AS item_sk,
        r_sr.r_reason_desc AS store_return_reason,
        COUNT(DISTINCT cs.cs_order_number) AS num_orders,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        SUM(sr.sr_return_amt) AS total_store_return,
        SUM(wr.wr_return_amt) AS total_web_return,
        SUM(cs.cs_ext_sales_price) - (SUM(sr.sr_return_amt) + SUM(wr.wr_return_amt)) AS net_sales
    FROM
        catalog_sales cs
        JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
        JOIN item i ON cs.cs_item_sk = i.i_item_sk
        JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
        JOIN date_dim d_sold ON cs.cs_sold_date_sk = d_sold.d_date_sk
        JOIN date_dim d_ship ON cs.cs_ship_date_sk = d_ship.d_date_sk
        JOIN household_demographics hd_bill ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
        JOIN customer_address ca_bill ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
        JOIN store_returns sr ON sr.sr_item_sk = i.i_item_sk
        JOIN customer_address ca_sr ON sr.sr_addr_sk = ca_sr.ca_address_sk
        JOIN household_demographics hd_sr ON sr.sr_hdemo_sk = hd_sr.hd_demo_sk
        JOIN store s ON sr.sr_store_sk = s.s_store_sk
        JOIN reason r_sr ON sr.sr_reason_sk = r_sr.r_reason_sk
        JOIN date_dim d_sr_return ON sr.sr_returned_date_sk = d_sr_return.d_date_sk
        JOIN web_returns wr ON wr.wr_item_sk = i.i_item_sk
        JOIN date_dim d_web_return ON wr.wr_returned_date_sk = d_web_return.d_date_sk
        JOIN reason r_wr ON wr.wr_reason_sk = r_wr.r_reason_sk
        JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
        JOIN customer_address ca_wr_refund ON wr.wr_refunded_addr_sk = ca_wr_refund.ca_address_sk
        JOIN household_demographics hd_wr_refund ON wr.wr_refunded_hdemo_sk = hd_wr_refund.hd_demo_sk
        JOIN date_dim d_store_close ON s.s_closed_date_sk = d_store_close.d_date_sk
        JOIN date_dim d_cp_start ON cp.cp_start_date_sk = d_cp_start.d_date_sk
        JOIN date_dim d_cp_end ON cp.cp_end_date_sk = d_cp_end.d_date_sk
    WHERE
        cs.cs_net_paid > (
            SELECT AVG(cs3.cs_net_paid)
            FROM catalog_sales cs3
            WHERE cs3.cs_item_sk = cs.cs_item_sk
        )
    GROUP BY
        d_sold.d_year,
        s.s_state,
        s.s_store_sk,
        i.i_category,
        i.i_item_sk,
        r_sr.r_reason_desc
)
SELECT
    sales_year,
    store_state,
    store_sk,
    item_category,
    store_return_reason,
    num_orders,
    total_sales,
    total_store_return,
    total_web_return,
    net_sales,
    (
        SELECT AVG(cs2.cs_ext_sales_price)
        FROM catalog_sales cs2
        WHERE cs2.cs_item_sk = ss.item_sk
    ) AS avg_item_sales,
    ROW_NUMBER() OVER (ORDER BY net_sales DESC) AS rn
FROM sales_summary ss
WHERE EXISTS (
    SELECT 1
    FROM store_returns sr2
    WHERE sr2.sr_store_sk = ss.store_sk
      AND sr2.sr_return_amt > 50
)
ORDER BY net_sales DESC
LIMIT 100
