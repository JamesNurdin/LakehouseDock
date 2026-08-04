WITH
    inv AS (
        SELECT
            inv_item_sk,
            inv_warehouse_sk,
            inv_date_sk,
            inv_quantity_on_hand
        FROM inventory
        TABLESAMPLE BERNOULLI (10)
    ),
    sales AS (
        SELECT
            cs_bill_customer_sk      AS customer_sk,
            cs_sold_date_sk,
            cs_sold_time_sk,
            cs_ext_sales_price,
            cs_net_profit,
            cs_item_sk,
            cs_warehouse_sk,
            cs_call_center_sk,
            cs_catalog_page_sk
        FROM catalog_sales
        WHERE cs_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2001)
    ),
    web AS (
        SELECT
            ws_bill_customer_sk AS customer_sk,
            ws_sold_date_sk,
            ws_sold_time_sk,
            ws_ext_sales_price,
            ws_net_profit,
            ws_item_sk,
            ws_warehouse_sk,
            ws_web_site_sk
        FROM web_sales
        WHERE ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2001)
    ),
    returns AS (
        SELECT
            cr_refunded_customer_sk AS customer_sk,
            cr_returned_date_sk,
            cr_returned_time_sk,
            cr_return_amount,
            cr_return_quantity,
            cr_item_sk,
            cr_warehouse_sk,
            cr_call_center_sk,
            cr_catalog_page_sk
        FROM catalog_returns
        WHERE cr_returned_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2001)
    )
SELECT
    c.c_customer_id,
    d_main.d_year,
    SUM(sales.cs_ext_sales_price)                         AS total_sales,
    SUM(web.ws_ext_sales_price)                           AS total_web_sales,
    SUM(returns.cr_return_amount)                         AS total_returns,
    (SUM(sales.cs_net_profit) + SUM(web.ws_net_profit) - SUM(returns.cr_return_amount)) AS net_contribution,
    RANK() OVER (PARTITION BY d_main.d_year ORDER BY (SUM(sales.cs_net_profit) + SUM(web.ws_net_profit) - SUM(returns.cr_return_amount)) DESC) AS profit_rank
FROM
    customer c
    LEFT JOIN sales   ON c.c_customer_sk = sales.customer_sk
    LEFT JOIN web     ON c.c_customer_sk = web.customer_sk
    LEFT JOIN returns ON c.c_customer_sk = returns.customer_sk
    LEFT JOIN date_dim d_main ON COALESCE(sales.cs_sold_date_sk, web.ws_sold_date_sk, returns.cr_returned_date_sk) = d_main.d_date_sk
    LEFT JOIN call_center cc ON cc.cc_call_center_sk = COALESCE(sales.cs_call_center_sk, returns.cr_call_center_sk)
    LEFT JOIN catalog_page cp ON cp.cp_catalog_page_sk = COALESCE(sales.cs_catalog_page_sk, returns.cr_catalog_page_sk)
    LEFT JOIN warehouse w ON w.w_warehouse_sk = COALESCE(sales.cs_warehouse_sk, web.ws_warehouse_sk, returns.cr_warehouse_sk)
    LEFT JOIN item i ON i.i_item_sk = COALESCE(sales.cs_item_sk, web.ws_item_sk, returns.cr_item_sk)
    LEFT JOIN household_demographics hd ON hd.hd_demo_sk = c.c_current_hdemo_sk
    LEFT JOIN income_band ib ON ib.ib_income_band_sk = hd.hd_income_band_sk
    LEFT JOIN inv ON inv.inv_item_sk = i.i_item_sk AND inv.inv_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN date_dim d_inv ON inv.inv_date_sk = d_inv.d_date_sk
    LEFT JOIN web_site ws ON ws.web_site_sk = web.ws_web_site_sk
    LEFT JOIN time_dim t ON t.t_time_sk = COALESCE(sales.cs_sold_time_sk, web.ws_sold_time_sk, returns.cr_returned_time_sk)
WHERE
    cc.cc_city = 'Highland Park'
    AND w.w_state = 'CA'
    AND i.i_brand = 'BrandX'
    AND ib.ib_lower_bound >= 50000
    AND d_main.d_month_seq = 12
    AND ws.web_country = 'United States'
GROUP BY
    c.c_customer_id,
    d_main.d_year
HAVING
    SUM(sales.cs_ext_sales_price) > 1000
EXCEPT
SELECT
    c.c_customer_id,
    d_main.d_year,
    SUM(sales.cs_ext_sales_price)                         AS total_sales,
    SUM(web.ws_ext_sales_price)                           AS total_web_sales,
    SUM(returns.cr_return_amount)                         AS total_returns,
    (SUM(sales.cs_net_profit) + SUM(web.ws_net_profit) - SUM(returns.cr_return_amount)) AS net_contribution,
    RANK() OVER (PARTITION BY d_main.d_year ORDER BY (SUM(sales.cs_net_profit) + SUM(web.ws_net_profit) - SUM(returns.cr_return_amount)) DESC) AS profit_rank
FROM
    customer c
    LEFT JOIN sales   ON c.c_customer_sk = sales.customer_sk
    LEFT JOIN web     ON c.c_customer_sk = web.customer_sk
    LEFT JOIN returns ON c.c_customer_sk = returns.customer_sk
    LEFT JOIN date_dim d_main ON COALESCE(sales.cs_sold_date_sk, web.ws_sold_date_sk, returns.cr_returned_date_sk) = d_main.d_date_sk
    LEFT JOIN call_center cc ON cc.cc_call_center_sk = COALESCE(sales.cs_call_center_sk, returns.cr_call_center_sk)
    LEFT JOIN catalog_page cp ON cp.cp_catalog_page_sk = COALESCE(sales.cs_catalog_page_sk, returns.cr_catalog_page_sk)
    LEFT JOIN warehouse w ON w.w_warehouse_sk = COALESCE(sales.cs_warehouse_sk, web.ws_warehouse_sk, returns.cr_warehouse_sk)
    LEFT JOIN item i ON i.i_item_sk = COALESCE(sales.cs_item_sk, web.ws_item_sk, returns.cr_item_sk)
    LEFT JOIN household_demographics hd ON hd.hd_demo_sk = c.c_current_hdemo_sk
    LEFT JOIN income_band ib ON ib.ib_income_band_sk = hd.hd_income_band_sk
    LEFT JOIN inv ON inv.inv_item_sk = i.i_item_sk AND inv.inv_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN date_dim d_inv ON inv.inv_date_sk = d_inv.d_date_sk
    LEFT JOIN web_site ws ON ws.web_site_sk = web.ws_web_site_sk
    LEFT JOIN time_dim t ON t.t_time_sk = COALESCE(sales.cs_sold_time_sk, web.ws_sold_time_sk, returns.cr_returned_time_sk)
WHERE
    cc.cc_city = 'Highland Park'
    AND w.w_state = 'CA'
    AND i.i_brand = 'BrandX'
    AND i.i_color = 'Red'                -- different predicate to create a distinct set
    AND ib.ib_lower_bound >= 50000
    AND d_main.d_month_seq = 12
    AND ws.web_country = 'United States'
GROUP BY
    c.c_customer_id,
    d_main.d_year
LIMIT 100
