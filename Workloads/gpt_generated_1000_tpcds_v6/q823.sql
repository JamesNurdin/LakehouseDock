WITH base AS (
    SELECT
        ws_site.web_name,
        cp.cp_department,
        cd_bill.cd_gender,
        d_sold.d_year,
        d_sold.d_fy_quarter_seq,
        ws.ws_order_number,
        ws.ws_ext_sales_price,
        ws.ws_net_profit,
        inv.inv_quantity_on_hand
    FROM tpcds.web_sales ws
    JOIN tpcds.date_dim d_sold
        ON ws.ws_sold_date_sk = d_sold.d_date_sk
    JOIN tpcds.customer_demographics cd_bill
        ON ws.ws_bill_cdemo_sk = cd_bill.cd_demo_sk
    JOIN tpcds.web_site ws_site
        ON ws.ws_web_site_sk = ws_site.web_site_sk
    JOIN tpcds.catalog_page cp
        ON cp.cp_start_date_sk = d_sold.d_date_sk
    JOIN tpcds.inventory inv
        ON inv.inv_date_sk = d_sold.d_date_sk
    WHERE d_sold.d_year = 2000
      AND d_sold.d_fy_quarter_seq = 8
      AND cd_bill.cd_gender = 'M'
      AND cp.cp_department = 'Electronics'
      AND inv.inv_quantity_on_hand > 500
      AND ws.ws_net_profit > 0
)
SELECT
    web_name,
    cp_department,
    cd_gender,
    d_year,
    d_fy_quarter_seq,
    COUNT(DISTINCT ws_order_number) AS orders,
    SUM(ws_ext_sales_price) AS total_sales,
    AVG(ws_net_profit) AS avg_profit,
    MIN(ws_ext_sales_price) AS min_sale,
    MAX(ws_ext_sales_price) AS max_sale,
    SUM(inv_quantity_on_hand) AS total_inventory_qty,
    SUM(SUM(ws_ext_sales_price)) OVER (PARTITION BY web_name) AS site_total_sales
FROM base
GROUP BY web_name, cp_department, cd_gender, d_year, d_fy_quarter_seq
ORDER BY total_sales DESC
LIMIT 100
