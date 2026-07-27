WITH
    -- sales base with sold and ship dates/times
    sales_base AS (
        SELECT
            cs.cs_sold_date_sk,
            cs.cs_sold_time_sk,
            cs.cs_ship_date_sk,
            cs.cs_catalog_page_sk,
            cs.cs_bill_customer_sk,
            cs.cs_bill_hdemo_sk,
            cs.cs_order_number,
            cs.cs_net_profit,
            cs.cs_item_sk
        FROM catalog_sales cs
    ),
    -- returns linked to sales
    returns_base AS (
        SELECT
            cr.cr_order_number,
            cr.cr_item_sk,
            cr.cr_returned_date_sk,
            cr.cr_returned_time_sk,
            cr.cr_return_amount,
            cr.cr_catalog_page_sk
        FROM catalog_returns cr
    )
SELECT
    s.s_store_id,
    d_sold.d_year,
    cp.cp_type,
    SUM(sb.cs_net_profit) AS total_profit,
    COUNT(DISTINCT rb.cr_order_number) AS return_count,
    SUM(rb.cr_return_amount) AS total_return_amount
FROM sales_base sb
    -- sold date
    JOIN date_dim d_sold ON sb.cs_sold_date_sk = d_sold.d_date_sk
    -- sold time
    JOIN time_dim t_sold ON sb.cs_sold_time_sk = t_sold.t_time_sk
    -- ship date (different alias)
    JOIN date_dim d_ship ON sb.cs_ship_date_sk = d_ship.d_date_sk
    -- catalog page for the sale
    JOIN catalog_page cp ON sb.cs_catalog_page_sk = cp.cp_catalog_page_sk
    -- billing customer
    JOIN customer c_bill ON sb.cs_bill_customer_sk = c_bill.c_customer_sk
    -- billing household demographics
    JOIN household_demographics hd_bill ON sb.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
    -- store (closed date linked to sold date)
    JOIN store s ON s.s_closed_date_sk = d_sold.d_date_sk
    -- left join returns (may be none for a sale)
    LEFT JOIN returns_base rb ON rb.cr_order_number = sb.cs_order_number
        AND rb.cr_item_sk = sb.cs_item_sk
    -- return date (second alias of date_dim)
    LEFT JOIN date_dim d_return ON rb.cr_returned_date_sk = d_return.d_date_sk
    -- return time (second alias of time_dim)
    LEFT JOIN time_dim t_return ON rb.cr_returned_time_sk = t_return.t_time_sk
    -- catalog page for the return (second alias of catalog_page)
    LEFT JOIN catalog_page cp_ret ON rb.cr_catalog_page_sk = cp_ret.cp_catalog_page_sk
GROUP BY
    s.s_store_id,
    d_sold.d_year,
    cp.cp_type
ORDER BY
    total_profit DESC
LIMIT 100
