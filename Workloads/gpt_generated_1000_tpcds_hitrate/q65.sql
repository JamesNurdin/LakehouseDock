WITH sales_agg AS (
    SELECT
        cs.cs_order_number   AS order_number,
        d.d_year,
        SUM(cs.cs_net_profit)          AS total_profit,
        SUM(cs.cs_ext_sales_price)     AS total_sales,
        SUM(cs.cs_quantity)            AS total_qty
    FROM tpcds.catalog_sales cs
    JOIN tpcds.date_dim d               ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN tpcds.call_center cc           ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN tpcds.catalog_page cp           ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN tpcds.warehouse w              ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN tpcds.item i                   ON cs.cs_item_sk = i.i_item_sk
    JOIN tpcds.promotion p              ON cs.cs_promo_sk = p.p_promo_sk
    JOIN tpcds.household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN tpcds.income_band ib           ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN tpcds.customer_address ca      ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN tpcds.web_returns wr          
         ON wr.wr_item_sk = i.i_item_sk
        AND wr.wr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2001                                        -- filter 1
      AND w.w_county = 'Walker County'                           -- filter 2
      AND ca.ca_city IN ('Oakdale', 'Hopewell')                  -- filter 3
      AND p.p_discount_active = 'Y'                              -- filter 4
      AND ib.ib_upper_bound > 50000                              -- filter 5
    GROUP BY cs.cs_order_number, d.d_year
),

returns_agg AS (
    SELECT
        wr.wr_order_number   AS order_number,
        SUM(wr.wr_net_loss)  AS total_return_loss
    FROM tpcds.web_returns wr
    JOIN tpcds.date_dim d                ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN tpcds.item i                    ON wr.wr_item_sk = i.i_item_sk
    JOIN tpcds.household_demographics hd ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN tpcds.income_band ib            ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE d.d_year = 2001                                          -- filter 6
      AND ib.ib_lower_bound >= 30000                              -- filter 7
      AND wr.wr_return_quantity > 0                               -- filter 8
    GROUP BY wr.wr_order_number
),

profitable_orders AS (
    SELECT order_number FROM sales_agg WHERE total_profit > 1000
),

loss_orders AS (
    SELECT order_number FROM returns_agg WHERE total_return_loss > 500
),

intersect_orders AS (
    SELECT order_number FROM profitable_orders
    INTERSECT
    SELECT order_number FROM loss_orders
)
SELECT
    sa.d_year,
    COUNT(*)                         AS orders_count,
    AVG(sa.total_profit)             AS avg_profit,
    AVG(ra.total_return_loss)        AS avg_return_loss
FROM intersect_orders io
JOIN sales_agg sa   ON io.order_number = sa.order_number
LEFT JOIN returns_agg ra ON io.order_number = ra.order_number
GROUP BY sa.d_year
HAVING COUNT(*) > 5
ORDER BY sa.d_year DESC
