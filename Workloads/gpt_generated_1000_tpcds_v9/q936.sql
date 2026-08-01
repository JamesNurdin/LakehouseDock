WITH sales_agg AS (
    SELECT 
        d_sold.d_year AS d_year,
        i.i_category AS i_category,
        cc.cc_state AS cc_state,
        cp.cp_type AS cp_type,
        hd_bill.hd_income_band_sk AS hd_income_band_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws.ws_order_number) AS order_cnt,
        AVG(ws.ws_quantity) AS avg_quantity
    FROM tpcds.web_sales ws
    JOIN tpcds.date_dim d_sold
        ON ws.ws_sold_date_sk = d_sold.d_date_sk
    JOIN tpcds.item i
        ON ws.ws_item_sk = i.i_item_sk
    JOIN tpcds.household_demographics hd_bill
        ON ws.ws_bill_hdemo_sk = hd_bill.hd_demo_sk
    JOIN tpcds.call_center cc
        ON cc.cc_open_date_sk = d_sold.d_date_sk
    JOIN tpcds.catalog_page cp
        ON cp.cp_start_date_sk = d_sold.d_date_sk
    WHERE 
        i.i_current_price BETWEEN 50 AND 200
        AND ws.ws_quantity >= 2
        AND d_sold.d_year = 2001
        AND hd_bill.hd_dep_count <= 3
        AND cc.cc_state IN ('CA', 'TX', 'NY')
        AND cp.cp_type = 'C'
        AND i.i_color = 'Red'
    GROUP BY 
        d_sold.d_year,
        i.i_category,
        cc.cc_state,
        cp.cp_type,
        hd_bill.hd_income_band_sk
    HAVING 
        SUM(ws.ws_ext_sales_price) > 100000
        AND COUNT(DISTINCT ws.ws_order_number) >= 10
)
SELECT 
    d_year,
    i_category,
    cc_state,
    cp_type,
    hd_income_band_sk,
    total_sales,
    total_profit,
    order_cnt,
    avg_quantity,
    RANK() OVER (PARTITION BY d_year ORDER BY total_sales DESC) AS sales_rank_in_year,
    SUM(total_sales) OVER (
        PARTITION BY i_category 
        ORDER BY total_sales 
        ROWS BETWEEN 1 PRECEDING AND CURRENT ROW
    ) AS moving_sales_sum
FROM sales_agg
ORDER BY d_year, sales_rank_in_year
