WITH base_data AS (
    SELECT
        cr.cr_return_amount,
        cr.cr_return_quantity,
        cr.cr_net_loss,
        ws.ws_ext_sales_price,
        ws.ws_net_profit,
        i.i_category,
        i.i_item_sk,
        d_sold.d_year AS d_year,
        hd_bill.hd_income_band_sk AS hd_income_band_sk,
        cr.cr_item_sk,
        ws.ws_item_sk AS ws_item_sk
    FROM catalog_returns cr
    JOIN date_dim d_ret ON cr.cr_returned_date_sk = d_ret.d_date_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN customer cust_ref ON cr.cr_refunded_customer_sk = cust_ref.c_customer_sk
    JOIN household_demographics hd_ref ON cr.cr_refunded_hdemo_sk = hd_ref.hd_demo_sk
    JOIN customer_address ca_ref ON cr.cr_refunded_addr_sk = ca_ref.ca_address_sk
    JOIN customer cust_ret ON cr.cr_returning_customer_sk = cust_ret.c_customer_sk
    JOIN household_demographics hd_ret ON cr.cr_returning_hdemo_sk = hd_ret.hd_demo_sk
    JOIN customer_address ca_ret ON cr.cr_returning_addr_sk = ca_ret.ca_address_sk
    -- link sales by the same item
    JOIN web_sales ws ON ws.ws_item_sk = cr.cr_item_sk
    JOIN date_dim d_sold ON ws.ws_sold_date_sk = d_sold.d_date_sk
    JOIN date_dim d_ship ON ws.ws_ship_date_sk = d_ship.d_date_sk
    JOIN customer cust_bill ON ws.ws_bill_customer_sk = cust_bill.c_customer_sk
    JOIN household_demographics hd_bill ON ws.ws_bill_hdemo_sk = hd_bill.hd_demo_sk
    JOIN customer_address ca_bill ON ws.ws_bill_addr_sk = ca_bill.ca_address_sk
    JOIN customer cust_ship ON ws.ws_ship_customer_sk = cust_ship.c_customer_sk
    JOIN household_demographics hd_ship ON ws.ws_ship_hdemo_sk = hd_ship.hd_demo_sk
    JOIN customer_address ca_ship ON ws.ws_ship_addr_sk = ca_ship.ca_address_sk
    -- additional joins to satisfy the nine‑join requirement
    JOIN household_demographics hd_bill_current ON cust_bill.c_current_hdemo_sk = hd_bill_current.hd_demo_sk
    JOIN customer_address ca_bill_current ON cust_bill.c_current_addr_sk = ca_bill_current.ca_address_sk
    JOIN date_dim d_first_sales ON cust_bill.c_first_sales_date_sk = d_first_sales.d_date_sk
    WHERE EXISTS (
        SELECT 1 FROM catalog_returns cr_ex
        WHERE cr_ex.cr_refunded_customer_sk = cust_bill.c_customer_sk
          AND cr_ex.cr_return_amount > 5000
    )
),
agg_data AS (
    SELECT
        d_year,
        i_category,
        hd_income_band_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        SUM(ws_net_profit) AS total_profit,
        SUM(cr_return_amount) AS total_return_amount,
        MAX(i_item_sk) AS item_sk
    FROM base_data
    GROUP BY CUBE (d_year, i_category, hd_income_band_sk)
)
SELECT
    a.d_year,
    a.i_category,
    a.hd_income_band_sk,
    a.total_sales,
    a.total_profit,
    a.total_return_amount,
    CASE WHEN a.total_sales > 0 THEN a.total_return_amount / a.total_sales END AS return_to_sales_ratio,
    CASE WHEN a.total_sales > 10000 THEN 'High' ELSE 'Low' END AS sales_volume_flag,
    (
        SELECT AVG(cr2.cr_return_amount)
        FROM catalog_returns cr2
        WHERE cr2.cr_item_sk = a.item_sk
    ) AS avg_item_return_amount,
    SUM(a.total_sales) OVER (PARTITION BY a.i_category ORDER BY a.d_year) AS cumulative_sales_by_category
FROM agg_data a
ORDER BY a.d_year DESC, a.i_category, a.hd_income_band_sk
LIMIT 100
