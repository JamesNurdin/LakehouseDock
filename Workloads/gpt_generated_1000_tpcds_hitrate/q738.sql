WITH sampled_cs AS (
    SELECT *
    FROM catalog_sales
    TABLESAMPLE BERNOULLI (10)
)
SELECT
    d_sold.d_year,
    cp.cp_department,
    CASE WHEN cs.cs_ext_tax > 50 THEN 'HIGH' ELSE 'LOW' END AS tax_category,
    COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
    COUNT(DISTINCT ss.ss_ticket_number) AS distinct_tickets,
    SUM(cs.cs_ext_sales_price) AS total_sales,
    SUM(ss.ss_net_paid_inc_tax) AS total_store_net_paid,
    AVG(wr.wr_return_amt) AS avg_return_amt
FROM sampled_cs cs
JOIN date_dim d_sold
    ON cs.cs_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship
    ON cs.cs_ship_date_sk = d_ship.d_date_sk
JOIN catalog_page cp
    ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN date_dim d_start
    ON cp.cp_start_date_sk = d_start.d_date_sk
JOIN date_dim d_end
    ON cp.cp_end_date_sk = d_end.d_date_sk
JOIN store_sales ss
    ON ss.ss_sold_date_sk = d_sold.d_date_sk
JOIN store_sales ss2
    ON ss2.ss_sold_date_sk = d_end.d_date_sk
JOIN web_returns wr
    ON wr.wr_returned_date_sk = d_end.d_date_sk
JOIN date_dim d_ret
    ON wr.wr_returned_date_sk = d_ret.d_date_sk
JOIN date_dim d_start2
    ON cp.cp_start_date_sk = d_start2.d_date_sk
WHERE EXISTS (
    SELECT 1
    FROM store_sales ss_chk
    WHERE ss_chk.ss_item_sk = cs.cs_item_sk
      AND ss_chk.ss_quantity > 0
)
GROUP BY
    d_sold.d_year,
    cp.cp_department,
    CASE WHEN cs.cs_ext_tax > 50 THEN 'HIGH' ELSE 'LOW' END
ORDER BY total_sales DESC
LIMIT 100
