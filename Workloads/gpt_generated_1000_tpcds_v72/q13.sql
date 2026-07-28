WITH base AS (
    SELECT
        d.d_date_sk,
        d.d_date,
        d.d_year,
        d.d_month_seq,
        w.w_warehouse_name,
        w.w_country,
        i.inv_quantity_on_hand,
        p.p_promo_name,
        wr.wr_return_amt,
        wr.wr_return_quantity,
        wr.wr_order_number
    FROM tpcds.date_dim d
    JOIN tpcds.inventory i
        ON i.inv_date_sk = d.d_date_sk
    JOIN tpcds.warehouse w
        ON i.inv_warehouse_sk = w.w_warehouse_sk
    JOIN tpcds.promotion p
        ON p.p_start_date_sk = d.d_date_sk
    JOIN tpcds.web_returns wr
        ON wr.wr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND d.d_date = DATE '2001-06-15'
      AND w.w_country = 'United States'
      AND p.p_promo_name LIKE '%cally%'
      AND wr.wr_return_amt > 20
)
SELECT
    w_warehouse_name,
    d_year,
    d_month_seq,
    p_promo_name,
    SUM(inv_quantity_on_hand) AS total_qty_on_hand,
    SUM(wr_return_amt)      AS total_return_amount,
    COUNT(DISTINCT wr_order_number) AS distinct_return_orders,
    AVG(wr_return_quantity) AS avg_return_quantity
FROM base
GROUP BY w_warehouse_name, d_year, d_month_seq, p_promo_name
ORDER BY total_return_amount DESC
LIMIT 100
