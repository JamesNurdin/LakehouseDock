WITH joined_data AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        i.i_category,
        i.i_brand,
        p.p_promo_name,
        ss.ss_ticket_number AS store_ticket_number,
        ss.ss_net_paid AS store_sales_net_paid,
        ss.ss_ext_discount_amt AS store_discount,
        sr.sr_return_amt AS store_return_amt,
        ws.ws_net_paid AS web_sales_net_paid,
        wr.wr_return_amt AS web_return_amt,
        r_sr.r_reason_desc AS store_return_reason
    FROM tpcds.date_dim d
    JOIN tpcds.store_sales ss ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN tpcds.item i ON ss.ss_item_sk = i.i_item_sk
    JOIN tpcds.promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN tpcds.customer_demographics c ON ss.ss_cdemo_sk = c.cd_demo_sk
    LEFT JOIN tpcds.store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
    LEFT JOIN tpcds.reason r_sr ON sr.sr_reason_sk = r_sr.r_reason_sk
    LEFT JOIN tpcds.catalog_returns cr ON cr.cr_item_sk = i.i_item_sk AND cr.cr_returned_date_sk = d.d_date_sk
    LEFT JOIN tpcds.call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    LEFT JOIN tpcds.catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    LEFT JOIN tpcds.ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    LEFT JOIN tpcds.warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN tpcds.web_sales ws ON ws.ws_item_sk = i.i_item_sk AND ws.ws_sold_date_sk = d.d_date_sk
    LEFT JOIN tpcds.web_returns wr ON wr.wr_order_number = ws.ws_order_number
    LEFT JOIN tpcds.reason r_wr ON wr.wr_reason_sk = r_wr.r_reason_sk
    WHERE d.d_year = 2001
      AND i.i_category = 'Sports'
      AND p.p_channel_radio = 'N'
      AND r_sr.r_reason_desc LIKE '%warranty%'
),
agg AS (
    SELECT
        d_year,
        d_month_seq,
        i_category,
        i_brand,
        p_promo_name,
        SUM(store_sales_net_paid) AS total_store_sales,
        SUM(COALESCE(store_return_amt, 0)) AS total_store_returns,
        SUM(COALESCE(web_sales_net_paid, 0)) AS total_web_sales,
        SUM(COALESCE(web_return_amt, 0)) AS total_web_returns,
        AVG(store_discount) AS avg_store_discount,
        COUNT(DISTINCT store_ticket_number) AS cnt_store_transactions
    FROM joined_data
    GROUP BY
        d_year,
        d_month_seq,
        i_category,
        i_brand,
        p_promo_name
)
SELECT
    d_year,
    d_month_seq,
    i_category,
    i_brand,
    p_promo_name,
    total_store_sales,
    total_store_returns,
    total_web_sales,
    total_web_returns,
    avg_store_discount,
    cnt_store_transactions,
    SUM(total_store_sales) OVER (
        PARTITION BY d_year
        ORDER BY d_month_seq
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cum_store_sales_year
FROM agg
ORDER BY total_store_sales DESC
LIMIT 100
