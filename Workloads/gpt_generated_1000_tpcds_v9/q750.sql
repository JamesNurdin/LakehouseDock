WITH sales_data AS (
    -- Store channel (store_sales) rows
    SELECT
        d.d_year,
        i.i_category AS category,
        cd.cd_gender AS gender,
        hd.hd_vehicle_count AS vehicle_count,
        ss.ss_ext_sales_price AS sales_amount,
        ss.ss_quantity AS quantity,
        ss.ss_ext_discount_amt AS discount_amount
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    WHERE d.d_year = 1998
      AND i.i_category_id = 7
      AND ca.ca_state = 'CA'
      AND cd.cd_gender = 'M'
      AND hd.hd_vehicle_count >= 2
    UNION
    -- Web channel (web_sales) rows, adjusted for possible returns
    SELECT
        d_sale.d_year,
        i.i_category AS category,
        cd_bill.cd_gender AS gender,
        hd_bill.hd_vehicle_count AS vehicle_count,
        (ws.ws_ext_sales_price - COALESCE(wr.wr_return_amt, 0)) AS sales_amount,
        (ws.ws_quantity - COALESCE(wr.wr_return_quantity, 0)) AS quantity,
        (ws.ws_ext_discount_amt - COALESCE(wr.wr_return_tax, 0)) AS discount_amount
    FROM web_sales ws
    JOIN date_dim d_sale ON ws.ws_sold_date_sk = d_sale.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN customer_demographics cd_bill ON ws.ws_bill_cdemo_sk = cd_bill.cd_demo_sk
    JOIN household_demographics hd_bill ON ws.ws_bill_hdemo_sk = hd_bill.hd_demo_sk
    JOIN customer_address ca_bill ON ws.ws_bill_addr_sk = ca_bill.ca_address_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN web_returns wr ON ws.ws_order_number = wr.wr_order_number
    LEFT JOIN date_dim d_return ON wr.wr_returned_date_sk = d_return.d_date_sk
    WHERE d_sale.d_year = 1998
      AND i.i_category_id = 7
      AND ca_bill.ca_state = 'CA'
      AND cd_bill.cd_gender = 'M'
      AND hd_bill.hd_vehicle_count >= 2
      AND wp.wp_type = 'home'
      AND w.w_state = 'CA'
),
agg_sales AS (
    SELECT
        d_year,
        category,
        gender,
        SUM(sales_amount) AS total_sales,
        SUM(quantity) AS total_quantity,
        SUM(discount_amount) AS total_discount,
        AVG(vehicle_count) AS avg_vehicle_count
    FROM sales_data
    GROUP BY GROUPING SETS (
        (d_year, category, gender),
        (d_year, category),
        (d_year),
        ()
    )
)
SELECT
    d_year,
    category,
    gender,
    total_sales,
    total_quantity,
    total_discount,
    avg_vehicle_count,
    ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY total_sales DESC) AS sales_rank
FROM agg_sales
ORDER BY d_year, sales_rank
LIMIT 100
