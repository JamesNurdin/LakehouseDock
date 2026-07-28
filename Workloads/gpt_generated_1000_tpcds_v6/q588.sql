-- goal: Identify the top‑selling products for the year 2001, comparing catalog and web channel profitability, classifying profit status, and ranking products within each category.
WITH base AS (
    SELECT
        d.d_year,
        i.i_category,
        i.i_product_name,
        cs.cs_net_profit,
        ws.ws_net_profit,
        i.i_item_sk,
        cs.cs_ext_sales_price,
        cs.cs_ext_sales_price,
        cs.cs_item_sk,
        cs.cs_order_number,
        ws.ws_order_number
    FROM
        tpcds.catalog_sales cs
        LEFT JOIN tpcds.date_dim d
            ON cs.cs_sold_date_sk = d.d_date_sk
        LEFT JOIN tpcds.item i
            ON cs.cs_item_sk = i.i_item_sk
        LEFT JOIN tpcds.warehouse w
            ON cs.cs_warehouse_sk = w.w_warehouse_sk
        LEFT JOIN tpcds.call_center cc
            ON cs.cs_call_center_sk = cc.cc_call_center_sk
        LEFT JOIN tpcds.catalog_page cp
            ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
        LEFT JOIN tpcds.household_demographics hd
            ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
        LEFT JOIN tpcds.customer_address ca
            ON cs.cs_bill_addr_sk = ca.ca_address_sk
        LEFT JOIN tpcds.catalog_returns cr
            ON cr.cr_order_number = cs.cs_order_number
            AND cr.cr_item_sk = i.i_item_sk
        LEFT JOIN tpcds.reason r
            ON cr.cr_reason_sk = r.r_reason_sk
        LEFT JOIN tpcds.web_sales ws
            ON ws.ws_item_sk = i.i_item_sk
            AND ws.ws_sold_date_sk = d.d_date_sk
        LEFT JOIN tpcds.web_returns wr
            ON wr.wr_order_number = ws.ws_order_number
            AND wr.wr_item_sk = i.i_item_sk
            AND wr.wr_returned_date_sk = d.d_date_sk
    WHERE
        d.d_year = 2001
        AND i.i_current_price BETWEEN 20 AND 100
        AND w.w_state = 'CA'
        AND cc.cc_market_manager = 'John Doe'
)
SELECT
    b.d_year,
    b.i_category,
    b.i_product_name,
    SUM(b.cs_net_profit) AS total_catalog_profit,
    SUM(b.ws_net_profit) AS total_web_profit,
    CASE WHEN SUM(b.cs_net_profit) > 0 THEN 'Positive' ELSE 'Negative' END AS catalog_profit_status,
    RANK() OVER (PARTITION BY b.i_category ORDER BY SUM(b.cs_net_profit) DESC) AS category_rank,
    (
        SELECT MAX(cs2.cs_ext_sales_price)
        FROM tpcds.catalog_sales cs2
        WHERE cs2.cs_item_sk = b.i_item_sk
    ) AS max_catalog_ext_sales_price
FROM
    base b
GROUP BY
    b.d_year,
    b.i_category,
    b.i_product_name,
    b.i_item_sk
ORDER BY
    total_catalog_profit DESC,
    category_rank ASC
LIMIT 100
