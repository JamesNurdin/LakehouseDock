/* goal: Rank customers by total sales amount for the year 2001, showing their sales category, total refunded amount, inventory on hand for the sold item, and the location name derived from a full outer join of stores and web sites. The query samples items, applies multiple filters, uses a CASE expression, a correlated scalar subquery, window ranking, a HAVING clause, and pages the result. */
WITH sampled_item AS (
    SELECT *
    FROM item TABLESAMPLE BERNOULLI (10)
),
sales_join AS (
    SELECT
        cs.cs_bill_customer_sk,
        cs.cs_sold_date_sk,
        cs.cs_item_sk,
        cs.cs_ext_sales_price,
        cs.cs_net_profit,
        cs.cs_order_number,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        hd.hd_income_band_sk,
        ib.ib_lower_bound,
        cp.cp_department,
        sm.sm_type AS ship_mode_type,
        w.w_warehouse_name,
        d.d_year,
        d.d_month_seq
    FROM catalog_sales cs
    JOIN sampled_item i               ON cs.cs_item_sk = i.i_item_sk
    JOIN customer c                   ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd     ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd    ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib               ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN catalog_page cp              ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm                 ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w                  ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN date_dim d                   ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND i.i_wholesale_cost > 10
      AND cp.cp_department = 'Electronics'
),
returns_join AS (
    SELECT
        cr.cr_order_number,
        cr.cr_return_amount,
        cr.cr_return_quantity,
        cr.cr_refunded_customer_sk,
        d.d_year AS return_year
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
),
web_returns_join AS (
    SELECT
        wr.wr_order_number,
        wr.wr_return_amt,
        wr.wr_return_quantity,
        wr.wr_refunded_customer_sk,
        d.d_year AS web_return_year
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
),
inventory_join AS (
    SELECT
        inv.inv_item_sk,
        inv.inv_quantity_on_hand,
        d.d_year
    FROM inventory inv
    JOIN date_dim d ON inv.inv_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
),
store_join AS (
    SELECT
        s.s_store_sk,
        s.s_store_name,
        d.d_year
    FROM store s
    JOIN date_dim d ON s.s_closed_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
),
web_site_join AS (
    SELECT
        ws.web_site_sk,
        ws.web_name,
        d.d_year
    FROM web_site ws
    JOIN date_dim d ON ws.web_open_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
)
SELECT
    sj.cs_bill_customer_sk               AS customer_sk,
    sj.c_first_name,
    sj.c_last_name,
    sj.cd_gender,
    sj.cp_department,
    sj.ship_mode_type,
    sj.w_warehouse_name,
    sj.d_year,
    sj.cs_ext_sales_price,
    CASE WHEN sj.cs_ext_sales_price > 1000 THEN 'High' ELSE 'Low' END AS sales_category,
    (
        SELECT COALESCE(SUM(cr2.cr_return_amount), 0)
        FROM catalog_returns cr2
        WHERE cr2.cr_refunded_customer_sk = sj.cs_bill_customer_sk
    )                                   AS total_refunded_amount,
    ROW_NUMBER() OVER (PARTITION BY sj.cs_bill_customer_sk ORDER BY sj.cs_ext_sales_price DESC) AS sales_rank,
    COALESCE(st.s_store_name, ws.web_name) AS location_name,
    inv.inv_quantity_on_hand,
    rj.cr_return_amount,
    wrj.wr_return_amt
FROM sales_join sj
LEFT JOIN returns_join rj   ON sj.cs_order_number = rj.cr_order_number
LEFT JOIN web_returns_join wrj ON sj.cs_order_number = wrj.wr_order_number
LEFT JOIN inventory_join inv ON sj.cs_item_sk = inv.inv_item_sk
FULL OUTER JOIN (
    SELECT s_store_sk, s_store_name, d_year FROM store_join
) st ON st.d_year = sj.d_year
FULL OUTER JOIN (
    SELECT web_site_sk, web_name, d_year FROM web_site_join
) ws ON ws.d_year = sj.d_year
WHERE sj.cs_ext_sales_price IS NOT NULL
GROUP BY
    sj.cs_bill_customer_sk,
    sj.c_first_name,
    sj.c_last_name,
    sj.cd_gender,
    sj.cp_department,
    sj.ship_mode_type,
    sj.w_warehouse_name,
    sj.d_year,
    sj.cs_ext_sales_price,
    sj.cs_order_number,
    st.s_store_name,
    ws.web_name,
    inv.inv_quantity_on_hand,
    rj.cr_return_amount,
    wrj.wr_return_amt
HAVING SUM(sj.cs_ext_sales_price) > 5000
ORDER BY sj.d_year DESC, sales_rank
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY
