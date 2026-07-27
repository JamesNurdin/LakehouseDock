WITH sales_data AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        cd.cd_education_status,
        cd.cd_credit_rating,
        wp.wp_type,
        inv.inv_warehouse_sk,
        ws.ws_ext_sales_price,
        ws.ws_ext_discount_amt,
        ws.ws_order_number,
        ws.ws_net_profit,
        ws.ws_quantity
    FROM tpcds.web_sales ws
    INNER JOIN tpcds.date_dim d
        ON ws.ws_sold_date_sk = d.d_date_sk
    INNER JOIN tpcds.customer_demographics cd
        ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    INNER JOIN tpcds.web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    INNER JOIN tpcds.inventory inv
        ON inv.inv_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND d.d_month_seq BETWEEN 1200 AND 1220
      AND cd.cd_education_status = 'Advanced Degree'
      AND cd.cd_credit_rating = 'Low Risk'
      AND wp.wp_type = 'Home'
      AND inv.inv_warehouse_sk IN (14, 8)
      AND ws.ws_quantity > 5
)
SELECT
    d_year,
    d_month_seq,
    cd_education_status,
    cd_credit_rating,
    wp_type,
    inv_warehouse_sk,
    SUM(ws_ext_sales_price) AS total_sales,
    AVG(ws_ext_discount_amt) AS avg_discount,
    COUNT(DISTINCT ws_order_number) AS order_cnt,
    MIN(ws_net_profit) AS min_profit,
    MAX(ws_net_profit) AS max_profit
FROM sales_data
GROUP BY
    d_year,
    d_month_seq,
    cd_education_status,
    cd_credit_rating,
    wp_type,
    inv_warehouse_sk
ORDER BY total_sales DESC
LIMIT 100
